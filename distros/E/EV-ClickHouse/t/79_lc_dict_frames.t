use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# LowCardinality columns travel as a deduplicated dictionary; native
# inserts are compressed in bounded frames, LZ4 or ZSTD.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

my $has_zstd = EV::ClickHouse->features->{zstd};
my %conn;

sub conn {
    my (%o) = @_;
    my $key = join ',', map { "$_=$o{$_}" } sort keys %o;
    my $ch = $conn{$key};
    return $ch if $ch && $ch->is_connected;
    my ($ok, $err);
    $ch = EV::ClickHouse->new(
        host => $host, port => $port, protocol => 'native',
        on_connect => sub { $ok = 1; EV::break },
        on_error   => sub { $err = $_[0]; EV::break },
        %o,
    );
    my $t = EV::timer(10, 0, sub { $err //= 'connect timeout'; EV::break });
    EV::run until $ok || $err;
    die "connect: $err\n" unless $ok;
    $ch->on_error(sub { });
    return $conn{$key} = $ch;
}

sub wait_for {
    my ($start) = @_;
    my ($res, $err, $done);
    $start->(sub { ($res, $err) = @_; $done = 1; EV::break });
    my $t = EV::timer(60, 0, sub { $err //= 'timeout'; $done = 1; EV::break });
    EV::run until $done;
    return ($res, $err);
}

sub q_ok {
    my ($sql, %o) = @_;
    my $settings = $sql =~ /^create/ ? { allow_suspicious_low_cardinality_types => 1 } : {};
    my ($res, $err) = wait_for(sub { conn(%o)->query($sql, $settings, $_[0]) });
    ok(!$err, $sql =~ s/\s+/ /gr) or diag $err;
    return $res;
}

sub ins {
    my ($table, $data, $settings, %o) = @_;
    my (undef, $err) = wait_for(sub { conn(%o)->insert($table, $data, $settings // {}, $_[0]) });
    return $err;
}

my $qid = 0;
sub qid { sprintf 'evch_t79_%d_%d_%d', $$, time, ++$qid }

# ProfileEvents of the query, or undef when query_log is unavailable
sub events {
    my ($id) = @_;
    my (undef, $err) = wait_for(sub { conn()->query('system flush logs', $_[0]) });
    return if $err;
    my ($rows) = wait_for(sub {
        conn()->query("select ProfileEvents from system.query_log where query_id = '$id'"
            . " and type = 'QueryFinish' limit 1", $_[0]);
    });
    return $rows && @$rows ? $rows->[0][0] : undef;
}

sub round_trip {
    my (%a) = @_;
    my $t = "evch_t79_$a{tag}";
    my $o = $a{conn} || {};
    q_ok("drop table if exists $t");
    q_ok("create table $t (id UInt32, a $a{type}) engine = MergeTree order by id");
    my $id = qid();
    my $err = ins("$t (id, a)", $a{data}, { query_id => $id, %{ $a{settings} || {} } }, %$o);
    ok(!$err, "$a{tag}: insert") or diag $err;
    my $rows = q_ok("select id, a from $t order by id");
    is_deeply($rows, $a{want} // $a{data}, "$a{tag}: rows read back as inserted");
    q_ok("drop table $t");
    return $id;
}

sub rows { [ map { [ $_ + 1, $_[$_] ] } 0 .. $#_ ] }

for my $o ({}, { compress => 1 }, $has_zstd ? { compress => 1, compress_method => 'zstd' } : ()) {
    my $tag = !$o->{compress} ? 'plain' : $o->{compress_method} ? 'zstd' : 'lz4';
    my @cases = (
        [ str             => 'LowCardinality(String)',  '', 'a', 'bb', 'a', '', 'ccc', 'bb', 'a' ],
        [ nullable        => 'LowCardinality(Nullable(String))', undef, '', 'x', undef, 'x', '', 'y' ],
        [ array           => 'Array(LowCardinality(String))',
          [], ['a', 'b', 'a'], ['b'], [], ['', 'a'], ['c', 'c', 'c'] ],
        [ array_nullable  => 'Array(LowCardinality(Nullable(String)))',
          [undef, 'a', undef], [], ['a', '', undef] ],
        [ uint32          => 'LowCardinality(UInt32)',  7, 0, 7, 4294967295, 0, 7 ],
        [ nullable_uint16 => 'LowCardinality(Nullable(UInt16))', undef, 0, 5, undef, 5 ],
        [ fixed           => 'LowCardinality(FixedString(2))', 'ab', 'cd', 'ab', 'ab' ],
    );
    for (@cases) {
        my ($name, $type, @v) = @$_;
        round_trip(tag => "${name}_$tag", conn => $o, type => $type, data => rows(@v));
    }

    # TabSeparated text goes through the text encoder
    round_trip(
        tag  => "tsv_$tag", conn => $o, type => 'LowCardinality(Nullable(String))',
        data => "1\tq\n2\t\\N\n3\tq\n4\t\n5\tr\n",
        want => [ [1, 'q'], [2, undef], [3, 'q'], [4, ''], [5, 'r'] ],
    );
}

# many rows, few values: 1-byte keys whatever the row count
{
    my $n = 70_000;
    my @v = ('alpha', 'beta', '', 'gamma');
    my $id = round_trip(
        tag  => 'many_rows_few_values', conn => {}, type => 'LowCardinality(String)',
        data => [ map { [ $_, $v[$_ % 4] ] } 1 .. $n ],
    );
    my $ev = events($id);
    SKIP: {
        skip 'system.query_log unavailable', 1 unless $ev;
        # id 4 bytes + key 1 byte a row; a dictionary per row would add 9 more
        cmp_ok($ev->{NetworkReceiveBytes}, '<', $n * 6, "$n rows of 4 values: about 5 bytes a row")
            or diag "NetworkReceiveBytes $ev->{NetworkReceiveBytes}";
    }
}

# more keys than UInt16 holds: 4-byte keys; the values start all distinct,
# so lookups stop, and repeat after that
{
    my $n = 70_000;
    round_trip(
        tag  => 'uint32_keys', conn => { compress => 1 }, type => 'LowCardinality(String)',
        data => [ map { [ $_, 'k' . ($_ % 66_000) ] } 1 .. $n ],
    );
    is_deeply(q_ok('select 1'), [ [1] ], 'uint32_keys: the connection stays usable');

    round_trip(
        tag  => 'distinct_nullable', conn => {}, type => 'LowCardinality(Nullable(String))',
        data => [ map { [ $_, $_ % 5 ? 'n' . ($_ % 45_000) : undef ] } 1 .. 50_000 ],
    );
    round_trip(
        tag  => 'distinct_array', conn => { compress => 1 }, type => 'Array(LowCardinality(String))',
        data => [ map { [ $_, [ "e$_", "f$_", $_ > 15_000 ? 'e1' : () ] ] } 1 .. 20_000 ],
    );
}

# tens of thousands of distinct values, each repeated: still one key a value
{
    my $n = 100_000;
    my $id = round_trip(
        tag  => 'mid_cardinality', conn => {}, type => 'LowCardinality(String)',
        data => [ map { [ $_, 'm' . ($_ * 7919 % 20_000) ] } 1 .. $n ],
    );
    my $ev = events($id);
    SKIP: {
        skip 'system.query_log unavailable', 1 unless $ev;
        # id 4 bytes + key 2 bytes a row and 20000 short values once; a key
        # per row would add a 4-byte key and the value to every row
        cmp_ok($ev->{NetworkReceiveBytes}, '<', $n * 8, "$n rows of 20000 values: about 6 bytes a row")
            or diag "NetworkReceiveBytes $ev->{NetworkReceiveBytes}";
    }
}

# keys repeat across the encoder's 1024-row chunks and across Array rows
{
    my @data = map { [ $_, ['x' . ($_ % 3), 'y'], 'v' . ($_ % 5) ] } 1 .. 5000;
    my $t = 'evch_t79_chunks';
    q_ok("drop table if exists $t");
    q_ok("create table $t (id UInt32, a Array(LowCardinality(String)), b LowCardinality(String))"
        . " engine = MergeTree order by id");
    my $err = ins("$t (id, a, b)", \@data, {}, compress => 1);
    ok(!$err, 'chunks: insert') or diag $err;
    is_deeply(q_ok("select id, a, b from $t order by id"), \@data, 'chunks: rows read back');
    is_deeply(q_ok("select uniqExact(b), uniqExact(arrayJoin(a)) from $t"), [ [5, 4] ],
        'chunks: the server holds the distinct values');
    q_ok("drop table $t");
}

# bounded frames: the server decompresses frame by frame
{
    my $t = 'evch_t79_frames';
    my @data = map { [ $_, join('', map { chr(97 + ($_ * 7 + $_ ** 2) % 26) } 1 .. 64) . $_ ] } 1 .. 20_000;
    q_ok("drop table if exists $t");
    q_ok("create table $t (id UInt32, s String) engine = MergeTree order by id");
    for my $case ([65536, 'many'], [0, 'one']) {
        my ($size, $what) = @$case;
        my $id = qid();
        my $err = ins("$t (id, s)", \@data, { query_id => $id },
            compress => 1, compress_block_size => $size);
        ok(!$err, "frames $what: insert") or diag $err;
        my $ev = events($id);
        SKIP: {
            skip 'system.query_log unavailable', 1 unless $ev;
            # data frames, plus the empty block ending the query and the insert
            if ($size) {
                cmp_ok($ev->{CompressedReadBufferBlocks}, '>=', 20, "frames $what: $ev->{CompressedReadBufferBlocks} frames");
            } else {
                is($ev->{CompressedReadBufferBlocks}, 3, 'frames one: a frame for the whole block');
            }
        }
    }
    is_deeply(q_ok("select count(), sum(id), uniqExact(s) from $t"), [ [40_000, 2 * (20_000 * 20_001 / 2), 20_000] ],
        'frames: both inserts read back');
    q_ok("drop table $t");
}

# an encode failure sends nothing, frames or not
{
    my $t = 'evch_t79_reject';
    q_ok("drop table if exists $t");
    q_ok("create table $t (id UInt32, a LowCardinality(UInt8)) engine = MergeTree order by id");
    my $err = ins("$t (id, a)", [ map { [ $_, $_ == 3000 ? 'x' : $_ % 7 ] } 1 .. 5000 ], {},
        compress => 1, compress_block_size => 4096);
    like($err, qr/encoding failed.*row 2999/, 'bad value: the insert fails naming the row');
    is_deeply(q_ok("select count() from $t"), [ [0] ], 'bad value: no row landed');
    q_ok("drop table $t");
}

# ZSTD frames also carry queries with external tables
SKIP: {
    skip 'built without libzstd', 2 unless $has_zstd;
    my ($rows, $err) = wait_for(sub {
        conn(compress => 1, compress_method => 'zstd')->query(
            'select count(), sum(n) from ext',
            { external => { ext => { structure => [n => 'UInt32'], data => [ map { [$_] } 1 .. 1000 ] } } },
            $_[0]);
    });
    ok(!$err, 'zstd: external table query') or diag $err;
    is_deeply($rows, [ [1000, 500500] ], 'zstd: external table rows');
}

# option checks
{
    for my $bad ('brotli', undef) {
        eval { EV::ClickHouse->new(protocol => 'native', compress_method => $bad, host => $host, port => $port) };
        like($@, qr/unknown compress_method '\Q${\($bad \/\/ '')}\E'/,
             'compress_method ' . ($bad // 'undef') . ' croaks');
    }
    my %bad = (compress_block_size => [2**31, -1, 0.5, undef, 'junk', []],
               compress_level      => [23, -131073, 0.5, undef, 'junk', []]);
    for my $opt (sort keys %bad) {
        for my $bad (@{ $bad{$opt} }) {
            my $what = defined $bad ? "'$bad'" : 'undef';
            eval { EV::ClickHouse->new(protocol => 'native', $opt => $bad, host => $host, port => $port) };
            like($@, qr/$opt must be an integer/, "$opt $what croaks");
        }
    }
    unless ($has_zstd) {
        eval { EV::ClickHouse->new(protocol => 'native', compress_method => 'zstd', host => $host, port => $port) };
        like($@, qr/needs a build with libzstd/, 'zstd without libzstd croaks');
    }
}

$_->finish for grep { $_->is_connected } values %conn;
done_testing;
