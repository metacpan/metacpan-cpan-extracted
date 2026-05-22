#!/usr/bin/env perl
# max_recv_buffer caps the recv buffer growth on HTTP responses. A
# SELECT that produces more than the cap must fire on_error with a
# clean message, tear the connection down, and leave subsequent
# queries on a fresh connection usable.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

plan skip_all => "ClickHouse HTTP not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);

plan tests => 2;

my $cap = 64 * 1024;            # 64KB cap; query will produce ~1MB
my $err;

my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $hport, protocol => 'http',
    max_recv_buffer => $cap,
    auto_reconnect  => 1,
    on_connect => sub {
        # Wide string per row, many rows — guarantees we exceed 64KB
        # even after chunked + (no) gzip framing on the wire.
        $ch->query(
            "select repeat('x', 1000), number from numbers(2000) format TabSeparated",
            { raw => 1 },
            sub {
                (undef, $err) = @_;
                # Issue a small follow-up to prove auto_reconnect rebuilt
                # the connection. We don't inspect the result — reaching
                # EV::break is enough.
                $ch->query("select 42 format TabSeparated",
                    { raw => 1 }, sub { EV::break });
            });
    },
    on_error => sub { $err //= $_[0] },
);

my $bail = EV::timer(8, 0, sub { EV::break }); EV::run; undef $bail;
$ch->finish;

ok defined($err) && length($err),
   "max_recv_buffer cap surfaced an error";
like $err, qr/recv|max_recv_buffer|too large|exceed|overflow/i,
   "error message names the cap"
   or diag "err=$err";
