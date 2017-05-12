use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 2 }

use Hex::Record;

my $intel_hex_string;

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
            start => 0xFFFFFF00,
            bytes => [
                qw(00 11 22 33 44 55 66 77 88 99 00),
            ],
        },
    ],
);

my $intel_hex_string_expected = <<'END_HEX';
: 0A | 0000 | 00 | 00 11 22 33 44 55 66 77 88 99 | F9
: 01 | 000B | 00 | BB                            | 39
: 01 | 000D | 00 | DD                            | 15
: 0A | FFF0 | 00 | 00 01 02 03 04 05 06 07 08 09 | DA
: 0A | FFFA | 00 | 10 11 12 13 14 15 16 17 18 19 | 30
: 02 | 0000 | 04 | 00 01                         | F9
: 0A | 0004 | 00 | 20 21 22 23 24 25 26 27 28 29 | 85
: 0A | 000E | 00 | 30 31 32 33 34 35 36 37 38 39 | DB
: 0A | 0018 | 00 | 40 41 42 43 44 45 46 47 48 49 | 31
: 02 | 0000 | 04 | 00 FF                         | FB
: 0A | 0000 | 00 | 00 11 22 33 44 55 66 77 88 99 | F9
: 02 | 0000 | 04 | FF FF                         | FC
: 0A | FF00 | 00 | 00 11 22 33 44 55 66 77 88 99 | FA
: 01 | FF0A | 00 | 00                            | F6
: 00 | 0000 | 01 |                               | FF
END_HEX

$intel_hex_string_expected =~ s{[^\S\n]}{}xmsg;
$intel_hex_string_expected =~ s{\|}{}xmsg;


$intel_hex_string = $hex->as_intel_hex(10);

is(  $intel_hex_string, $intel_hex_string_expected, 'dumped correctly as intel hex' );

# force checksum to '100' => '1' should be ignored

$hex = Hex::Record->new(
    parts => [
        {
            start => 0x20C0,
            bytes => [
                qw(40 00 40 00 40 00 40 00 40 00
                   40 00 40 00 40 00 40 00 40 00
                   40 00 40 00 40 00 40 00 40 00
                   40 00),
            ],
        },
    ]
);


$intel_hex_string_expected = <<'END_HEX';
: 20 | 20C0 | 00 | 4000400040004000400040004000400040004000400040004000400040004000 | 00
: 00 | 0000 | 01 |                                                                  | FF
END_HEX

$intel_hex_string_expected =~ s{[^\S\n]}{}xmsg;
$intel_hex_string_expected =~ s{\|}{}xmsg;

$intel_hex_string = $hex->as_intel_hex(32);

is( $intel_hex_string,
    $intel_hex_string_expected,
    'dumped correctly as intel hex'
);

