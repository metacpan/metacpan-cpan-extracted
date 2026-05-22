#!/usr/bin/env perl
# Tail-latency mitigation with hedged_query: race N members of a pool
# in parallel and resolve with the first reply. The "win" goes to
# whichever member's response arrived first.
#
# Pool members share connection parameters, so the demo races a pool
# of `size` connections to one server (any one of them can be transiently
# slow, and the second/third copy of the query hides that). For a real
# fan-across-replicas setup you'd build one EV::ClickHouse per replica
# and dispatch by hand — Pool doesn't currently support per-member
# host overrides.
#
# Realistic shape for a low-RPS dashboard backend where a stuck member
# would otherwise spike p99 latency. Not appropriate for INSERT (would
# silently double-write under dedupe miss) or high-RPS bulk scans
# (doubles server load for marginal latency gain).
#
# Usage:
#   CH_HOST=127.0.0.1 CH_NATIVE_PORT=9000 RPS=5 SIZE=3 ./eg/hedged_pool.pl

use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host  = $ENV{CH_HOST}        // '127.0.0.1';
my $nport = $ENV{CH_NATIVE_PORT} // 9000;
my $size  = $ENV{SIZE}           // 3;
my $rps   = $ENV{RPS}            // 5;

my $pool = EV::ClickHouse::Pool->new(
    host              => $host,
    port              => $nport,
    protocol          => 'native',
    size              => $size,
    auto_reconnect    => 1,
    circuit_threshold => 5,
    circuit_cooldown  => 30,
);

my @wins = (0) x $size;
my $period = 1 / $rps;

my $issue = EV::timer(0, $period, sub {
    my $sent_at = EV::time;
    $pool->hedged_query(
        "select sleep(0.05), hostName()",       # 50ms baseline
        hedge => 2,
        sub {
            my ($rows, $err, $winner) = @_;
            my $latency = EV::time - $sent_at;
            if ($err) { warn "err: $err\n"; return }
            $wins[$winner]++;
            printf "%.0fms  member=%d  %s\n",
                   $latency * 1000, $winner, $rows->[0][1];
        },
    );
});

# Report breaker + win distribution every 5s.
my $report = EV::timer(5, 5, sub {
    print "--- circuit state + wins ---\n";
    my @st = $pool->circuit_state;
    for my $i (0 .. $#st) {
        printf "  member %d: fails=%d alive=%d wins=%d\n",
               $i, $st[$i]{fails}, $st[$i]{alive}, $wins[$i];
    }
});

# Graceful drain on Ctrl-C.
my $stop = EV::signal('INT', sub {
    undef $issue; undef $report;
    print "draining\n";
    $pool->shutdown(5, sub { print "done\n"; EV::break });
});

EV::run;
