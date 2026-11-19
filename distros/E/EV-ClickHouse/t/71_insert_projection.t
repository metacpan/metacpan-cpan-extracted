use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;
use B ();
use Tie::Array;

# columns_at (insert column j reads $row->[$columns_at[j]]) over native
# and HTTP, the insert snapshot, and the chunked native encode.

my $host  = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;
my $hport = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

require IO::Socket::INET;
plan skip_all => "ClickHouse not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2)
        && IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);

{ package TA; our @ISA = ('Tie::StdArray'); }

my %conn;
sub conn {
    my ($proto) = @_;
    my $ch = $conn{$proto};
    return $ch if $ch && $ch->is_connected;
    my ($ok, $err);
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $proto eq 'native' ? $nport : $hport,
        protocol   => $proto,
        on_connect => sub { $ok = 1; EV::break },
        on_error   => sub { $err = $_[0]; EV::break },
    );
    my $t = EV::timer(10, 0, sub { $err //= 'connect timeout'; EV::break });
    EV::run until $ok || $err;
    die "connect $proto: $err" unless $ok;
    $ch->on_error(sub { });
    return $conn{$proto} = $ch;
}

sub wait_for {
    my ($start) = @_;
    my ($res, $err, $done);
    $start->(sub { ($res, $err) = @_; $done = 1; EV::break });
    my $t = EV::timer(20, 0, sub { $err //= 'timeout'; $done = 1; EV::break });
    EV::run until $done;
    return ($res, $err);
}

sub q_native {
    my ($sql) = @_;
    my $ch = conn('native');
    my ($res, $err) = wait_for(sub { $ch->query($sql, $_[0]) });
    delete $conn{native} if $err;
    die "$sql: $err" if $err && $sql =~ /^(create|drop|truncate)/;
    return ($res, $err);
}

sub ins {
    my ($proto, $table, $data, $opts, $after) = @_;
    my $ch = conn($proto);
    my (undef, $err) = wait_for(sub {
        $ch->insert($table, $data, $opts ? $opts : (), $_[0]);
        $after->() if $after;
    });
    delete $conn{$proto} if $err;
    return $err;
}

sub rows_of {
    my ($table, $cols) = @_;
    my ($rows, $err) = q_native("select $cols from $table order by $cols");
    return $err ? "ERR $err" : $rows;
}

my $t = 'pf_proj';
my $ddl = "create table $t (a UInt32, b String, c Nullable(String)) engine = MergeTree order by tuple()";

for my $proto ('native', 'http') {
    my @wide = map { my $r = $_; [ map { "r${r}c$_" } 0 .. 11 ] } 0 .. 2;
    $wide[$_][7] = 10 + $_ for 0 .. 2;

    q_native("drop table if exists $t");
    q_native($ddl);
    my $err = ins($proto, "$t (a, b, c)", \@wide, { columns_at => [7, 2, 11] });
    ok(!$err, "$proto: wide rows insert") or diag $err;
    is_deeply(rows_of($t, 'a, b, c'),
        [ map { [ 10 + $_, "r${_}c2", "r${_}c11" ] } 0 .. 2 ],
        "$proto: column j reads row position columns_at[j]");

    q_native("truncate table $t");
    $err = ins($proto, "$t (a, b, c)", [ [5, 'x'], [6, 'y'] ], { columns_at => [0, 1, 1] });
    ok(!$err, "$proto: repeated position insert") or diag $err;
    is_deeply(rows_of($t, 'a, b, c'), [ [5, 'x', 'x'], [6, 'y', 'y'] ],
        "$proto: a position may feed several columns");

    q_native("truncate table $t");
    $err = ins($proto, "$t (c, b, a)", [ [1, 'p', 'q'] ], { columns_at => [2, 1, 0] });
    ok(!$err, "$proto: reordered insert") or diag $err;
    is_deeply(rows_of($t, 'a, b, c'), [ [1, 'p', 'q'] ], "$proto: reordering");

    q_native("truncate table $t");
    $err = ins($proto, "$t (a, b, c)", [ [3, 'z'], [4, 'w', 'v'] ], { columns_at => [0, 1, 2] });
    ok(!$err, "$proto: short row insert") or diag $err;
    is_deeply(rows_of($t, 'a, b, c'), [ [3, 'z', undef], [4, 'w', 'v'] ],
        "$proto: a position past the row end reads as undef");

    q_native("truncate table $t");
    {
        tie my @r1, 'TA'; @r1 = (0, 'k', 7, 'm');
        tie my @outer, 'TA'; @outer = (\@r1, [0, 'n', 8, undef]);
        $err = ins($proto, "$t (a, b, c)", \@outer, { columns_at => [2, 1, 3] });
    }
    ok(!$err, "$proto: tied rows insert") or diag $err;
    is_deeply(rows_of($t, 'a, b, c'), [ [7, 'k', 'm'], [8, 'n', undef] ],
        "$proto: tied rows project");

    q_native("truncate table $t");
    $err = ins($proto, "$t (a, b, c)", [ [1, 'x', 'y', 'extra'] ], { columns_at => [0, 1] });
    ok($err, "$proto: fewer positions than columns is an insert error");
    is_deeply(rows_of($t, 'count()'), [ [0] ], "$proto: nothing inserted on count mismatch");

    for my $with (0, 1) {
        q_native("truncate table $t");
        my @rows = ([1, 'a', 'b'], [2, 'c', 'd']);
        my $keep = $rows[1];
        $err = ins($proto, "$t (a, b, c)", \@rows,
            $with ? { columns_at => [0, 1, 2] } : undef,
            sub { @{ $rows[0] } = (); $rows[1] = [9, 'q', 'q']; push @rows, [3, 'e', 'f']; @$keep = () });
        ok(!$err, "$proto: insert then mutate (columns_at $with)") or diag $err;
        is_deeply(rows_of($t, 'a, b, c'), [ [1, 'a', 'b'], [2, 'c', 'd'] ],
            "$proto: clearing or replacing rows after insert() changes nothing (columns_at $with)");
    }
    q_native("drop table $t");
}

{
    my $ch = conn('native');
    for my $bad ('x', {}, [], [-1], [1.5], ['a'], [undef], [[0]], [0, 'nan']) {
        my $ok = eval { $ch->insert('pf_none', [[1]], { columns_at => $bad }, sub { }); 1 };
        like($ok ? '' : $@, qr/columns_at must be a non-empty array of non-negative integers/,
            'invalid columns_at croaks: ' . (ref $bad ? '[' . join(',', map { $_ // 'undef' } ref $bad eq 'ARRAY' ? @$bad : ()) . ']' : $bad));
    }
    my $ok = eval { $ch->insert('pf_none', "1\n", { columns_at => [0] }, sub { }); 1 };
    like($ok ? '' : $@, qr/columns_at needs the data as an array of rows/,
        'columns_at with TSV text croaks');
    my $h = conn('http');
    $ok = eval { $h->insert('pf_none', [[1]], { columns_at => [-2] }, sub { }); 1 };
    like($ok ? '' : $@, qr/columns_at must be/, 'HTTP validates columns_at too');
    delete @conn{qw(native http)};
    $_->finish for $ch, $h;
}

# Native insert no longer stringifies the caller's numbers.
{
    q_native('drop table if exists pf_num');
    q_native('create table pf_num (a UInt32, d DateTime, e Int32, f UInt16) engine = Memory');
    my @row = (42, 1700000000, -5, 7);
    my $err = ins('native', 'pf_num', [ \@row ]);
    ok(!$err, 'numeric insert') or diag $err;
    my @pok = grep { B::svref_2object(\$row[$_])->FLAGS & (B::SVf_POK | B::SVp_POK) } 0 .. $#row;
    is_deeply(\@pok, [], 'inserted numbers keep no string form');
    is_deeply(rows_of('pf_num', 'a, toUnixTimestamp(d), e, f'), [ [42, 1700000000, -5, 7] ],
        'numeric values round-trip');
    q_native('drop table pf_num');
}

# Chunked encode: values across several 1024-row chunks round-trip
# exactly, and an error names the first failing column.
{
    my $tb = 'pf_chunk';
    q_native("drop table if exists $tb");
    q_native("create table $tb (id UInt32, n Nullable(String), a Array(UInt16),"
           . " l LowCardinality(String), d Decimal(18, 3), t DateTime('UTC'),"
           . " e Enum8('x' = 1, 'y' = 2), s String, ln LowCardinality(Nullable(String)))"
           . " engine = MergeTree order by id");
    my $N = 2600;
    my @rows = map {
        [ $_, ($_ % 7 ? "n$_" : undef), [ (1) x ($_ % 4) ], 'l' . ($_ % 300),
          ($_ % 2 ? "$_.125" : $_), ($_ % 3 ? 1700000000 + $_ : '2024-01-02 03:04:05'),
          ($_ % 2 ? 'x' : 2), "s$_", ($_ % 5 ? "m$_" : undef) ]
    } 0 .. $N - 1;
    my $err = ins('native', $tb, \@rows);
    ok(!$err, 'multi-chunk insert') or diag $err;
    my ($got, $e2) = q_native("select id, n, toString(a), l, toString(d), toUnixTimestamp(t),"
                            . " toString(e), s, ln from $tb order by id");
    my @want = map {
        [ $_, ($_ % 7 ? "n$_" : undef), '[' . join(',', (1) x ($_ % 4)) . ']', 'l' . ($_ % 300),
          ($_ % 2 ? "$_.125" : "$_"), ($_ % 3 ? 1700000000 + $_ : 1704164645),
          ($_ % 2 ? 'x' : 'y'), "s$_", ($_ % 5 ? "m$_" : undef) ]
    } 0 .. $N - 1;
    is_deeply($got, \@want, 'multi-chunk values round-trip');

    my @bad = map { [@$_] } @rows[0 .. 2099];
    $bad[2000][0] = 'not-a-number';
    $bad[3][4] = 'not-a-number';
    $err = ins('native', $tb, \@bad);
    like($err // '', qr/encoding failed/, 'bad values fail the insert');
    like($err // '', qr/column 'id'/, 'the first failing column is reported, not the first failing row');
    q_native("drop table $tb");
}

# Tied scalars as rows or cells are read once, when insert() is called.
{
    { package CountTie;
      sub TIESCALAR { bless { v => $_[1], n => 0 }, $_[0] }
      sub FETCH { $_[0]{n}++; $_[0]{v} }
      sub STORE { $_[0]{v} = $_[1] } }
    q_native('drop table if exists pf_magic');
    q_native('create table pf_magic (a UInt32, arr Array(UInt8)) engine = Memory');
    my @rows;
    tie $rows[0], 'CountTie', [1, [2, 3]];
    $rows[1] = [undef, []];
    tie $rows[1][0], 'CountTie', 7;
    $rows[2] = [9, undef];
    tie $rows[2][1], 'CountTie', [4];
    my $err = ins('native', 'pf_magic (a, arr)', \@rows, undef,
        sub { (tied $rows[1][0])->{v} = 99 });
    ok(!$err, 'tied row and tied cells insert') or diag $err;
    is_deeply(rows_of('pf_magic', 'a, arr'), [ [1, [2, 3]], [7, []], [9, [4]] ],
        'tied values read at insert() time');
    is((tied $rows[1][0])->{n}, 1, 'a tied cell is fetched once');
    q_native('drop table pf_magic');
}

done_testing;
