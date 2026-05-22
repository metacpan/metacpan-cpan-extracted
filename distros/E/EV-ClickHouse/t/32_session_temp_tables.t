#!/usr/bin/env perl
# HTTP session_id keeps temp tables visible across queries on the same
# connection. Without session_id, each HTTP request lands in its own
# session and the temp table vanishes between calls.
use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;
use IO::Socket::INET;

my $host  = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

plan skip_all => "ClickHouse HTTP not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);

plan tests => 3;

# 1. With session_id: temp table survives across queries.
{
    my $sid = "ev-ch-test-$$-" . int(rand 1_000_000);
    my $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        session_id => $sid,
    );
    my ($created, $rows, $err);
    $ch->query("create temporary table _s32 (n UInt32) ENGINE = Memory", sub {
        (undef, $err) = @_;
        if ($err) { EV::break; return }
        $created = 1;
        $ch->query("insert into _s32 values (1),(2),(3)", sub {
            (undef, $err) = @_;
            if ($err) { EV::break; return }
            $ch->query("select count() from _s32 format TabSeparated", sub {
                ($rows, $err) = @_;
                EV::break;
            });
        });
    });
    EV::run;
    ok $created, 'created temp table inside session';
    is_deeply $rows, [[3]], 'temp table visible to subsequent query in the same session';
    $ch->finish;
}

# 2. Without session_id: each HTTP request is its own session, so temp
#    tables created in one request are gone in the next.
{
    my ($err);
    my $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
    );
    $ch->query("create temporary table _s32_no_sess (n UInt32) ENGINE = Memory", sub {
        (undef, $err) = @_;
        if ($err) { EV::break; return }
        $ch->query("select count() from _s32_no_sess format TabSeparated", sub {
            (undef, $err) = @_;
            EV::break;
        });
    });
    EV::run;
    like $err, qr/UNKNOWN_TABLE|Unknown\s+table|doesn't exist/i,
         'temp table is invisible across requests when session_id is unset';
    $ch->finish;
}
