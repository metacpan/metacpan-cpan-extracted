#!/usr/bin/env perl
# Native-protocol external tables: a per-query `external` option ships
# named in-memory data blocks the query can reference as tables (joins,
# IN filters, etc.) without creating a server-side temp table.
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

plan tests => 16;

# Run one query on a fresh native connection; hand ($rows,$err) to $check.
sub one_query {
    my ($sql, $settings, $check, %opt) = @_;
    my ($rows, $err);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        compress => $opt{compress} ? 1 : 0,
        on_connect => sub {
            $ch->query($sql, $settings, sub { ($rows, $err) = @_; EV::break });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run; undef $t;
    $ch->finish if $ch && $ch->is_connected;
    $check->($rows, $err);
}

# 1-2. Basic: select straight from an external table.
one_query(
    "select n, t from _ext order by n",
    { external => { _ext => {
        structure => [ n => 'UInt32', t => 'String' ],
        data      => [ [3,'c'], [1,'a'], [2,'b'] ],
    } } },
    sub {
        my ($rows, $err) = @_;
        ok !$err, 'external select: no error' or diag $err;
        is_deeply $rows, [[1,'a'],[2,'b'],[3,'c']],
            'external select: rows round-trip in queried order';
    },
);

# 3. IN-filter: the classic "send an id set" pattern.
one_query(
    "select number from numbers(1000) where number in _ids order by number",
    { external => { _ids => {
        structure => [ id => 'UInt64' ],
        data      => [ [7], [42], [911] ],
    } } },
    sub {
        my ($rows, $err) = @_;
        is_deeply $rows, [[7],[42],[911]],
            'external IN-filter: only matching ids returned' or diag $err;
    },
);

# 4. Join a server table-function against an external table.
one_query(
    "select a.number, b.label from numbers(5) a "
  . "join _labels b on a.number = b.id order by a.number",
    { external => { _labels => {
        structure => [ id => 'UInt64', label => 'String' ],
        data      => [ [1,'one'], [3,'three'] ],
    } } },
    sub {
        my ($rows, $err) = @_;
        is_deeply $rows, [[1,'one'],[3,'three']],
            'external join: matched rows' or diag $err;
    },
);

# 5. Compressed connection still ships external tables correctly.
one_query(
    "select sum(v) from _big",
    { external => { _big => {
        structure => [ v => 'Int64' ],
        data      => [ map { [$_] } 1 .. 5000 ],
    } } },
    sub {
        my ($rows, $err) = @_;
        is $rows && $rows->[0][0], 12502500,
            'external table over a compressed connection' or diag $err;
    },
    compress => 1,
);

# 6-7. Multiple external tables referenced by one query.
one_query(
    "select x.n, y.n from _x x join _y y on x.n = y.n order by x.n",
    { external => {
        _x => { structure => [ n => 'UInt32' ], data => [ [1],[2],[3] ] },
        _y => { structure => [ n => 'UInt32' ], data => [ [2],[3],[4] ] },
    } },
    sub {
        my ($rows, $err) = @_;
        ok !$err, 'two external tables: no error' or diag $err;
        is_deeply $rows, [[2,2],[3,3]],
            'two external tables: both usable in one query';
    },
);

# 8. Empty external table (0 rows) is valid.
one_query(
    "select count() from _empty",
    { external => { _empty => {
        structure => [ id => 'UInt64' ],
        data      => [],
    } } },
    sub {
        my ($rows, $err) = @_;
        is $rows && $rows->[0][0], 0,
            'empty external table: zero rows' or diag $err;
    },
);

# 9-10. Mixed column types round-trip.
one_query(
    "select id, name, ratio from _mix order by id",
    { external => { _mix => {
        structure => [ id => 'UInt16', name => 'String', ratio => 'Float64' ],
        data      => [ [10,'ten',1.5], [20,'twenty',2.25] ],
    } } },
    sub {
        my ($rows, $err) = @_;
        ok !$err, 'typed external table: no error' or diag $err;
        is_deeply $rows, [[10,'ten',1.5],[20,'twenty',2.25]],
            'typed external table: Int/String/Float round-trip';
    },
);

# 11-15. Error handling — all croak synchronously from query().
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break }); EV::run; undef $t;

    eval { $ch->query("select 1", { external => { t => [] } }, sub { }) };
    like $@, qr/spec must be a hashref/, 'external: non-hashref spec rejected';

    eval { $ch->query("select 1",
        { external => { t => { data => [[1]] } } }, sub { }) };
    like $@, qr/structure/, 'external: missing structure rejected';

    eval { $ch->query("select 1",
        { external => { t => { structure => [ 'n' ], data => [[1]] } } }, sub { }) };
    like $@, qr/even list of name => type/, 'external: odd structure rejected';

    eval { $ch->query("select 1",
        { external => { t => {
            structure => [ n => 'UInt32' ], data => [ 'notaref' ] } } }, sub { }) };
    like $@, qr/each data row must be an arrayref/,
        'external: non-arrayref data row rejected';

    eval { $ch->query("select 1",
        { external => { t => {
            structure => [ n => 'NoSuchType' ], data => [[1]] } } }, sub { }) };
    like $@, qr/cannot encode column/, 'external: unencodable type rejected';

    $ch->finish;
}

# 16. external on an HTTP connection croaks.
SKIP: {
    skip "ClickHouse HTTP not reachable", 1
        unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        on_connect => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break }); EV::run; undef $t;
    eval { $ch->query("select 1", { external => { t => {
        structure => [ n => 'UInt32' ], data => [[1]] } } }, sub { }) };
    like $@, qr/only supported with the native protocol/,
        'external tables croak on the HTTP protocol';
    $ch->finish;
}
