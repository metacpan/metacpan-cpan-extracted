use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;

# Regression tests for C9 (consumer error paths):
#   F1  P7: OFFSET_OUT_OF_RANGE re-resolves the position per
#       auto_offset_reset and surfaces in the poll callback — today the
#       fetch loop repeats the same failing offset every tick forever.
#   F2  P7: a seek() landing while a fetch is in flight must not be
#       clobbered by the fetch response's offset advance.
#   F3  P8: seek() honors its documented error position: unknown leader,
#       unassigned partition, and transport failure all deliver
#       (undef, $err) instead of firing the cb with no error.
#   F4  P7: other per-partition error codes go to on_error, once per
#       partition per rebalance — not to the poll callback, not per tick.
#   F5  C11: a die in on_message warns and does not skip sibling records.
#   F6  C11: a die in one produce callback does not skip its siblings.
#   F7  C11: connect() called twice fires both callbacks exactly once;
#       connect() on an established client fires synchronously.
#
# Uses the shared in-process mock broker (t/lib/EVKafkaTest.pm).

plan tests => 23;

sub frames { grep { $_->{api} == $_[1] } @{$_[0]{requests}} }

# --- F1: OFFSET_OUT_OF_RANGE recovery -------------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my $oor = 0;
    $broker->{fetch_error} = sub { $oor++ ? 0 : 1 };  # first fetch: OOR
    my (@poll_errs, @errs);
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { push @errs, $_[0] },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->assign([{ topic => 't1', partition => 0, offset => 5 }]);
    $k->poll(sub { push @poll_errs, $_[0]; EV::break });
    my $t2 = timeout_w();
    EV::run;
    undef $t2;

    like $poll_errs[0] // '', qr/OFFSET_OUT_OF_RANGE/,
        'F1: poll callback got the partition error';
    is $k->{cfg}{assignments}[0]{offset}, 5,
        'F1: errored response did not move the offset';

    # the recovery seek resolves via ListOffsets; wait for it to apply
    my $w; $w = EV::timer 0, 0.01, sub {
        return unless frames($broker, 2) >= 1;
        undef $w; EV::break;
    };
    my $t3 = timeout_w();
    EV::run;
    undef $t3;
    my $settle = EV::timer 0.1, 0, sub { EV::break };
    EV::run;

    is $k->{cfg}{assignments}[0]{offset}, 0,
        'F1: offset re-resolved to earliest';

    $k->poll(sub { push @poll_errs, $_[0]; EV::break });
    my $t4 = timeout_w();
    EV::run;
    undef $t4;

    ok !$poll_errs[1], 'F1: poll clean after recovery';
    my @f = frames($broker, 1);
    is $f[-1]{fetch_offsets}{'t1:0'}, 0,
        'F1: next Fetch carried the reset offset';
    ok !@errs, 'F1: OFFSET_OUT_OF_RANGE is not an on_error event';
}

# --- F2: seek landing mid-flight is not clobbered -------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    $broker->{hold_fetch} = 1;
    $broker->{fetch_records}{'t1:0'} = [
        { key => 'k', value => 'a' }, { key => 'k', value => 'b' },
    ];
    my @msgs;
    my $k = EV::Kafka->new(
        brokers    => "127.0.0.1:$port",
        on_error   => sub { },
        on_message => sub { push @msgs, [@_] },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->assign([{ topic => 't1', partition => 0, offset => 0 }]);
    $k->poll(sub { EV::break });
    my $w; $w = EV::timer 0, 0.01, sub {
        return unless frames($broker, 1) >= 1;
        undef $w; EV::break;
    };
    my $t2 = timeout_w();
    EV::run;
    undef $t2;

    # fetch is in flight at the broker; the seek wins over its response
    $k->seek('t1', 0, 42);
    release_held_fetch($broker);
    my $t3 = timeout_w();
    EV::run;
    undef $t3;

    is $k->{cfg}{assignments}[0]{offset}, 42,
        'F2: in-flight fetch response did not clobber the seek';
    is scalar(@msgs), 2, 'F2: both records still delivered';
}

# --- F3: seek error contract ----------------------------------------------
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        drop_on => { 2 => 1 },   # first ListOffsets: drop the conn
    );
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->assign([{ topic => 'ghost', partition => 0, offset => 0 }]);
    my @scb;
    $k->seek('ghost', 0, -1, sub { push @scb, [@_] });
    like $scb[0][1] // '', qr/no connection to leader/,
        'F3: unknown leader -> cb error';

    $k->seek('t1', 7, -1, sub { push @scb, [@_] });
    like $scb[1][1] // '', qr/not assigned/,
        'F3: unassigned partition -> cb error';

    $k->assign([{ topic => 't1', partition => 0, offset => 0 }]);
    $k->seek('t1', 0, -1, sub { push @scb, [@_]; EV::break });
    my $t2 = timeout_w();
    EV::run;
    undef $t2;
    ok defined $scb[2][1], 'F3: transport failure -> cb error';
}

# --- F4: other partition codes -> on_error once ---------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    $broker->{fetch_error} = 3;   # UNKNOWN_TOPIC_OR_PARTITION, always
    my (@poll_errs, @errs);
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { push @errs, $_[0] },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->assign([{ topic => 't1', partition => 0, offset => 0 }]);
    for (1 .. 2) {
        $k->poll(sub { push @poll_errs, $_[0]; EV::break });
        my $t2 = timeout_w();
        EV::run;
        undef $t2;
    }

    is scalar(grep { /code 3/ } @errs), 1,
        'F4: partition error reported to on_error exactly once';
    ok !grep({ defined } @poll_errs),
        'F4: non-recoverable partition errors stay out of the poll cb';
}

# --- F5: a die in on_message does not skip sibling records ----------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    $broker->{fetch_records}{'t1:0'} = [
        { key => 'k', value => 'a' }, { key => 'k', value => 'b' },
    ];
    my (@msgs, @warns);
    my $k = EV::Kafka->new(
        brokers    => "127.0.0.1:$port",
        on_error   => sub { },
        on_message => sub {
            die "boom on first\n" if $_[2] == 0;
            push @msgs, [@_];
        },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->assign([{ topic => 't1', partition => 0, offset => 0 }]);
    my @warned;
    {
        local $SIG{__WARN__} = sub { push @warned, $_[0] };
        $k->poll(sub { EV::break });
        my $t2 = timeout_w();
        EV::run;
        undef $t2;
    }

    is scalar(@msgs), 1, 'F5: record after the dying one still delivered';
    is $msgs[0][4], 'b', 'F5: the delivered record is the sibling';
    ok grep({ /on_message error: boom on first/ } @warned),
        'F5: the die surfaced as a warning';
}

# --- F6: a die in one produce callback does not skip siblings -------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my (@done, @warned);
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    {
        local $SIG{__WARN__} = sub { push @warned, $_[0] };
        # same linger window -> one batch -> one produce-cb loop
        $k->produce('t1', 'k', 'v1', sub { die "cb boom\n" });
        $k->produce('t1', 'k', 'v2', sub { push @done, 1; EV::break });
        my $t2 = timeout_w();
        EV::run;
        undef $t2;
    }

    is scalar(@done), 1, 'F6: sibling produce cb fired after one died';
    ok grep({ /produce callback error: cb boom/ } @warned),
        'F6: the die surfaced as a warning';
}

# --- F7: connect() twice --------------------------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my (@cb1, @cb2, @cb3);
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    $k->connect(sub { push @cb1, [@_] });
    $k->connect(sub { push @cb2, [@_]; EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    is scalar(@cb1), 1, 'F7: first connect cb fired exactly once';
    is scalar(@cb2), 1, 'F7: second connect cb fired exactly once';
    ok $cb1[0][0] && ref $cb1[0][0]{brokers} eq 'ARRAY',
        'F7: first cb got metadata';
    ok !$cb1[0][1], 'F7: first cb got no error';

    # already connected: fires immediately with the cached metadata
    $k->connect(sub { push @cb3, [@_] });
    is scalar(@cb3), 1, 'F7: connect on an established client fires synchronously';
}
