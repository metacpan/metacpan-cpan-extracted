use strict;
use warnings;
use Test::More;
use EV::Kafka;

plan tests => 24;

# ZigZag encoding (Kafka uses this for record-level varints).
is EV::Kafka::_test_zigzag_i32(0),   0,  'zigzag i32(0)  = 0';
is EV::Kafka::_test_zigzag_i32(-1),  1,  'zigzag i32(-1) = 1';
is EV::Kafka::_test_zigzag_i32(1),   2,  'zigzag i32(1)  = 2';
is EV::Kafka::_test_zigzag_i32(-2),  3,  'zigzag i32(-2) = 3';
is EV::Kafka::_test_zigzag_i32(2),   4,  'zigzag i32(2)  = 4';

is EV::Kafka::_test_zigzag_i64(0),   0,  'zigzag i64(0)  = 0';
is EV::Kafka::_test_zigzag_i64(-1),  1,  'zigzag i64(-1) = 1';
is EV::Kafka::_test_zigzag_i64(1),   2,  'zigzag i64(1)  = 2';
is EV::Kafka::_test_zigzag_i64(-2),  3,  'zigzag i64(-2) = 3';
is EV::Kafka::_test_zigzag_i64(2147483648),  4294967296,
    'zigzag i64 handles values beyond i32 range';

# Varint round-trip across boundaries.
for my $v (0, 1, -1, 63, 64, -64, -65,
           127, 128, -128,
           16383, 16384,
           2_000_000_000, -2_000_000_000)
{
    is EV::Kafka::_test_varint_roundtrip($v), $v,
        "varint round-trips $v";
}
