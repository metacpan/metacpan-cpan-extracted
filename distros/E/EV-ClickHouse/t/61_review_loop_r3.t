#!/usr/bin/env perl
# Regression tests for review-loop round 3: HTTP keeps trailing empty
# rows, native insert keeps/errors blank lines like the server,
# async-DNS failure fails over and retries.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $nat_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
plan skip_all => 'no ClickHouse native at $host:$nport' unless $nat_ok;
plan tests => 7;

# --- R3-3: HTTP keeps empty-string rows -------------------------------------
{
    my $h = EV::ClickHouse->new(host => $host, port => $hport,
                                protocol => 'http',
                                on_error => sub { EV::break });
    my ($n1, $n3);
    $h->query("select ''", sub {
        my ($r) = @_; $n1 = $r ? scalar(@$r) : -1;
        $h->query("select '' union ALL select '' union ALL select ''", sub {
            my ($r2) = @_; $n3 = $r2 ? scalar(@$r2) : -1;
            EV::break;
        });
    });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    is($n1, 1, 'R3-3: lone empty string is one row');
    is($n3, 3, 'R3-3: trailing empty row is kept');
    $h->finish;
}

# --- R3-1: native insert blank-line parity ----------------------------------
{
    my $ch = EV::ClickHouse->new(host => $host, port => $nport,
                                 protocol => 'native',
                                 on_connect => sub { EV::break },
                                 on_error => sub { EV::break });
    EV::run;
    my ($rows, $err);
    $ch->query('drop table if exists t61_b', sub {
    $ch->query('create table t61_b (s String) engine=Memory', sub {
        $ch->insert('t61_b', "a\n\nb\n", sub {
            $ch->query('select s from t61_b order by s', sub {
                my ($r) = @_; $rows = $r;
                $ch->query('drop table t61_b', sub { EV::break });
            });
        });
    }) });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    is_deeply([map { $_->[0] } @$rows], ['', 'a', 'b'],
        'R3-1: middle blank line kept as an empty row');
    $ch->query('drop table if exists t61_mc', sub {
    $ch->query('create table t61_mc (a UInt32, b String) engine=Memory', sub {
        $ch->insert('t61_mc', "1\tx\n\n3\ty\n", sub {
            my (undef, $e) = @_; $err = $e;
            $ch->query('drop table t61_mc', sub { EV::break });
        });
    }) });
    $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    like($err // '', qr/native INSERT encoding failed/,
        'R3-1: short blank line fails loudly like the server');
    $ch->finish;
}

# --- R3-2: async-DNS failure fails over and retries --------------------------
SKIP: {
    skip 'EV::cares not installed', 3 unless eval { require EV::cares; 1 };
    my (@fo, $qok);
    my $c;
    $c = EV::ClickHouse->new(hosts => ['nonexistent.invalid', $host],
        port => $nport, protocol => 'native', auto_reconnect => 1,
        on_failover => sub { push @fo, [@_] },
        on_connect  => sub {
            $c->query('select 1', sub {
                my (undef, $e) = @_; $qok = !$e; EV::break;
            });
        },
        on_error => sub {});
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(@fo, 'R3-2: DNS failure rotates the failover ring');
    ok($qok, 'R3-2: query succeeds on the good host after DNS failover');
    $c->finish;

    my $errs = 0;
    my $d;
    $d = EV::ClickHouse->new(host => 'nonexistent.invalid', port => $nport,
        protocol => 'native', auto_reconnect => 1,
        reconnect_max_attempts => 2, reconnect_delay => 0.1,
        on_error => sub { $errs++ });
    $t = EV::timer(8, 0, sub { EV::break });
    EV::run;
    cmp_ok($errs, '>=', 2, 'R3-2: DNS failure retries instead of dying once');
    $d->finish;
}
