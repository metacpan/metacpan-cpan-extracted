use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;

# Regression tests for close() semantics (P2 + the teardown contract):
#   C1  close() stops production structurally: a pending linger timer
#       must NOT open a new connection and produce after close (the
#       proven P2 resurrection). The queued record's callback is failed
#       with "client closed" instead.
#   C2  the exactly-once split: an in-flight produce callback is failed
#       by XS ("disconnected"), an unsent (batched) produce callback is
#       failed by close() ("client closed"), each exactly once.
#   C3  close() fails a pre-metadata queued produce callback.
#   C4  close() fails an outstanding flush callback.
#   C5  close() fails a queued poll callback.
#   C6  close() is idempotent.
#   C7  public methods croak after close.
#
# Uses the shared in-process mock broker (t/lib/EVKafkaTest.pm).

plan tests => 32;

# --- C1: no production after close ---------------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my @pcb;
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;

    my $accepts0 = $broker->{accepts};
    # default linger (5ms): the batch is armed but not yet sent when we
    # close in the same statement sequence
    $k->produce('t1', 'k', 'v', sub { push @pcb, [@_] });
    $k->close;

    my $done = EV::timer 1.0, 0, sub { EV::break };
    EV::run;

    is $broker->{accepts}, $accepts0,
        'C1: no new connection opened after close';
    is scalar(grep { $_->{api} == 0 } @{$broker->{requests}}), 0,
        'C1: no Produce request sent after close';
    is scalar(@pcb), 1, 'C1: produce callback fired exactly once';
    like $pcb[0][1] // '', qr/client closed/,
        'C1: produce callback got the teardown error';
}

# --- C2: in-flight vs unsent callback split -------------------------------
{
    # mock swallows Produce requests: r1 stays in flight
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        respond => { 0 => sub { undef } },
    );
    my (@r1, @r2);
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;

    $k->produce('t1', 'k', 'v1', sub { push @r1, [@_] });
    # wait for r1's Produce frame to reach the broker (in flight now)
    my $wait; $wait = EV::timer 0, 0.005, sub {
        return unless grep { $_->{api} == 0 } @{$broker->{requests}};
        undef $wait;
        EV::break;
    };
    EV::run;

    # r2 is queued unsent (long linger, armed timer cancelled by close)
    $k->{cfg}{linger_ms} = 60000;
    $k->produce('t1', 'k', 'v2', sub { push @r2, [@_] });
    $k->close;

    is scalar(@r1), 1, 'C2: in-flight produce callback fired exactly once';
    like $r1[0][1] // '', qr/disconnected/,
        'C2: in-flight callback was failed by the connection layer';
    is scalar(@r2), 1, 'C2: unsent produce callback fired exactly once';
    like $r2[0][1] // '', qr/client closed/,
        'C2: unsent callback was failed by close()';
    my $done = EV::timer 0.2, 0, sub { EV::break };
    EV::run;
    is scalar(grep { $_->{api} == 0 } @{$broker->{requests}}), 1,
        'C2: the unsent batch never reached the broker';
}

# --- C3: close fails a pre-metadata queued produce ------------------------
{
    my @pcb;
    my $k = EV::Kafka->new(brokers => '127.0.0.1:1', on_error => sub { });
    $k->produce('t1', 'k', 'v', sub { push @pcb, [@_] });
    $k->close;
    is scalar(@pcb), 1, 'C3: queued produce callback fired at close';
    like $pcb[0][1] // '', qr/client closed/,
        'C3: queued produce callback got the teardown error';
}

# --- C4: close fails an outstanding flush callback ------------------------
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        respond => { 0 => sub { undef } },   # swallow Produce
    );
    my @fcb;
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    $k->produce('t1', 'k', 'v');
    $k->flush(sub { push @fcb, [@_] });
    $k->close;
    is scalar(@fcb), 1, 'C4: flush callback fired at close';
    like $fcb[0][0] // '', qr/client closed/,
        'C4: flush callback got the teardown error';
}

# --- C5: close fails a queued poll callback -------------------------------
{
    my @pollcb;
    my $k = EV::Kafka->new(brokers => '127.0.0.1:1', on_error => sub { });
    $k->assign([{ topic => 't1', partition => 0, offset => 0 }]);
    $k->poll(sub { push @pollcb, 1 });
    $k->close;
    is scalar(@pollcb), 1, 'C5: queued poll callback fired at close';
}

# --- C6: close is idempotent ----------------------------------------------
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $k = EV::Kafka->new(brokers => '127.0.0.1:1', on_error => sub { });
    my $fired = 0;
    $k->close;
    $k->close(sub { $fired++ });
    is $fired, 1, 'C6: second close() is a no-op but fires its callback';
    is scalar(grep { /EV::Kafka/ } @warns), 0, 'C6: repeated close is silent';
}

# --- C7: public methods croak after close ---------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    $k->close;

    my @calls = (
        ['connect',     sub { $k->connect(sub { }) }],
        ['produce',     sub { $k->produce('t1', 'k', 'v', sub { }) }],
        ['produce_many',sub { $k->produce_many([['t1', 'k', 'v']], sub { }) }],
        ['flush',       sub { $k->flush(sub { }) }],
        ['assign',      sub { $k->assign([]) }],
        ['seek',        sub { $k->seek('t1', 0, 0, sub { }) }],
        ['poll',        sub { $k->poll(sub { }) }],
        ['offsets_for', sub { $k->offsets_for('t1', sub { }) }],
        ['lag',         sub { $k->lag(sub { }) }],
        ['subscribe',   sub { $k->subscribe('t1', group_id => 'g') }],
        ['commit',      sub { $k->commit(sub { }) }],
        ['unsubscribe', sub { $k->unsubscribe(sub { }) }],
        ['begin_transaction',        sub { $k->begin_transaction }],
        ['commit_transaction',       sub { $k->commit_transaction(sub { }) }],
        ['abort_transaction',        sub { $k->abort_transaction(sub { }) }],
        ['send_offsets_to_transaction',
            sub { $k->send_offsets_to_transaction('g', sub { }) }],
    );
    for my $c (@calls) {
        my ($name, $code) = @$c;
        like do { local $@; eval { $code->() }; $@ } // '',
            qr/^EV::Kafka: client is closed/,
            "C7: $name() croaks after close";
    }
}
