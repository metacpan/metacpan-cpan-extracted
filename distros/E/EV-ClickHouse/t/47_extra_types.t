use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# Decoder coverage for types that have implementations in xs/types.c but
# no dedicated regression test: BFloat16, Decimal256, Interval*, and the
# Geo types (Point / Polygon). A decoder regression in any of these would
# otherwise slip past `make test`.
#
# Each type is probed independently so an older server that lacks one
# (e.g. Geo) still exercises the others rather than skipping the lot.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

plan tests => 8;

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

# Run $sql; if the server rejects it (unsupported type/function on an
# older build) skip $n tests, otherwise hand ($rows) to $check.
sub typed_case {
    my ($label, $sql, $n, $check) = @_;
    SKIP: {
        my ($rows, $err);
        with_native(sub {
            $ch->query($sql, sub { ($rows, $err) = @_; EV::break });
        });
        skip "$label unsupported on this server", $n if $err;
        $check->($rows);
    }
}

# BFloat16: top 16 bits of a Float32. 2.5 is exact in bf16.
typed_case("BFloat16", "select toBFloat16(2.5) as bf", 1, sub {
    my ($rows) = @_;
    cmp_ok(abs(($rows->[0][0] // 0) - 2.5), '<', 0.01,
           "bfloat16: 2.5 decodes near 2.5 (got " . ($rows->[0][0] // 'undef') . ")");
});

# Decimal256: no native int256, so the decoder delivers the raw 32-byte
# LE value (documented contract - hand to Math::BigInt for arithmetic).
typed_case("Decimal256", "select toDecimal256('123456789.123456789', 9) as d", 1, sub {
    my ($rows) = @_;
    is(length($rows->[0][0] // ''), 32,
       "decimal256: decoder delivers the raw 32-byte value");
});

# Interval: decoded as an integer count of units.
typed_case("Interval", "select toIntervalDay(7) as iv", 2, sub {
    my ($rows) = @_;
    ok(defined $rows->[0][0],            "interval: value decoded");
    is($rows->[0][0], 7,                 "interval: toIntervalDay(7) decodes to 7");
});

# Geo Point: Tuple(Float64, Float64). Uses the ::Point cast (older
# servers lack the toPoint() function but accept the cast).
typed_case("Geo Point", "select (10, 20)::Point as pt", 2, sub {
    my ($rows) = @_;
    ok(ref $rows->[0][0] eq 'ARRAY',     "geo point: decodes as a tuple/arrayref");
    is_deeply($rows->[0][0], [10, 20],   "geo point: [x, y] values");
});

# Geo Polygon: Array(Array(Tuple(Float64,Float64))) - one outer ring.
typed_case("Geo Polygon",
    "select [[(0,0),(0,1),(1,1),(1,0),(0,0)]]::Polygon as poly", 2, sub {
    my ($rows) = @_;
    ok(ref $rows->[0][0] eq 'ARRAY',     "geo polygon: decodes as nested arrayrefs");
    is_deeply($rows->[0][0], [[[0,0],[0,1],[1,1],[1,0],[0,0]]],
              "geo polygon: nested rings of points");
});
