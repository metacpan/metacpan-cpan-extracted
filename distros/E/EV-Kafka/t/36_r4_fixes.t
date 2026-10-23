use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;

# r4 fixes:
#   F1  commit() surfaces broker per-partition errors via $cb
#       (was: silent success on rebalance/unknown-member)
#   F2  concurrent flush() calls each fire their callback
#       (was: all but the last callback stranded)
#
# Uses the shared in-process mock broker (t/lib/EVKafkaTest.pm).

plan tests => 9;

sub sub_group_client {
    my ($port) = @_;
    my $k = EV::Kafka->new(
        brokers    => "127.0.0.1:$port",
        on_error   => sub { },
        on_message => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;
    return $k;
}

# --- F1: commit reports a broker per-partition error -----------------------
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        respond => { 8 => i32(1) . kstr('t1') . i32(1) . i32(0) . i16(25) },
    );
    my ($assigned, $commit_err);
    my $k = sub_group_client($port);
    $k->subscribe('t1',
        group_id           => 'g1',
        heartbeat_interval => 60,
        on_assign          => sub { $assigned = $_[0]; EV::break },
    );
    my $t = timeout_w();
    EV::run;
    undef $t;
    ok $assigned && @$assigned, 'F1: group assigned before commit';

    $k->commit(sub { $commit_err = $_[0]; EV::break });
    $t = timeout_w();
    EV::run;
    undef $t;
    ok defined($commit_err), 'F1: commit surfaces broker per-partition error';
    like $commit_err // '', qr/25/, 'F1: error names the broker code';
    $k->close;
}

# --- F1b: clean commit still reports no error ------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my ($assigned, $commit_err);
    my $k = sub_group_client($port);
    $k->subscribe('t1',
        group_id           => 'g1',
        heartbeat_interval => 60,
        on_assign          => sub { $assigned = $_[0]; EV::break },
    );
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->commit(sub { $commit_err = $_[0]; EV::break });
    $t = timeout_w();
    EV::run;
    undef $t;
    ok !defined($commit_err), 'F1: clean commit still reports no error';
    $k->close;
}

# --- F2a: concurrent flushes all fire on completion ------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my $k = EV::Kafka->new(brokers => "127.0.0.1:$port");
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->produce('t1', 'k', 'v', sub { });
    my @fired;
    $k->flush(sub { push @fired, ['a', $_[0]]; EV::break if @fired == 2 });
    $k->flush(sub { push @fired, ['b', $_[0]]; EV::break if @fired == 2 });
    $t = timeout_w();
    EV::run;
    undef $t;
    is scalar(@fired), 2, 'F2: both concurrent flushes fire on completion';
    ok !grep({ defined $_->[1] } @fired), 'F2: no flush error on completion';
    $k->close;
}

# --- F2b: concurrent flushes all fail on close -----------------------------
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        respond => { 0 => sub { undef } },
    );
    my $k = EV::Kafka->new(brokers => "127.0.0.1:$port");
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->produce('t1', 'k', 'v', sub { });
    my @fired;
    $k->flush(sub { push @fired, $_[0] });
    $k->flush(sub { push @fired, $_[0] });
    $k->close;
    is scalar(@fired), 2, 'F2: both concurrent flushes fire on close';
    is_deeply \@fired, ['client closed', 'client closed'],
        'F2: close error delivered to each';
}

# --- F2c: concurrent flushes all fail on timeout ---------------------------
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        respond => { 0 => sub { undef } },
    );
    my $k = EV::Kafka->new(
        brokers       => "127.0.0.1:$port",
        flush_timeout => 0.2,
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->produce('t1', 'k', 'v', sub { });
    my @fired;
    my $done = sub { push @fired, $_[0]; EV::break if @fired == 2 };
    $k->flush($done);
    $k->flush($done);
    $t = timeout_w();
    EV::run;
    undef $t;
    is_deeply \@fired, ['flush timed out', 'flush timed out'],
        'F2: both concurrent flushes time out';
    $k->close;
}
