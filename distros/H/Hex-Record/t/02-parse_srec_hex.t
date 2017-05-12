use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 6 }

use Hex::Record;

my @tests = (
    {
        case      => 'simple srec hex (in order)',
        srec_hex =>
            "# some initial comment\n"
          . "S10C000000010203040506070809C6\n"
          . "S10C000A101112131415161718191C\n"
          . "S10C00142021222324252627282972\n",
        parts_exp => [
            {
                start => 0x0,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29),
                ],
            },
        ],
    },
    {
        case      => 'simple srec hex (not in order)',
        srec_hex =>
            "s invalid line\n"
          . "S10C00142021222324252627282972\n"
          . "S10C000A101112131415161718191C\n"
          . "S10C000000010203040506070809C6\n",
        parts_exp => [
            {
                start => 0x0,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29),
                ],
            },
        ],
    },
    {
        case      => 'colliding parts',
        srec_hex =>
            "s1invalid line\n"
          . "S10C000000010203040506070809C6\n"
          . "S10C0009101112131415161718191D\n"
          . "S10C00142021222324252627282972\n",
        parts_exp => [
            {
                start => 0x0,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 10
                       11 12 13 14 15 16 17 18 19),
                ],
            },
            {
                start => 0x14,
                bytes => [
                    qw(20 21 22 23 24 25 26 27 28 29),
                ],
            },
        ],
    },
    {
        case      => 'multiple colliding parts',
        srec_hex =>
            "S00C000000010203040506070809C6\n"
          . "S10C000000010203040506070809C6\n"
          . "S10C00031011121314151617181923\n"
          . "S10C00052021222324252627282981\n",
        parts_exp => [
            {
                start => 0x0,
                bytes => [
                    qw(00 01 02 10 11 20 21 22 23 24
                       25 26 27 28 29),
                ],
            },
        ],
    },
    {
        case      => '24 bit addresses',
        srec_hex =>
            "S20C010000FFFFFFFFFFFFFFFFFF33C8\n"
          . "S20CFF000100112233445566778899F6\n"
          . "S20C10000A99887766554433221100DC\n",
        parts_exp => [
            {
                start => 0x10000,
                bytes => [
                    qw(FF FF FF FF FF FF FF FF FF 33),
                ],
            },
            {
                start => 0x10000A,
                bytes => [
                    qw(99 88 77 66 55 44 33 22 11 00),
                ],
            },
            {
                start => 0xFF0001,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99),
                ],
            },
        ],
    },
    {
        case      => '32 bit addresses',
        srec_hex =>
            "S30C01000001FFFFFFFFFFFFFFFFFF33C7\n"
          . "S30CFF00010100112233445566778899F5\n"
          . "S30C10000A0F99887766554433221100CD\n",
        parts_exp => [
            {
                start => 0x01000001,
                bytes => [
                    qw(FF FF FF FF FF FF FF FF FF 33),
                ],
            },
            {
                start => 0x10000A0F,
                bytes => [
                    qw(99 88 77 66 55 44 33 22 11 00),
                ],
            },
            {
                start => 0xFF000101,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99),
                ],
            },
        ],
    },
);

for my $test (@tests) {
    my $hex_record = Hex::Record->new;
    $hex_record->import_srec_hex($test->{srec_hex});
    is_deeply($hex_record->{parts}, $test->{parts_exp}, $test->{case});
}
