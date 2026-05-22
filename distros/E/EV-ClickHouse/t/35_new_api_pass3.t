#!/usr/bin/env perl
# Pass-3 batch coverage: on_query_start, kill_query, insert_iter,
# Streamer::columns_from_table, Pool::with_each, last_tls_error.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

plan tests => 10;

# 1. on_query_start fires with the dispatched query_id.
{
    my $seen_qid;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_query_start => sub { $seen_qid = shift },
        on_connect => sub {
            $ch->query("select 1", { query_id => 'pass3-qstart' }, sub { EV::break });
        },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run; undef $t;
    is $seen_qid, 'pass3-qstart',  'on_query_start fires with query_id';
    eval { $ch->finish };
}

# 2. last_tls_error: defaults to undef; populates after a cert/key mismatch.
{
    my $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
    );
    is $ch->last_tls_error, undef,  'last_tls_error undef before any TLS work';
    eval { $ch->finish };
}

# 3. kill_query validates the id (reject SQL-injection-like values).
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
        on_error   => sub { EV::break },
    );
    my $t = EV::timer(3, 0, sub { EV::break }); EV::run; undef $t;
    eval { $ch->kill_query("'; drop table--", sub {}) };
    like $@, qr/invalid query_id/, 'kill_query rejects bogus id';
    # Real kill_query with a no-op id — succeeds (KILL with no matching
    # row returns empty result, not an error).
    my $err;
    $ch->kill_query('nope-nonexistent-xyz', sub {
        (undef, $err) = @_; EV::break;
    });
    $t = EV::timer(5, 0, sub { EV::break }); EV::run; undef $t;
    ok !$err, 'kill_query against non-existent id is a no-op'
        or diag "err: $err";
    eval { $ch->finish };
}

# 4. insert_iter pumps rows from a generator.
{
    my $tbl = "ev_ch_iter_$$";
    my $err_phase;
    my @rows = ([1,'a'],[2,'b'],[3,'c'],[4,'d']);
    my $i = 0;
    my $count;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table $tbl (n UInt32, s String) engine=Memory", sub {
                my (undef, $e) = @_;
                $err_phase = "ddl: $e" if $e;
                $ch->insert_iter($tbl, sub {
                    return $i < @rows ? $rows[$i++] : undef;
                }, sub {
                    my (undef, $e) = @_;
                    $err_phase = "ins: $e" if $e;
                    $ch->query("select count() from $tbl", sub {
                        my ($got, $e) = @_;
                        $count = $got->[0][0] if $got;
                        $ch->query("drop table $tbl", sub { EV::break });
                    });
                }, batch_size => 2);
            });
        },
        on_error => sub { $err_phase = "conn: $_[0]"; EV::break },
    );
    my $t = EV::timer(8, 0, sub { EV::break }); EV::run; undef $t;
    is $err_phase, undef, 'insert_iter: no errors';
    is $count, 4,         'insert_iter: all rows landed';
    eval { $ch->finish };
}

# 5. Streamer::columns_from_table auto-discovers schema.
{
    my $tbl = "ev_ch_cft_$$";
    my $names;
    my $err_phase;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table $tbl (a UInt32, b String, c Float64) engine=Memory", sub {
                my (undef, $e) = @_;
                $err_phase = "ddl: $e" if $e;
                my $s = $ch->insert_streamer($tbl);
                $s->columns_from_table(sub {
                    my ($e) = @_;
                    $err_phase = "cft: $e" if $e;
                    $names = $s->{columns};
                    $ch->query("drop table $tbl", sub { EV::break });
                });
            });
        },
        on_error => sub { $err_phase = "conn: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break }); EV::run; undef $t;
    is_deeply $names, [qw(a b c)], 'columns_from_table populates column list';
    is $err_phase, undef,          'columns_from_table: no errors';
    eval { $ch->finish };
}

# 6. Pool::with_each calls every member with ($conn, $idx).
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 3,
    );
    my @seen;
    $pool->with_each(sub { push @seen, [ref($_[0]), $_[1]] });
    is_deeply [ map { $_->[1] } @seen ], [0,1,2], 'with_each: all indexes visited';
    is_deeply [ map { $_->[0] } @seen ],
              ['EV::ClickHouse','EV::ClickHouse','EV::ClickHouse'],
              'with_each: passes each connection object';
    $pool->finish;
}
