use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# LowCardinality nested in Array/Map/Tuple over the native protocol: the
# KeysSerializationVersion prefixes of a column precede all of its data,
# and an LC node with zero values writes nothing.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

my %conn;
my $has_lz4 = 1;

sub conn {
    my ($compress) = @_;
    my $ch = $conn{$compress};
    return $ch if $ch && $ch->is_connected;
    my ($ok, $err);
    $ch = eval {
        EV::ClickHouse->new(
            host       => $host,
            port       => $port,
            protocol   => 'native',
            compress   => $compress,
            on_connect => sub { $ok = 1; EV::break },
            on_error   => sub { $err = $_[0]; EV::break },
        );
    };
    if (!$ch) { $has_lz4 = 0 if $compress; return }
    my $t = EV::timer(10, 0, sub { $err //= 'connect timeout'; EV::break });
    EV::run until $ok || $err;
    return unless $ok;
    $ch->on_error(sub { });
    return $conn{$compress} = $ch;
}

# a failed or wedged query must not leave later checks queued behind it
sub drop_conn {
    my ($compress) = @_;
    my $ch = delete $conn{$compress} or return;
    $ch->finish if $ch->is_connected;
}

sub wait_for {
    my ($start) = @_;
    my ($res, $err, $done);
    $start->(sub { ($res, $err) = @_; $done = 1; EV::break });
    my $t = EV::timer(10, 0, sub { $err //= 'timeout'; $done = 1; EV::break });
    EV::run until $done;
    return ($res, $err);
}

# mode: plain | lz4 | stream
sub sel {
    my ($sql, $mode) = @_;
    $mode //= 'plain';
    my $compress = $mode eq 'lz4' ? 1 : 0;
    my $ch = conn($compress) or return (undef, 'no connection');
    my @rows;
    my ($res, $err) = $mode eq 'stream'
        ? wait_for(sub {
            $ch->query($sql, { on_data => sub { push @rows, @{ $_[0] } } }, $_[0]);
        })
        : wait_for(sub { $ch->query($sql, $_[0]) });
    drop_conn($compress) if $err;
    return ($err ? undef : $mode eq 'stream' ? \@rows : $res, $err);
}

sub run_ok {
    my ($sql) = @_;
    my (undef, $err) = sel($sql);
    ok(!$err, $sql) or diag $err;
}

sub ins {
    my ($table, $data) = @_;
    my $ch = conn(0) or return 'no connection';
    my (undef, $err) = wait_for(sub { $ch->insert($table, $data, $_[0]) });
    drop_conn(0) if $err;
    return $err;
}

my @modes = ('plain', 'stream');
push @modes, 'lz4' if conn(1);

sub sel_is {
    my ($sql, $want, $name) = @_;
    for my $mode (@modes) {
        my ($rows, $err) = sel($sql, $mode);
        ok(!$err, "$name [$mode]: no error") or diag $err;
        is_deeply($rows, $want, "$name [$mode]: rows");
    }
}

sub server_strings {
    my ($table, $expr) = @_;
    my ($rows, $err) = sel("select toString($expr) from $table order by id");
    return $err ? "ERR $err" : [ map { $_->[0] } @$rows ];
}

sub round_trip {
    my (%a) = @_;
    my $t = "lc_$a{tag}";
    my @ids = (1 .. @{ $a{rows} });
    run_ok("drop table if exists $t");
    run_ok("create table $t (id UInt32, a $a{type}) engine = Memory");
    my $blocks = $a{blocks} || [ [ 0 .. $#ids ] ];
    for my $b (@$blocks) {
        my $err = ins("$t (id, a)", [ map { [ $ids[$_], $a{rows}[$_] ] } @$b ]);
        ok(!$err, "$a{type} $a{tag}: insert") or diag $err;
    }
    is_deeply(server_strings($t, $a{expr} || 'a'), $a{strings},
        "$a{type} $a{tag}: server sees inserted values");
    sel_is("select id, a from $t order by id",
        [ map { [ $ids[$_], $a{rows}[$_] ] } 0 .. $#ids ],
        "$a{type} $a{tag}: select");
    run_ok("drop table $t");
}

round_trip(
    tag     => 'arr',
    type    => 'Array(LowCardinality(String))',
    rows    => [ ['a', 'b'], ['c'], [], ['a', 'b', 'a'], [], [] ],
    blocks  => [ [0, 1], [2, 3], [4, 5] ],
    strings => [ "['a','b']", "['c']", '[]', "['a','b','a']", '[]', '[]' ],
);

round_trip(
    tag     => 'arr1',
    type    => 'Array(LowCardinality(String))',
    rows    => [ ['x'] ],
    strings => [ "['x']" ],
);

round_trip(
    tag     => 'arr2',
    type    => 'Array(Array(LowCardinality(String)))',
    rows    => [ [ ['a'], ['b', 'c'] ], [ [] ], [], [ ['d'] ] ],
    strings => [ "[['a'],['b','c']]", '[[]]', '[]', "[['d']]" ],
);

round_trip(
    tag     => 'map_k',
    type    => 'Map(LowCardinality(String), UInt8)',
    rows    => [ {}, { k => 1 }, { a => 2, b => 3 } ],
    expr    => 'mapSort(a)',
    strings => [ '{}', "{'k':1}", "{'a':2,'b':3}" ],
);

round_trip(
    tag     => 'map_v',
    type    => 'Map(String, LowCardinality(String))',
    rows    => [ { x => 'p' }, {}, { y => 'q', z => 'q' } ],
    expr    => 'mapSort(a)',
    strings => [ "{'x':'p'}", '{}', "{'y':'q','z':'q'}" ],
);

round_trip(
    tag     => 'map_kv',
    type    => 'Map(LowCardinality(String), Array(LowCardinality(String)))',
    rows    => [ { k => ['a', 'b'], j => [] }, {}, { m => ['c'] } ],
    expr    => 'mapSort(a)',
    strings => [ "{'j':[],'k':['a','b']}", '{}', "{'m':['c']}" ],
);

round_trip(
    tag     => 'tup1',
    type    => 'Tuple(String, LowCardinality(String))',
    rows    => [ ['b', 'a'], ['d', 'c'] ],
    strings => [ "('b','a')", "('d','c')" ],
);

round_trip(
    tag     => 'tup2',
    type    => 'Tuple(LowCardinality(String), LowCardinality(String))',
    rows    => [ ['a', 'b'], ['a', 'c'] ],
    strings => [ "('a','b')", "('a','c')" ],
);

round_trip(
    tag     => 'arrn',
    type    => 'Array(LowCardinality(Nullable(String)))',
    rows    => [ ['a', undef, 'b'], [undef], [] ],
    strings => [ "['a',NULL,'b']", '[NULL]', '[]' ],
);

round_trip(
    tag     => 'top',
    type    => 'LowCardinality(String)',
    rows    => [ 'x', 'y', 'x' ],
    strings => [ 'x', 'y', 'x' ],
);

round_trip(
    tag     => 'topn',
    type    => 'LowCardinality(Nullable(String))',
    rows    => [ 'x', undef ],
    strings => [ 'x', undef ],
);

# index width: >255 keys -> UInt16, >65535 keys -> UInt32
{
    my @w300 = map { "v$_" } 0 .. 299;
    my @w70k = map { "v$_" } 0 .. 69_999;
    my @n255 = ((map { "n$_" } 0 .. 253), undef);
    my $t = 'lc_wide';
    run_ok("drop table if exists $t");
    run_ok("create table $t (id UInt32, a Array(LowCardinality(String)),"
         . " n Array(LowCardinality(Nullable(String)))) engine = Memory");
    my $err = ins("$t (id, a, n)",
        [ [1, \@w300, \@n255], [2, \@w70k, []], [3, [], ['z']] ]);
    ok(!$err, 'wide: insert') or diag $err;
    my ($rows, $e) = sel("select id, length(a), a[1], a[-1], length(arrayDistinct(a)),"
        . " length(n), countEqual(n, null), toString(n[1]) from $t order by id");
    ok(!$e, 'wide: server summary') or diag $e;
    is_deeply($rows, [
        [1, 300, 'v0', 'v299', 300, 255, 1, 'n0'],
        [2, 70_000, 'v0', 'v69999', 70_000, 0, 0, undef],
        [3, 0, '', '', 0, 1, 0, 'z'],
    ], 'wide: server sees inserted values');
    sel_is("select id, a, n from $t order by id",
        [ [1, \@w300, \@n255], [2, \@w70k, []], [3, [], ['z']] ],
        'wide: select');
    run_ok("drop table $t");

    sel_is('select cast(arrayMap(x -> toString(x), range(300)) as Array(LowCardinality(String)))',
        [ [ [ map { "$_" } 0 .. 299 ] ] ], 'server-built 300 keys');
    sel_is('select cast(arrayMap(x -> toString(x), range(70000)) as Array(LowCardinality(String)))',
        [ [ [ map { "$_" } 0 .. 69_999 ] ] ], 'server-built 70000 keys');
}

# server-built values, independent of the encoder
sel_is('select cast([] as Array(LowCardinality(String)))', [ [ [] ] ], 'empty LC array');
sel_is('select cast([] as Array(LowCardinality(String))) from numbers(3)',
    [ [ [] ], [ [] ], [ [] ] ], 'empty LC array x3');
sel_is(q{select cast(['a','b'] as Array(LowCardinality(String)))},
    [ [ ['a', 'b'] ] ], 'LC array');
sel_is(q{select [toLowCardinality('a'), toLowCardinality('b')]},
    [ [ ['a', 'b'] ] ], 'LC array literal');
sel_is(q{select cast(if(number = 1, [], [toString(number)]) as Array(LowCardinality(String)))}
     . q{ from numbers(3)},
    [ [ ['0'] ], [ [] ], [ ['2'] ] ], 'mixed empty/non-empty LC arrays');
sel_is(q{select map(toLowCardinality('k1'), 1, toLowCardinality('k2'), 2)},
    [ [ { k1 => 1, k2 => 2 } ] ], 'LC-keyed map');
sel_is(q{select tuple('b', toLowCardinality('a'))}, [ [ ['b', 'a'] ] ], 'tuple(String, LC)');
sel_is(q{select tuple(toLowCardinality('a'), 'b', toLowCardinality('c'))},
    [ [ ['a', 'b', 'c'] ] ], 'tuple(LC, String, LC)');
sel_is(q{select [[toLowCardinality('a')], []]}, [ [ [ ['a'], [] ] ] ], 'LC array of arrays');

# WITH TOTALS: the totals row holds an empty LC array
{
    my $sql = q{select cast(if(number < 2, ['a'], []) as Array(LowCardinality(String))) as k,}
            . q{ count() as c}
            . q{ from numbers(4) group by k with totals order by c, length(k)};
    for my $mode (@modes) {
        my ($rows, $err) = sel($sql, $mode);
        ok(!$err, "totals [$mode]: no error") or diag $err;
        is_deeply($rows, [ [ [], 2 ], [ ['a'], 2 ] ], "totals [$mode]: rows");
        my $ch = conn($mode eq 'lz4' ? 1 : 0);
        is_deeply($ch && $ch->last_totals, [ [ [], 4 ] ], "totals [$mode]: totals row");
    }
}

# JSON typed path prefixes sit inside the JSON prefix
SKIP: {
    sel("drop table if exists lc_json");
    my (undef, $err) = sel("create table lc_json (id UInt32,"
        . " j JSON(a LowCardinality(String))) engine = Memory");
    skip "JSON type not available: $err", 5 + 4 * @modes
        if $err && $err =~ /JSON|experimental|Unknown data type/i;
    ok(!$err, 'JSON(LC typed path): create table') or diag $err;
    $err = ins('lc_json (id, j)', [ [1, { a => 'x', b => 7 }], [2, { a => 'y' }] ]);
    ok(!$err, 'JSON(LC typed path): insert') or diag $err;
    is_deeply(server_strings('lc_json', 'j.a'), ['x', 'y'],
        'JSON(LC typed path): server sees typed path');
    is_deeply(server_strings('lc_json', q{if(isNull(j.b), 'NULL', toString(j.b))}), ['7', 'NULL'],
        'JSON(LC typed path): server sees dynamic path');
    sel_is('select j from lc_json order by id',
        [ [ { a => 'x', b => 7 } ], [ { a => 'y' } ] ], 'JSON(LC typed path): select');
    sel_is(q{select cast('{"a":"x","b":7}', 'JSON(a LowCardinality(String))')},
        [ [ { a => 'x', b => 7 } ] ], 'JSON(LC typed path): server-built');
    run_ok('drop table lc_json');
}

# TabSeparated string payload: top-level LC through encode_column_text
{
    my $t = 'lc_tsv';
    run_ok("drop table if exists $t");
    run_ok("create table $t (id UInt32, a LowCardinality(String),"
         . " n LowCardinality(Nullable(String))) engine = Memory");
    my $err = ins("$t (id, a, n)", "1\tx\t\\N\n2\ty\tz\n");
    ok(!$err, 'TSV LC: insert') or diag $err;
    my ($rows, $e) = sel("select id, a, n from $t order by id");
    ok(!$e, 'TSV LC: select') or diag $e;
    is_deeply($rows, [ [1, 'x', undef], [2, 'y', 'z'] ], 'TSV LC: values');
    run_ok("drop table $t");
}

# Malformed blocks from a mock server fail the query instead of waiting forever.
{
    require IO::Select;
    require POSIX;
    my $vu = sub {
        my ($v) = @_;
        my $bytes = '';
        do { my $b = $v & 127; $v >>= 7; $bytes .= chr($b | ($v ? 128 : 0)) } while $v;
        $bytes;
    };
    my $vstr = sub { $vu->(length $_[0]) . $_[0] };
    my $u64  = sub { pack 'Q<', $_[0] };
    my $drain = sub {
        my ($s) = @_;
        my $sel = IO::Select->new($s);
        while ($sel->can_read(.05)) { sysread($s, my $buf, 65536) or last }
    };
    my $hello = "\x00" . $vstr->('mock') . $vu->(1) . $vu->(1) . $vu->(54492)
              . $vstr->('UTC') . $vstr->('mock') . $vu->(0);

    for my $case (
        [ 'decreasing array offsets', 'Array(UInt8)', 3,
          $u64->(1) . $u64->(0) . $u64->(0) ],
        [ 'LowCardinality version 2', 'Array(LowCardinality(String))', 1,
          $u64->(2) . $u64->(0) ],
        [ 'LowCardinality index past the dictionary', 'LowCardinality(String)', 1,
          $u64->(1) . $u64->(0x600) . $u64->(1) . "\x00" . $u64->(1) . "\x05" ],
        [ 'LowCardinality global dictionary flag', 'LowCardinality(String)', 1,
          $u64->(1) . $u64->(0x700) . $u64->(1) . "\x00" . $u64->(1) . "\x00" ],
    ) {
        my ($name, $type, $rows, $data) = @$case;
        my $listener = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1', Listen => 1, ReuseAddr => 1) or die $!;
        my $pid = fork // die $!;
        if (!$pid) {
            alarm 10;
            my $s = $listener->accept or POSIX::_exit(0);
            $drain->($s);
            syswrite $s, $hello;
            $drain->($s);
            syswrite $s, $vu->(1) . $vstr->('') . "\x01\x00\x02\xff\xff\xff\xff\x00"
                . $vu->(1) . $vu->($rows) . $vstr->('c') . $vstr->($type) . "\x00" . $data;
            sleep 5;
            POSIX::_exit(0);
        }
        my $port = $listener->sockport;
        close $listener;
        my ($ch, $done, $err);
        $ch = EV::ClickHouse->new(
            host => '127.0.0.1', port => $port, protocol => 'native', compress => 0,
            on_connect => sub {
                $ch->query('select c', sub { ($done, $err) = (1, $_[1]); EV::break });
            },
            on_error => sub { },
        );
        my $t = EV::timer(3, 0, sub { EV::break });
        EV::run;
        ok($done, "mock $name: query completes");
        like($err // '', qr/decode_column failed/, "mock $name: decode error");
        $ch->finish if $ch->is_connected;
        undef $ch;
        kill 'TERM', $pid;
        waitpid $pid, 0;
    }
}

done_testing;
