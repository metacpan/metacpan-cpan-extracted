use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;

# Regression tests for C8 (group subsystem):
#   G1  P6: a JoinGroup that fails at the request level (coordinator conn
#       dropped mid-request) is retried through full re-discovery
#       (FindCoordinator) and the join eventually succeeds — today the
#       error goes to on_error and the group silently stalls.
#   G2  P6: the retry is bounded — a permanently failing JoinGroup stops
#       the group after 5 retries and reports once via on_error.
#   G3  P12: a late fetch completion from a previous fetch-loop
#       generation must not clear the new loop's in-flight flag — at
#       most one Fetch request is outstanding at any time.
#
# Uses the shared in-process mock broker (t/lib/EVKafkaTest.pm).
#
# Note: every phase undefs the previous phase's timeout watcher — an
# armed one-shot timeout_w() survives into later EV::run phases and
# would break the loop early.

plan tests => 14;

sub frames { grep { $_->{api} == $_[1] } @{$_[0]{requests}} }

# --- G1: dropped JoinGroup -> re-discovery -> eventual join ---------------
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        drop_on => { 11 => 1 },   # first JoinGroup: drop the conn, no reply
    );
    my (@errs, @assigned);
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { push @errs, $_[0] },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->subscribe('t1',
        group_id           => 'g1',
        heartbeat_interval => 60,     # keep heartbeats out of the way
        on_assign          => sub { push @assigned, $_[0]; EV::break },
    );
    my $t2 = timeout_w(10);
    EV::run;

    is scalar(@assigned), 1, 'G1: join eventually succeeded (on_assign fired)';
    is $assigned[0][0]{topic}, 't1', 'G1: assignment covers the topic';
    my @fc = frames($broker, 10);
    my @jg = frames($broker, 11);
    cmp_ok scalar(@fc), '>=', 2, 'G1: coordinator re-discovered after the drop';
    cmp_ok scalar(@jg), '>=', 2, 'G1: JoinGroup retried after the drop';
    ok $fc[1]{ts} - $jg[0]{ts} < 3.5,
        'G1: re-discovery within bounded retry time';
    ok !grep({ /JoinGroup/ } @errs),
        'G1: no JoinGroup error surfaced (retry recovered)';
}

# --- G2: permanently failing JoinGroup -> bounded retry -> stopped --------
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        drop_on => { 11 => 50 },  # every JoinGroup drops the conn
    );
    my @errs;
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { push @errs, $_[0] },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->subscribe('t1', group_id => 'g2', heartbeat_interval => 60);
    my $w; $w = EV::timer 0, 0.1, sub {
        my $g = $k->{cfg}{group};
        return unless $g && $g->{state} eq 'stopped';
        undef $w; EV::break;
    };
    my $t2 = timeout_w(20);
    EV::run;

    is $k->{cfg}{group}{state}, 'stopped',
        'G2: group stopped after bounded retries';
    is scalar(grep { /JoinGroup|no broker connection/ } @errs), 1,
        'G2: exhaustion reported exactly once';
    cmp_ok scalar(frames($broker, 11)), '<=', 6,
        'G2: JoinGroup attempts bounded (initial + 5 retries)';
    cmp_ok scalar(frames($broker, 10)), '<=', 6,
        'G2: coordinator re-discovery bounded';
}

# --- G3: late completion from an old fetch-loop generation ----------------
# Two broker nodes so group traffic (coordinator, node 0) and fetch
# traffic (t1 leader, node 1) use separate client conns; a committed
# offset of 0 keeps ListOffsets off the data conn. Then fetches are the
# only requests on the data conn and held fetches can be released
# oldest-first without violating the per-conn FIFO of responses.
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => { nparts => 1, leader => 1 } },
        brokers => [[0, '127.0.0.1', 0], [1, '127.0.0.1', 0]],
    );
    $broker->{hold_fetch} = 1;
    $broker->{committed}{'t1:0'} = 0;
    $broker->{fetch_records}{'t1:0'} = [{ key => 'k', value => 'v1' }];
    my $hb27 = 0;
    $broker->{heartbeat_error} = sub { $hb27++ ? 0 : 27 };  # rebalance once
    my (@msgs, @errs);
    my $assigned = 0;
    my $k = EV::Kafka->new(
        brokers    => "127.0.0.1:$port",
        on_error   => sub { push @errs, $_[0] },
        on_message => sub { push @msgs, [@_] },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->subscribe('t1',
        group_id           => 'g3',
        heartbeat_interval => 1,
        on_assign          => sub { $assigned++ },
    );

    # Phase 1: join, start the fetch loop (fetch #1 is held by the mock),
    # then the first heartbeat returns 27 (REBALANCE_IN_PROGRESS) and the
    # client rejoins. Wait for the second SyncGroup.
    my $w; $w = EV::timer 0, 0.02, sub {
        return unless frames($broker, 14) >= 2;
        undef $w; EV::break;
    };
    my $t2 = timeout_w(10);
    EV::run;
    undef $t2;
    is $assigned, 2, 'G3: joined, then rejoined on the forced rebalance';

    # Phase 2: wait for the NEW loop's fetch (#2) to be held as well,
    # then release only the STALE fetch (#1). Its late completion must
    # not clear the new loop's in-flight flag.
    my $w2; $w2 = EV::timer 0, 0.02, sub {
        return unless @{$broker->{held_fetch} // []} >= 2;
        undef $w2; EV::break;
    };
    my $t3 = timeout_w(10);
    EV::run;
    undef $t3;
    release_held_fetch($broker, 1);
    my $settle = EV::timer 0.4, 0, sub { EV::break };
    EV::run;

    is scalar(@{$broker->{held_fetch} // []}), 1,
        'G3: stale completion did not free the flag (still one outstanding)';
    is scalar(frames($broker, 1)), 2,
        'G3: no third Fetch dispatched while #2 is outstanding';

    # Cleanup: answer the rest; the record must have arrived exactly once.
    release_held_fetch($broker);
    my $settle2 = EV::timer 0.3, 0, sub { EV::break };
    EV::run;
    is scalar(grep { $_->[2] == 0 } @msgs), 1,
        'G3: record at offset 0 delivered exactly once';
}
