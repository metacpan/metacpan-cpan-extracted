use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 1 }

use Hex::Record;

{ # correct
    my $hex = Hex::Record->new(
        parts => [
            {
                start => 0x0,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99),
                ],
            },
            {
                start => 0xB,
                bytes => [
                    qw(BB),
                ],
            },
            {
                start => 0xD,
                bytes => [
                    qw(DD),
                ],
            },
            {
                start => 0x0000FFF0,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            },
            {
                start => 0xFF0000,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99),
                ],
            },
            {
                start => 0x0FFFFF00,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99),
                ],
            },
            {
                start => 0xFFFFFF00,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99 00),
                ],
            },
        ],
    );

    # dump as srec hex
    my $srec_hex_string_expected = <<'END_HEX';

S1 | 0C | 0000     | 00 11 22 33 44 55 66 77 88 99 | F6
S1 | 03 | 000B     | BB                            | 36
S1 | 03 | 000D     | DD                            | 12
S1 | 0C | FFF0     | 00 01 02 03 04 05 06 07 08 09 | D7
S1 | 0C | FFFA     | 10 11 12 13 14 15 16 17 18 19 | 2D
S2 | 0D | 010004   | 20 21 22 23 24 25 26 27 28 29 | 80
S2 | 0D | 01000E   | 30 31 32 33 34 35 36 37 38 39 | D6
S2 | 0D | 010018   | 40 41 42 43 44 45 46 47 48 49 | 2C
S2 | 0D | FF0000   | 00 11 22 33 44 55 66 77 88 99 | F6
S3 | 0E | 0FFFFF00 | 00 11 22 33 44 55 66 77 88 99 | E7
S3 | 0E | FFFFFF00 | 00 11 22 33 44 55 66 77 88 99 | F7
S3 | 05 | FFFFFF0A | 00                            | F3
END_HEX

    $srec_hex_string_expected =~ s{[^\S\n]}{}xmsg;
    $srec_hex_string_expected =~ s{\|}{}xmsg;

    $srec_hex_string_expected =~ s{[\s\|]+}{};

    my $srec_hex_string = $hex->as_srec_hex(10);
    is( $srec_hex_string, $srec_hex_string_expected, 'dumped correctly as srec hex' );
}
