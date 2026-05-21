use strict;
use warnings;
use Test::More;
use EV::Kafka;

plan tests => 4;

# Encode a valid batch.
my $bytes = EV::Kafka::_test_encode_batch(
    [{ key => 'k', value => 'untampered' }]
);
my $ok = EV::Kafka::_test_decode_batch($bytes);
is scalar @$ok, 1, 'untampered batch decodes';

# Flip a byte inside the records area (offset 50ish — past the CRC field).
{
    my $bad = $bytes;
    substr($bad, length($bad) - 3, 1) = "\xff";
    my $r = EV::Kafka::_test_decode_batch($bad);
    ok !defined $r, 'bit-flipped batch fails CRC verification';
}

# Truncated batch.
{
    my $short = substr($bytes, 0, length($bytes) - 5);
    my $r = EV::Kafka::_test_decode_batch($short);
    ok !defined $r, 'truncated batch is rejected';
}

# Wrong magic byte.
{
    my $bad = $bytes;
    # base_offset(8) + batch_length(4) + leader_epoch(4) = 16; magic at offset 16
    substr($bad, 16, 1) = "\x01";
    my $r = EV::Kafka::_test_decode_batch($bad);
    ok !defined $r, 'wrong magic byte is rejected';
}
