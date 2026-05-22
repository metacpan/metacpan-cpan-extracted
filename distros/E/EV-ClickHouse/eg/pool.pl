#!/usr/bin/env perl
# Connection pool: fan out N concurrent queries through a fixed pool.
# Pool->_pick chooses the least-busy connection; ties round-robin.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $pool = EV::ClickHouse::Pool->new(
    host     => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
    size     => 8,
);

my $left = 32;
for my $i (1 .. 32) {
    $pool->query("select $i, count() from numbers(100_000)", sub {
        my ($r, $err) = @_;
        if ($err) { warn "[$i] err: $err\n" }
        else      { printf "[%2d] count=%d\n", $i, $r->[0][1] }
        EV::break unless --$left;
    });
}
EV::run;
$pool->finish;
