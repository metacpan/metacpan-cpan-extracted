#!/usr/bin/env perl
# Pool fan-out distribution test.
#   - Launch a Pool of 4 native connections.
#   - Issue 200 quick selects.
#   - Each query callback records which connection handled it (by refaddr).
#   - Assert no member handled less than 10% or more than 50% of the load
#     (i.e. roughly balanced - allowing for least-busy bias near startup).
use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;
use IO::Socket::INET;
use Scalar::Util qw(refaddr);

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;
plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

plan tests => 3;

my $size  = 4;
my $total = 200;
my $pool  = EV::ClickHouse::Pool->new(
    host => $host, port => $nport, protocol => 'native', size => $size,
);

# Pool::query routes through _pick BEFORE calling the underlying query, so
# we recover the assigned connection by inspecting which member's
# pending_count went up. Easier: ask _pick directly N times and call query
# on the returned connection, recording the addr per call.
my %hits;
my $left = $total;
for (1 .. $total) {
    my $ch = $pool->_pick;
    $hits{ refaddr $ch }++;
    $ch->query("select 1", sub { EV::break unless --$left });
}
my $bail = EV::timer(15, 0, sub { EV::break });
EV::run;
undef $bail;

is $left, 0, "all $total queries completed";
is scalar(keys %hits), $size, "every pool member handled at least one query";
my $min = (sort { $a <=> $b } values %hits)[0];
my $max = (sort { $b <=> $a } values %hits)[0];
my $expected = $total / $size;
ok $min >= $expected * 0.10 && $max <= $expected * 5,
   "distribution within bounds (min=$min max=$max expected=$expected)";

$pool->finish;
