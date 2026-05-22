#!/usr/bin/env perl
# Native CLIENT_CANCEL mid-query: the cancelled query's callback must
# fire, the connection must remain usable for the next query, and the
# cancel must arrive promptly (well under the query's natural duration).
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

plan tests => 4;

my $start;
my $finished_at;
my $next_rows;
my $next_err;
my $kicker;

my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $nport, protocol => 'native',
    on_connect => sub {
        $start = EV::time();
        # 5s natural duration; cancel fires at 0.2s.
        $ch->query("select sleep(5), number from numbers(1000000)", sub {
            $finished_at = EV::time();
            # Follow-up: verify the connection is still usable.
            $ch->query("select 42", sub {
                ($next_rows, $next_err) = @_;
                EV::break;
            });
        });
        $kicker = EV::timer(0.2, 0, sub { $ch->cancel });
    },
    on_error => sub { },        # ignore any reconnect chatter
);

my $bail = EV::timer(10, 0, sub { EV::break }); EV::run; undef $bail;
$ch->finish;

ok defined($finished_at),         "cancelled query callback fired";
my $elapsed = ($finished_at // 0) - ($start // 0);
cmp_ok $elapsed, '<', 2,          "cancel arrived in <2s (much shorter than the 5s query)"
    or diag "elapsed=${elapsed}s";
ok !$next_err,                    "follow-up query succeeded on the same conn"
    or diag $next_err;
is $next_rows && $next_rows->[0][0], 42,
                                  "follow-up query returned the expected value";
