use strict;
use warnings;
use Test::More;
use EV::Kafka;

# Regression tests for:
#   L7  LZ4 record batches use the LZ4 FRAME format (KIP-57) in both
#       directions — the magic bytes 04 22 4D 18 must be present in the
#       compressed payload
#   L8  decompression failure / unknown codec returns undef instead of
#       parsing the compressed bytes as records

# Capability probe, mirroring Makefile.PL's detection (HAVE_LZ4 now
# implies the frame API).
my $have_lz4 = system('pkg-config --exists liblz4 2>/dev/null') == 0
    || -f '/usr/include/lz4frame.h';

plan skip_all => 'LZ4 frame support not built (liblz4 with lz4frame.h)'
    unless $have_lz4;
plan tests => 5;

# Batch v2 layout: baseOffset(8) batchLength(4) leaderEpoch(4) magic(1)
# crc(4) attributes(2) ... recordCount(4) payload — attributes low byte at
# offset 22, CRC covers offset 21..end, compressed payload at offset 61.
sub set_compression_bits {
    my ($batch, $type) = @_;
    substr($batch, 22, 1) = chr((ord(substr($batch, 22, 1)) & ~0x07) | $type);
    substr($batch, 17, 4) = pack 'N', EV::Kafka::_crc32c(substr($batch, 21));
    return $batch;
}

my $records = [{ key => 'hello', value => 'world' }];

# --- L7: encoder emits the frame magic -------------------------------------
{
    my $batch = EV::Kafka::_test_encode_batch($records,
        { compression => 3, timestamp => 1000 });
    is unpack('H8', substr($batch, 61, 4)), '04224d18',
        'L7: LZ4-compressed batch starts with the frame magic 04 22 4D 18';
}

# --- L7: frame roundtrip through the real decode path ----------------------
{
    my $batch = EV::Kafka::_test_encode_batch($records,
        { compression => 3, timestamp => 1000 });
    my $decoded = EV::Kafka::_test_decode_batch($batch);
    is_deeply $decoded, [{ offset => 0, timestamp => 1000,
                           key => 'hello', value => 'world' }],
        'L7: frame format roundtrips through kf_decode_record_batch';
}

# --- L7: a reference frame (golden bytes) decodes --------------------------
# Produced once by the frame encoder; pinned here so the test does not
# depend on the build's own encoder agreeing with itself.
{
    my $golden = pack 'H*',
        '000000000000000000000051000000000255d2dad3000300000000000000'
        . '00000003e800000000000003e8ffffffffffffffffffffffffffff0000'
        . '000104224d184040c011000080200000000a68656c6c6f0a776f726c64'
        . '0000000000';
    my $decoded = EV::Kafka::_test_decode_batch($golden);
    is_deeply $decoded, [{ offset => 0, timestamp => 1000,
                           key => 'hello', value => 'world' }],
        'L7: reference LZ4 frame decodes to the original record';
}

# --- L8: failed decompression must not parse payload as records ------------
{
    # Valid uncompressed batch, but attributes claim LZ4: the plaintext
    # payload is not a frame, decompression fails — must return undef
    # (pre-fix it fell through and delivered the plaintext as records).
    my $batch = EV::Kafka::_test_encode_batch($records,
        { compression => 0, timestamp => 1000 });
    $batch = set_compression_bits($batch, 3);
    ok !defined(EV::Kafka::_test_decode_batch($batch)),
        'L8: failed LZ4 decompression returns undef, not garbage records';
}

# --- L8: unknown compression type ------------------------------------------
{
    my $batch = EV::Kafka::_test_encode_batch($records,
        { compression => 0, timestamp => 1000 });
    $batch = set_compression_bits($batch, 5);
    ok !defined(EV::Kafka::_test_decode_batch($batch)),
        'L8: unknown compression type returns undef, not garbage records';
}
