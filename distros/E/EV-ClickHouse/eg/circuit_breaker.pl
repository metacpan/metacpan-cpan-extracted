#!/usr/bin/env perl
# Pool circuit breaker: after `circuit_threshold` consecutive query
# errors on a member, the Pool marks it dead for `circuit_cooldown`
# seconds. Subsequent _pick()s skip dead members; if all are dead,
# the breaker is bypassed so recovery attempts still go through.
#
# Inspect state via $pool->circuit_state - returns a list of
# { fails => N, dead_until => $epoch, alive => 0|1 } per member.
#
# This demo connects to a real server (queries must actually be
# dispatched to reach the breaker observer) and repeatedly runs a
# query that fails server-side. After `circuit_threshold` errors
# each member trips; once all members are dead the breaker is
# bypassed so recovery attempts still go through.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host  = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $nport = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;

my $pool = EV::ClickHouse::Pool->new(
    size              => 2,
    host              => $host,
    port              => $nport,
    protocol          => 'native',
    circuit_threshold => 3,
    circuit_cooldown  => 4,
);

my $issued = 0;
my $w = EV::timer(0, 0.5, sub {
    # Fire a server-side error - reaches the breaker via the async path.
    for (1 .. 3) {
        $pool->query("select * from no_such_db_$$.no_such_table_$$",
            sub { });   # errors ignored - we just want the breaker hits
    }
    $issued += 3;
    my @s = $pool->circuit_state;
    for my $i (0 .. $#s) {
        printf STDERR "[breaker] member %d  fails=%d  alive=%s\n",
                      $i, $s[$i]{fails}, ($s[$i]{alive} ? 'yes' : 'no');
    }
    EV::break if $issued >= 30;
});

EV::run;
$pool->finish;
