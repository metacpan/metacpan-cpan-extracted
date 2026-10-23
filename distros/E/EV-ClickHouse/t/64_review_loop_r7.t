#!/usr/bin/env perl
# Regression tests for review-loop round 7: XS-boundary magic safety.
# UAF guards (undef/reset/finish during async builds), tied-container
# support (rows/cells/Array/Tuple/Map/JSON/settings), single-FETCH
# wire encoding, HTTP params single-pass, pool idx clamp, dying-SQL
# leak, cancel_pending re-queue routing.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;
require Tie::Array;
require Tie::Hash;
require Tie::Scalar;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $nat_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
plan skip_all => "no ClickHouse native at $host:$nport" unless $nat_ok;
my $http_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);

plan tests => 26;

{ package TA; our @ISA = ('Tie::StdArray'); }
{ package TH; our @ISA = ('Tie::StdHash'); }

sub new_ch {
    my (%o) = @_;
    my $ch = EV::ClickHouse->new(host => $host, port => $nport,
                                 protocol => 'native', %o,
                                 on_connect => sub { EV::break },
                                 on_error => sub { EV::break });
    EV::run;
    $ch;
}

# --- H1: undef $ch inside a native callback with inserts pending --------
{
    my $ch = new_ch();
    $ch->query('drop table if exists t64_u', sub {
    $ch->query('create table t64_u (a UInt8) engine=Memory', sub {
        my $n = 0;
        my $cb = sub { $n++; undef $ch if $n == 1 };
        $ch->insert('t64_u', [[1]], $cb);
        $ch->query('select count() from t64_u', $cb);
        $ch->query('select 1', sub { EV::break });
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(1, 'H1: undef $ch in callback does not crash');
}

# --- H1: reset() from a callback during a pending insert -----------------
{
    my ($done, $started);
    my $ch; $ch = EV::ClickHouse->new(host => $host, port => $nport,
        protocol => 'native',
        on_error => sub {},
        on_connect => sub {
            return if $started++;
            $ch->query('drop table if exists t64_r', sub {
            $ch->query('create table t64_r (a UInt8) engine=Memory', sub {
                $ch->insert('t64_r', [[1]], sub {
                    my (undef, $e) = @_;
                    $ch->reset;
                    $ch->query('select 1', sub { $done = 1; EV::break });
                });
            }) });
        });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok($done, 'H1: reset during insert keeps the connection usable');
}

# --- tied Array cell round-trip ------------------------------------------
{
    my $ch = new_ch();
    my ($err, $got);
    $ch->query('drop table if exists t64_a', sub {
    $ch->query('create table t64_a (a Array(UInt8)) engine=Memory', sub {
        tie my @cell, 'TA'; @cell = (4, 5, 6);
        $ch->insert('t64_a', [[\@cell]], sub {
            (undef, $err) = @_;
            return EV::break if $err;
            $ch->query('select a from t64_a', sub {
                $got = $_[0][0][0]; EV::break });
        });
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'tied Array cell inserts') or diag $err;
    is_deeply($got, [4, 5, 6], 'tied Array cell reads back');
}

# --- tied Tuple cell round-trip ------------------------------------------
{
    my $ch = new_ch();
    my ($err, $got);
    $ch->query('drop table if exists t64_tp', sub {
    $ch->query('create table t64_tp (t Tuple(UInt8,String)) engine=Memory', sub {
        tie my @tc, 'TA'; @tc = (5, 'hi');
        $ch->insert('t64_tp', [[\@tc]], sub {
            (undef, $err) = @_;
            return EV::break if $err;
            $ch->query('select t from t64_tp', sub {
                $got = $_[0][0][0]; EV::break });
        });
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'tied Tuple cell inserts') or diag $err;
    is_deeply($got, [5, 'hi'], 'tied Tuple reads back');
}

# --- tied row freed before the deferred encode ---------------------------
{
    my $ch = new_ch();
    my ($err, $got);
    $ch->query('drop table if exists t64_tr', sub {
    $ch->query('create table t64_tr (a UInt8, b UInt8) engine=Memory', sub {
        { tie my @row, 'TA'; @row = (1, 2);
          $ch->insert('t64_tr', [\@row], sub {
              (undef, $err) = @_;
              return EV::break if $err;
              $ch->query('select a, b from t64_tr', sub {
                  $got = $_[0][0]; EV::break });
          });
        }
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'freed tied row inserts') or diag $err;
    is_deeply($got, [1, 2], 'freed tied row reads back');
}

# --- tied outer rows AV ----------------------------------------------------
{
    my $ch = new_ch();
    my ($err, $got);
    $ch->query('drop table if exists t64_to', sub {
    $ch->query('create table t64_to (a UInt8) engine=Memory', sub {
        tie my @rows, 'TA'; @rows = ([9], [8]);
        $ch->insert('t64_to', \@rows, sub {
            (undef, $err) = @_;
            return EV::break if $err;
            $ch->query('select sum(a) from t64_to', sub {
                $got = $_[0][0][0]; EV::break });
        });
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'tied outer rows insert') or diag $err;
    is($got, 17, 'tied outer rows read back');
}

# --- HTTP tied row (TSV path, no silent NULLs) -----------------------------
SKIP: {
    skip 'ClickHouse HTTP not reachable', 2 unless $http_ok;
    my $ch = EV::ClickHouse->new(host => $host, port => $hport,
                                 protocol => 'http',
                                 on_connect => sub { EV::break },
                                 on_error => sub { EV::break });
    EV::run;
    my ($err, $got);
    $ch->query('drop table if exists t64_h', sub {
    $ch->query('create table t64_h (a UInt8, b String) engine=Memory', sub {
        tie my @row, 'TA'; @row = (3, 'xy');
        $ch->insert('t64_h', [\@row], sub {
            (undef, $err) = @_;
            return EV::break if $err;
            $ch->query('select a, b from t64_h format TabSeparated', sub {
                $got = $_[0][0]; EV::break });
        });
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'HTTP tied row inserts') or diag $err;
    is_deeply($got, [3, 'xy'], 'HTTP tied row reads back');
}

# --- tied JSON cell ---------------------------------------------------------
SKIP: {
my $have_json = 0;
{
    my $ch = new_ch();
    $ch->query('drop table if exists t64_jprobe', sub {
    $ch->query('create table t64_jprobe (j JSON) engine=Memory', sub {
        $have_json = !$_[1];
        $ch->query('drop table if exists t64_jprobe', sub { EV::break });
    }) });
    my $pt = EV::timer(15, 0, sub { EV::break });
    EV::run;
    $ch->finish;
}
skip 'server has no JSON column type', 2 unless $have_json;
{
    my $ch = new_ch();
    my ($err, $got);
    $ch->query('drop table if exists t64_j', sub {
    $ch->query('create table t64_j (j JSON) engine=Memory', sub {
        tie my %jh, 'TH'; %jh = (n => 5, s => 'ab');
        $ch->insert('t64_j', [[\%jh]], sub {
            (undef, $err) = @_;
            return EV::break if $err;
            $ch->query('select j from t64_j', sub {
                $got = $_[0][0][0]; EV::break });
        });
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'tied JSON cell inserts') or diag $err;
    is_deeply($got, { n => 5, s => 'ab' }, 'tied JSON reads back');
}
}

# --- tied settings: on_data fires, params substitute -----------------------
{
    my $ch = new_ch();
    my ($fired, $perr, $pval);
    tie my %s, 'TH'; %s = (on_data => sub { $fired++ });
    $ch->query('select 1', \%s, sub { EV::break });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    is($fired, 1, 'tied settings on_data fires');
    tie my %p, 'TH'; %p = (x => 7);
    $ch->query('select {x:UInt8} * 2', { params => \%p }, sub {
        my ($rows, $e) = @_; ($perr, $pval) = ($e, $rows->[0][0]); EV::break });
    EV::run;
    ok(!$perr, 'tied params substitute') or diag $perr;
    is($pval, 14, 'tied params value correct');
}

# --- H2: pre-connect query with tied settings ------------------------------
{
    tie my %s, 'TH'; %s = (params => { x => 11 });
    my ($err, $got);
    my $ch = EV::ClickHouse->new(host => $host, port => $nport,
                                 protocol => 'native',
                                 on_error => sub { EV::break });
    $ch->query('select {x:UInt8} + 1', \%s, sub {
        my ($rows, $e) = @_; ($err, $got) = ($e, $rows->[0][0]); EV::break });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'deferred tied settings query works') or diag $err;
    is($got, 12, 'deferred tied settings value correct');
}

# --- L6: negative pool idx does not underflow ------------------------------
{
    my $pool = EV::ClickHouse::Pool->new(host => $host, port => $nport,
                                         protocol => 'native', size => 2);
    $pool->{idx} = -5;
    my ($err, $got);
    $pool->query('select 7', sub {
        my ($rows, $e) = @_; ($err, $got) = ($e, $rows->[0][0]); EV::break });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'L6: negative idx query works') or diag $err;
}

# --- H7: dying SQL tie dies loudly, connection stays healthy ---------------
{
    package DieSQL; our @ISA = ('Tie::StdScalar');
    sub FETCH { die "boom-sql\n" }
    package main;
    my $ch = new_ch();
    tie my $sql, 'DieSQL';
    my $ok = eval { $ch->query($sql, { params => { a => 1 } }, sub {}); 1 };
    like($@, qr/boom-sql/, 'H7: dying SQL dies at the boundary');
    my $got;
    $ch->query('select 8', sub { $got = $_[0][0][0]; EV::break });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    is($got, 8, 'H7: connection healthy after dying SQL');
}

# --- M4: setting value stringified exactly once (single-pass) ---------------
# (An overloaded object: the old size-then-append passes stringified
# twice, so a growing value smashed the URL buffer. A tied scalar
# cannot trigger it — hash construction materializes it first.)
SKIP: {
    skip 'ClickHouse HTTP not reachable', 1 unless $http_ok;
    package CountOv; our $N = 0;
    use overload '""' => sub { $CountOv::N++; '1000000' }, fallback => 1;
    sub new { bless {}, shift }
    package main;
    my $ch = EV::ClickHouse->new(host => $host, port => $hport,
                                 protocol => 'http',
                                 on_connect => sub { EV::break },
                                 on_error => sub { EV::break });
    EV::run;
    my $err;
    $CountOv::N = 0;
    $ch->query('select 1 format TabSeparated',
               { max_rows_to_read => CountOv->new },
               sub { (undef, $err) = @_; EV::break });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err && $CountOv::N == 1, 'M4: one stringify per setting value')
        or diag "err=$err count=$CountOv::N";
}

# --- heap-corrupting-on-base tests last: on unfixed builds the
# --- growing tie (Array BOF) and tied Map (H3 BOF) corrupt the heap,
# --- so they run last to keep earlier fail-before signals clean ------
# --- growing FETCHSIZE fails clean ---------------------------------------
{
    package GrowArr; our @ISA = ('Tie::StdArray');
    my $n = 0;
    sub FETCHSIZE { $n++; 3 + $n * 100 }
    package main;
    my $ch = new_ch();
    my $err;
    $ch->query('drop table if exists t64_g', sub {
    $ch->query('create table t64_g (a Array(UInt8)) engine=Memory', sub {
        tie my @g, 'GrowArr'; @g = (1, 2, 3);
        $ch->insert('t64_g', [[\@g]], sub { (undef, $err) = @_; EV::break });
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    like($err // '', qr/encoding failed/, 'growing tie fails clean');
}

# --- tied Map cell round-trip --------------------------------------------
{
    my $ch = new_ch();
    my ($err, $got);
    $ch->query('drop table if exists t64_m', sub {
    $ch->query('create table t64_m (m Map(String,UInt8)) engine=Memory', sub {
        tie my %mh, 'TH'; %mh = (x => 7, y => 8);
        $ch->insert('t64_m', [[\%mh]], sub {
            (undef, $err) = @_;
            return EV::break if $err;
            $ch->query('select m from t64_m', sub {
                $got = $_[0][0][0]; EV::break });
        });
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'tied Map cell inserts') or diag $err;
    is_deeply($got, { x => 7, y => 8 }, 'tied Map keys+values read back');
}
