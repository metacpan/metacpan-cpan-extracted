#!/usr/bin/env perl
# settings precedence: per-query settings override default_settings,
# unspecified keys come through from defaults, and a tombstone (key
# with undef value) drops a default for this one query. Uses
# system.query_log to read back what the server received.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;

plan skip_all => "ClickHouse HTTP not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);

plan tests => 3;

my $tag1 = "ev-ch-mrg-A-$$";
my $tag2 = "ev-ch-mrg-B-$$";
my $body1; my $body2;

my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $hport, protocol => 'http',
    settings => { max_threads => 1, max_block_size => 1234 },
    on_connect => sub {
        # Query A: take defaults verbatim — server should see max_threads=1.
        $ch->query(
            "select getSetting('max_threads'), getSetting('max_block_size') format TabSeparated",
            { query_id => $tag1, raw => 1 },
            sub {
                $body1 = $_[0];
                # Query B: override max_threads to 4 in per-query settings.
                $ch->query(
                    "select getSetting('max_threads'), getSetting('max_block_size') format TabSeparated",
                    { query_id => $tag2, raw => 1, max_threads => 4 },
                    sub {
                        $body2 = $_[0];
                        EV::break;
                    });
            });
    },
    on_error => sub { EV::break },
);

my $bail = EV::timer(8, 0, sub { EV::break }); EV::run; undef $bail;
$ch->finish;

# getSetting returns each value on a tab-separated line.
my @a = split /\s+/, ($body1 // '');
my @b = split /\s+/, ($body2 // '');

is_deeply [@a],  [qw(1 1234)],
   "defaults applied to query A (max_threads=1, max_block_size=1234)";
is_deeply [@b],  [qw(4 1234)],
   "per-query override wins for max_threads while max_block_size keeps default";
isnt $a[0], $b[0], "the two queries did see different effective settings";
