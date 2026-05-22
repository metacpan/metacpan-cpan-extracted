#!/usr/bin/env perl
# session_id: TEMPORARY TABLEs created in one query are visible to
# subsequent queries on the same connection sharing the same
# session_id. A second connection with a DIFFERENT session_id does
# not see them.
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

plan tests => 4;

my $sid_a = "ev-ch-sess-A-$$-" . int(rand(1_000_000));
my $sid_b = "ev-ch-sess-B-$$-" . int(rand(1_000_000));

# Session A: create the temp table, insert, count.
my ($create_ok, $count_a);
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        session_id => $sid_a,
        on_connect => sub {
            $ch->query("create temporary table tt (n UInt32) format TabSeparated", sub {
                my (undef, $e) = @_;
                $create_ok = !defined $e;
                $ch->query(
                    "insert into tt format TabSeparated\n1\n2\n3\n",
                    { raw => 1 }, sub {
                    $ch->query("select count() from tt format TabSeparated",
                               { raw => 1 }, sub {
                        my ($body) = @_;
                        ($count_a) = ($body // '') =~ /(\d+)/;
                        EV::break;
                    });
                });
            });
        },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(8, 0, sub { EV::break }); EV::run; undef $t;
    $ch->finish;
}

# Session B (different session_id): the temp table must NOT be visible.
my ($missing_err);
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        session_id => $sid_b,
        on_connect => sub {
            $ch->query("select count() from tt format TabSeparated",
                       { raw => 1 }, sub {
                (undef, $missing_err) = @_;
                EV::break;
            });
        },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(8, 0, sub { EV::break }); EV::run; undef $t;
    $ch->finish;
}

ok $create_ok,    'create temporary table succeeded'                            or diag "no";
is $count_a, 3,   'temp table visible to subsequent query on same session_id';
ok defined($missing_err) && length($missing_err),
                  'a different session_id does not see the temp table';
like $missing_err, qr/UNKNOWN_TABLE|doesn't exist|\btt\b|Table.*not.*found/i,
                  'error names the missing table';
