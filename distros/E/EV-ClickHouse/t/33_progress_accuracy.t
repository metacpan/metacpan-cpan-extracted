#!/usr/bin/env perl
# Sum of on_progress rows should match profile_rows reported after
# a query completes. Use a non-aggregating SELECT so result-set size
# equals scanned-rows, otherwise profile_rows (result rows) and the
# progress sum (scanned rows) diverge legitimately.
use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;
use IO::Socket::INET;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

plan tests => 2;

my $rows_target = 1_000_000;        # large enough for several progress packets
my $progress_total = 0;
my $profile_rows;

my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $nport, protocol => 'native',
    on_progress => sub {
        my ($rows) = @_;            # ($rows, $bytes, $total_rows, ...)
        $progress_total += $rows;
    },
    on_connect => sub {
        $ch->query(
            "select number from numbers($rows_target)",
            { on_data => sub { } },     # streaming so progress fires
            sub {
                $profile_rows = $ch->profile_rows;
                EV::break;
            },
        );
    },
);
my $bail = EV::timer(20, 0, sub { EV::break });
EV::run;
undef $bail;

ok $profile_rows && $profile_rows > 0, 'profile_rows reported';
SKIP: {
    # A very fast server can deliver EndOfStream before any progress
    # packet fires (rare on real workloads but legal per protocol).
    # Don't pin the equality assertion to that race; we only check it
    # when at least one progress packet did fire.
    skip "server emitted no progress packets — race", 1
        unless $progress_total > 0;
    # Some CH versions over-report scanned rows at the limit boundary
    # because progress fires per scanned block (e.g. 65536 rows) and the
    # final partial block still counts the full block size. Allow a
    # modest over-shoot but flag gross divergence.
    ok $progress_total >= $profile_rows && $progress_total <= $profile_rows * 1.2,
       "summed on_progress rows ($progress_total) match profile_rows ($profile_rows) within 20%";
}

$ch->finish;
