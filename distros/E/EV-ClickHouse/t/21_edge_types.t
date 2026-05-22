use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# Edge cases across native types: empty result, null columns, FixedString,
# 1 MB String, deeply-nested Array(Tuple), IPv6, Decimal128, Map.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

plan tests => 16;

my $ch;

sub with_native {
    my ($cb) = @_;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        protocol   => 'native',
        on_connect => sub { $cb->() },
        on_error   => sub { diag("error: $_[0]"); EV::break },
    );
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    $ch->finish if $ch && $ch->is_connected;
}

# 1-2: Empty result. Native returns an empty arrayref or undef when no
# rows match — accept either as long as no error was raised.
with_native(sub {
    $ch->query("select number from numbers(5) where number > 1000", sub {
        my ($rows, $err) = @_;
        ok(!$err, "empty: no error") or diag $err;
        my $rowcount = ref $rows eq 'ARRAY' ? scalar @$rows : 0;
        is($rowcount, 0, "empty: zero rows (got " . (defined $rows ? "ref" : "undef") . ")");
        EV::break;
    });
});

# Helper: fetch the first row of a single-column or multi-column result,
# tolerating $err so the per-test plan stays accurate.
sub first_row {
    my ($rows, $err) = @_;
    return $err ? undef
         : (ref $rows eq 'ARRAY' && @$rows ? $rows->[0] : undef);
}

# 3-4: All-null row
with_native(sub {
    $ch->query("select CAST(null as Nullable(UInt32)), CAST(null as Nullable(String))", sub {
        my ($rows, $err) = @_;
        ok(!$err, "all-null: no error") or diag $err;
        is_deeply($rows, [[undef, undef]], "all-null: both columns undef");
        EV::break;
    });
});

# 5-6: FixedString(N) — server pads with NULs to exactly N bytes
with_native(sub {
    $ch->query("select toFixedString('abc', 5)", sub {
        my ($rows, $err) = @_;
        ok(!$err, "FixedString: no error") or diag $err;
        my $r = first_row($rows, $err);
        is($r ? $r->[0] : undef, "abc\0\0", "FixedString: NUL-padded to 5");
        EV::break;
    });
});

# 7-8: Large String (~1 MB). ClickHouse caps repeat() at max_repeat_times
# (1_000_000 by default), so stay just under the cap.
with_native(sub {
    my $N = 999_999;
    $ch->query("select repeat('x', $N)", sub {
        my ($rows, $err) = @_;
        ok(!$err, "large string: no error") or diag $err;
        my $r = first_row($rows, $err);
        is(length($r ? $r->[0] : ''), $err ? 0 : $N,
            "large string: full length round-trips ($N bytes)");
        EV::break;
    });
});

# 9-10: Deeply nested Array(Tuple)
with_native(sub {
    $ch->query("select [tuple(1, 'a'), tuple(2, 'b')]", sub {
        my ($rows, $err) = @_;
        ok(!$err, "Array(Tuple): no error") or diag $err;
        my $r = first_row($rows, $err);
        is_deeply($r ? $r->[0] : undef, [[1, 'a'], [2, 'b']],
            "Array(Tuple): structure preserved");
        EV::break;
    });
});

# 11-12: IPv6 column
with_native(sub {
    $ch->query("select toIPv6('::1'), toIPv6('2001:db8::1')", sub {
        my ($rows, $err) = @_;
        ok(!$err, "IPv6: no error") or diag $err;
        is_deeply(first_row($rows, $err), ['::1', '2001:db8::1'],
            "IPv6: canonical form");
        EV::break;
    });
});

# 13-14: Decimal128 (raw, without decode_decimal — comes back as a string).
with_native(sub {
    $ch->query("select toDecimal128('123.456', 3)", sub {
        my ($rows, $err) = @_;
        ok(!$err, "Decimal128: no error") or diag $err;
        my $r = first_row($rows, $err);
        ok(defined($r ? $r->[0] : undef), "Decimal128: value defined");
        EV::break;
    });
});

# 15-16: Map(String, UInt32)
with_native(sub {
    $ch->query("select map('a', 1, 'b', 2)", sub {
        my ($rows, $err) = @_;
        ok(!$err, "Map: no error") or diag $err;
        my $r = first_row($rows, $err);
        is_deeply($r ? $r->[0] : undef, { a => 1, b => 2 },
            "Map: hashref decoded");
        EV::break;
    });
});
