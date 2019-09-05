use lib '../lib', 'blib', 'lib';
use Test::More;
use strict;
use warnings;
use Math::Int64 qw[uint64 hex_to_uint64];
no warnings 'portable';    # Support for 64-bit ints required
use Digest::xxHash qw[xxhash32 xxhash32_hex
    xxhash64 xxhash64_hex];

# 32bit
is xxhash32('this is a test', 0xCAFEBABE), 2811818255, 'Demo';
my $b1 = join '', map {chr} 0xB8, 0x1E, 0x85, 0xEB, 0x51, 0xB8, 0x9E, 0x3F,
    0xB8, 0x1E, 0x85, 0xEB, 0x51, 0xB8, 0x9E, 0x3F, 0xB8, 0x1E, 0x85, 0xEB,
    0x51, 0xB8, 0x9E, 0x3F, 0xB8, 0x1E, 0x85, 0xEB, 0x51, 0xB8, 0x9E, 0x3F,
    0xB8, 0x1E, 0x85, 0xEB, 0x51, 0xB8, 0x9E, 0x3F, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x50, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x20, 0x13, 0x08, 0x12, 0x65, 0xE3, 0x6A, 0xC0;
my $b2 = join '', map {chr} 0xD7, 0xA3, 0x70, 0x3D, 0x0A, 0x57, 0x21, 0x40,
    0x9A, 0x99, 0x99, 0x99, 0x99, 0x99, 0x21, 0x40, 0xA4, 0x70, 0x3D, 0x0A,
    0xD7, 0x23, 0x21, 0x40, 0x14, 0xAE, 0x47, 0xE1, 0x7A, 0x94, 0x21, 0x40,
    0x14, 0xAE, 0x47, 0xE1, 0x7A, 0x94, 0x21, 0x40, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xD8, 0x3C, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x20, 0x13, 0x08, 0x13, 0xA9, 0xF1, 0xE2, 0x2A;
is xxhash32($b1, 0x5262), xxhash32($b2, 0x5262), 'Known 32 bit collision';
is xxhash32('test', 123),   2758658570, 'basic';
is xxhash32('test', 12345), 3834992036, 'basic w/ different seed';
is xxhash32_hex('test', 12345), 'e49555a4', 'xxhash32_hex';

# 64bit
is uint64(xxhash64('test64', 1123)), uint64('18300740539230391133');
is uint64(xxhash64('test64', 5813)), uint64('470519085964830776');
is xxhash64_hex('test64', 5813), '06879e9da2f9a838', 'xxhash64_hex';
my $SANITY_BUFFER_SIZE = 101;
my $prime              = 2654435761;
my $sanityBuffer       = pack 'H*',
    '9eff1f4b5e532fddb5544d2a952b57ae5dba74e9d3a64c983060c080';

sub BMK_testSequence {
    my ($sentence, $len, $seed, $result) = @_;
    is xxhash32(pack('a' . $len, $sentence), $seed), $result,
        'line ' . (caller())[2];
}

sub BMK_testSequence64 {
    my ($sentence, $len, $seed, $result) = @_;
    is uint64(xxhash64(pack('a' . $len, $sentence), $seed)),
        hex_to_uint64($result), 'line ' . (caller())[2];
}
BMK_testSequence('',            0,                   0,      0x02CC5D05);
BMK_testSequence('',            0,                   $prime, 0x36B78AE7);
BMK_testSequence($sanityBuffer, 1,                   0,      0xB85CBEE5);
BMK_testSequence($sanityBuffer, 1,                   $prime, 0xD5845D64);
BMK_testSequence($sanityBuffer, 14,                  0,      0xE5AA0AB4);
BMK_testSequence($sanityBuffer, 14,                  $prime, 0x4481951D);
BMK_testSequence($sanityBuffer, $SANITY_BUFFER_SIZE, 0,      0x1F1AA412);
BMK_testSequence($sanityBuffer, $SANITY_BUFFER_SIZE, $prime, 0x498EC8E2);
BMK_testSequence64('',            0,  0,      'EF46DB3751D8E999');
BMK_testSequence64('',            0,  $prime, 'AC75FDA2929B17EF');
BMK_testSequence64($sanityBuffer, 1,  0,      '4FCE394CC88952D8');
BMK_testSequence64($sanityBuffer, 1,  $prime, '739840CB819FA723');
BMK_testSequence64($sanityBuffer, 14, 0,      'CFFA8DB881BC3A3D');
BMK_testSequence64($sanityBuffer, 14, $prime, '5B9611585EFCC9CB');
BMK_testSequence64($sanityBuffer, $SANITY_BUFFER_SIZE, 0, '0EAB543384F878AD');
BMK_testSequence64($sanityBuffer, $SANITY_BUFFER_SIZE,
                   $prime,        'CAA65939306F1E21');

# Issue 4
is xxhash64_hex("b" x 100000, 890272), 'df8fee94dbf20a9d',
    'uint64 fix to match xxHash.xs';
is xxhash64_hex("b" x 100000, 89), '01aae2582443bbf0', 'expect leading zeros';

# TODO: 128, 256
done_testing;
