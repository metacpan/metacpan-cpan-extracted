#!/usr/bin/env perl
# Slow-query observability: print any query slower than $threshold
# seconds with id, duration, error code, and the connection-level
# query_log_comment so logs can be correlated to the deploy / route.
#
# Drop-in: install $ch->slow_query_log(...) once after construction
# and forget. Composes with whatever on_query_complete handler is
# already wired up.
#
# Usage:
#   THRESHOLD=0.05 ./eg/slow_query_log.pl

use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host      = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $port      = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;
my $threshold = $ENV{THRESHOLD}              // 0.05;

my $ch; $ch = EV::ClickHouse->new(
    host              => $host, port => $port, protocol => 'native',
    query_log_comment => "slow-demo-pid=$$",
    on_connect => sub {
        # Demo: a fast query (filtered) + a slow one (logged).
        $ch->query("select 1", sub { });
        $ch->query("select sleep(0.2), 'slow one'", sub {
            EV::timer(0.1, 0, sub { EV::break });
        });
    },
    on_error => sub { warn "ch: $_[0]\n"; EV::break },
);

$ch->slow_query_log($threshold, sub {
    my ($qid, $rows, $bytes, $code, $dur, $err) = @_;
    printf STDERR "SLOW %.3fs  qid=%s  code=%d  err=%s  rows=%d  bytes=%d\n",
                  $dur, $qid // '?', $code, $err // '', $rows, $bytes;
});

EV::run;
$ch->finish;
