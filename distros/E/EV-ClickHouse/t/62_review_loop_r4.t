#!/usr/bin/env perl
# Regression tests for review-loop round 4: backtick-quoted type names
# (JSON typed paths, Tuple, Nested), empty Tuple() wire bytes,
# insert_iter loud failure, Iterator::cancel ownership guard,
# cancel_by_query_id staleness, and async-helper validation.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $nat_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
plan skip_all => 'no ClickHouse native at $host:$nport' unless $nat_ok;
plan tests => 28;

sub new_ch {
    my $ch = EV::ClickHouse->new(host => $host, port => $nport,
                                 protocol => 'native',
                                 on_connect => sub { EV::break },
                                 on_error => sub { EV::break });
    EV::run;
    $ch;
}

# True when the server accepts every statement: the blocks below use types and
# behaviour that arrived in 25.x and that 23.8 rejects. Every statement runs
# even after one fails, so a trailing DROP still cleans up.
sub ch_can {
    my @sql = @_;
    my $ch = new_ch();
    my $ok = 1;
    my $run;
    $run = sub {
        my $sql = shift @sql;
        return EV::break unless defined $sql;
        $ch->query($sql, sub { $ok = 0 if $_[1]; $run->() });
    };
    $run->();
    my $t = EV::timer(20, 0, sub { EV::break });
    EV::run;
    $ch->finish;
    undef $run;
    $ok;
}

# --- R4-1: JSON typed path with quoted space ---------------------------------
SKIP: {
skip 'server has no typed JSON paths', 2
    unless ch_can(q{select cast('{}' as JSON(x UInt8))});
{
    my $ch = new_ch();
    my ($rows, $err);
    $ch->query('drop table if exists t62_j', sub {
    $ch->query('create table t62_j (j JSON(`a b` UInt8, z String)) engine=Memory', sub {
    $ch->query(q{insert into t62_j values ('{"a b": 5, "z": "hi"}')}, sub {
        # query_timeout turns the pre-fix hang into a loud error
        $ch->query('select j from t62_j', { query_timeout => 5 }, sub {
            ($rows, $err) = @_;
            $ch->query('drop table t62_j', sub { EV::break });
        });
    }) }) });
    my $t = EV::timer(12, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'R4-1: quoted-space JSON path selects without hang');
    is_deeply($rows, [[{ 'a b' => 5, z => 'hi' }]], 'R4-1: values and keys decode');
    $ch->finish;
}
}

# --- R4-2/3: Tuple with quoted field name ------------------------------------
{
    my $ch = new_ch();
    my ($rows, $err, $irows, $ierr);
    $ch->query("select cast((7,'x') as Tuple(`my col` UInt8, s String)) as t", sub {
        ($rows, $err) = @_;
        $ch->query('drop table if exists t62_t', sub {
        $ch->query('create table t62_t (x Tuple(`my col` UInt8, s String)) engine=Memory', sub {
            $ch->insert('t62_t', [[[1, 'a']], [[2, 'b']]], sub {
                $ch->query('select x from t62_t', sub {
                    ($irows, $ierr) = @_;
                    $ch->query('drop table t62_t', sub { EV::break });
                });
            });
        }) });
    });
    my $t = EV::timer(12, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'R4-2: quoted-name Tuple selects');
    is_deeply($rows, [[[7, 'x']]], 'R4-2: Tuple values decode');
    ok(!$ierr, 'R4-3: quoted-name Tuple inserts');
    is_deeply($irows, [[[1, 'a']], [[2, 'b']]], 'R4-3: Tuple round-trips');
    $ch->finish;
}

# --- R4-4: empty Tuple() ------------------------------------------------------
SKIP: {
skip 'server has no empty Tuple()', 2 unless ch_can('select cast(() as Tuple())');
{
    my $ch = new_ch();
    my ($rows, $err);
    $ch->query('select cast(() as Tuple()) as t, number as x from numbers(3)', sub {
        ($rows, $err) = @_; EV::break;
    });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'R4-4: Tuple() selects');
    is_deeply($rows, [[[], 0], [[], 1], [[], 2]], 'R4-4: empty tuples plus intact sibling column');
    $ch->finish;
}
}

# --- R4-5: Nested with quoted field name --------------------------------------
# 23.8 flattens Nested into n.`a b` / n.c, so the whole column cannot be selected.
SKIP: {
skip 'server flattens Nested columns', 2 unless ch_can(
    'drop table if exists t62_nprobe',
    'create table t62_nprobe (n Nested(`a b` UInt8, c String)) engine=Memory',
    'select n from t62_nprobe',
    'drop table if exists t62_nprobe');
{
    my $ch = new_ch();
    my ($rows, $err);
    $ch->query('drop table if exists t62_n', sub {
    $ch->query('create table t62_n (n Nested(`a b` UInt8, c String)) engine=Memory', sub {
        $ch->insert('t62_n', [[[1, 2], ['p', 'q']]], sub {
            $ch->query('select n from t62_n', sub {
                ($rows, $err) = @_;
                $ch->query('drop table t62_n', sub { EV::break });
            });
        });
    }) });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok(!$err, 'R4-5: quoted-name Nested round-trips');
    is_deeply($rows, [[[[1, 'p'], [2, 'q']]]], 'R4-5: Nested values decode');
    $ch->finish;
}
}

# --- R4-6: insert_iter push_row failure is loud -------------------------------
{
    my $ch = new_ch();
    my ($err, $count);
    $ch->query('drop table if exists t62_ii', sub {
    $ch->query('create table t62_ii (a UInt8) engine=Memory', sub {
        my @rows = ({ a => 1 }, { a => 2 });
        $ch->insert_iter('t62_ii', sub { shift @rows }, sub {
            (undef, $err) = @_;
            $ch->query('select count() from t62_ii', sub {
                my ($r) = @_; $count = $r->[0][0];
                $ch->query('drop table t62_ii', sub { EV::break });
            });
        });
    }) });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok($err, 'R4-6: hashref rows without columns fail the callback');
    like($err, qr/columns/, 'R4-6: error names the missing columns');
    $ch->finish;
}

# --- R4-7/8: Iterator::cancel ownership ---------------------------------------
{
    my $ch = new_ch();
    my $it = $ch->iterate('select number as n from numbers(5)');
    my $n = 0; while (my $b = $it->next(5)) { $n += @$b }
    is($n, 5, 'R4-7: iterator drains');
    my ($slow_err, $ret);
    $ch->query('select sleep(2)', sub { (undef, $slow_err) = @_; EV::break });
    $ret = $it->cancel;
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    is($ret, 0, 'R4-7: late cancel is a no-op returning 0');
    ok(!$slow_err, 'R4-7: unrelated in-flight query survives late cancel');
    # positive control: cancel while active kills the iterator's own query
    my $it2 = $ch->iterate('select sleep(3)');
    my $ret2 = $it2->cancel;
    my $b = $it2->next(5);
    is($ret2, 1, 'R4-8: active cancel issues and returns 1');
    ok(!defined $b && $it2->{done}, 'R4-8: cancelled iterator completes with no batch');
    $ch->finish;
}

# --- R4-9: cancel_by_query_id staleness ---------------------------------------
{
    my $ch = new_ch();
    my ($stale, $live, $live_err);
    $ch->query('select 1', { query_id => 't62_done' }, sub {
        $stale = $ch->cancel_by_query_id('t62_done');
        $ch->query('select sleep(3)', { query_id => 't62_live' }, sub {
            (undef, $live_err) = @_; EV::break;
        });
        my $t2; $t2 = EV::timer(0.3, 0, sub {
            undef $t2;
            $live = $ch->cancel_by_query_id('t62_live');
        });
    });
    my $t = EV::timer(12, 0, sub { EV::break });
    EV::run;
    is($stale, 0, 'R4-9: completed query id no longer matches');
    is($live, 1, 'R4-9: live query id matches');
    ok($live_err, 'R4-9: live query was cancelled');
    $ch->finish;
}

# --- R4-10/11: duration percentile + slow threshold validation -----------------
{
    my $ch = new_ch();
    $ch->track_query_durations(16);
    my ($med, $warns) = (undef, 0);
    {
        local $SIG{__WARN__} = sub { $warns++ };
        $ch->query('select 1', sub { EV::break });
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        $med = $ch->query_duration_p(undef);
    }
    ok(defined $med && $med >= 0, 'R4-10: undef percentile defaults to median');
    is($warns, 0, 'R4-10: no warnings');
    my $died = !eval { $ch->slow_query_log('ten', sub {}); 1 };
    ok($died, 'R4-11: string threshold dies at install');
    $ch->finish;
}

# --- R4-12/13: pool index validation + circuit_state shape ---------------------
{
    my $pool = EV::ClickHouse::Pool->new(hosts => ["$host:$nport"],
                                         protocol => 'native', size => 2);
    my $e1 = !eval { $pool->nominate('x'); 1 };
    my $e2 = !eval { $pool->query_to('x', 'select 1', sub {}); 1 };
    my $ok = eval { $pool->nominate(1); 1 };
    ok($e1 && $e2, 'R4-12: non-numeric index dies');
    ok($ok, 'R4-12: numeric index still works');
    my $st = $pool->circuit_state;
    is(ref $st, 'ARRAY', 'R4-13: scalar circuit_state is an arrayref');
    $pool->finish;
}

# --- R4-14: iterate on_data composition ----------------------------------------
{
    my $ch = new_ch();
    my $fired = 0;
    my $it = $ch->iterate('select number from numbers(100000)',
                          { on_data => sub { $fired++ } });
    my $n = 0; while (my $b = $it->next(10)) { $n += @$b }
    is($n, 100000, 'R4-14: iterator delivers all rows');
    ok($fired > 0, 'R4-14: caller on_data still fires per block');
    $ch->finish;
}
