#!perl

use strict;
use warnings;
use Test::More;

use POSIX ();
use IO::Stty;

# _POSIX_VDISABLE: the platform-specific value used to disable a cc slot
my $VDISABLE = eval { POSIX::_POSIX_VDISABLE() };
$VDISABLE = 0 unless defined $VDISABLE;

# _parse_char_value is a private sub, call it fully qualified
my @tests = (
    # [ input, expected, description ]

    # Plain decimal integers
    [ '0',   0,   'decimal zero' ],
    [ '3',   3,   'decimal 3' ],
    [ '127', 127, 'decimal 127' ],
    [ '21',  21,  'decimal 21' ],

    # Hat notation
    [ '^C',  3,    'hat notation ^C (Ctrl-C)' ],
    [ '^c',  3,    'hat notation ^c (lowercase)' ],
    [ '^D',  4,    'hat notation ^D (Ctrl-D / EOF)' ],
    [ '^?',  0x7F, 'hat notation ^? (DEL)' ],
    [ '^A',  1,    'hat notation ^A' ],
    [ '^Z',  26,   'hat notation ^Z (Ctrl-Z / SUSP)' ],
    [ '^@',  0,    'hat notation ^@ (NUL)' ],
    [ '^[',  27,   'hat notation ^[ (ESC)' ],

    # Hexadecimal
    [ '0x03',  3,    'hex 0x03' ],
    [ '0x7f',  127,  'hex 0x7f (lowercase)' ],
    [ '0x7F',  127,  'hex 0x7F (uppercase)' ],
    [ '0x1B',  27,   'hex 0x1B' ],
    [ '0x00',  0,    'hex 0x00' ],
    [ '0xff',  255,  'hex 0xff' ],

    # Octal
    [ '03',   3,    'octal 03' ],
    [ '010',  8,    'octal 010' ],
    [ '017',  15,   'octal 017' ],
    [ '0177', 127,  'octal 0177' ],

    # undef / ^- (returns _POSIX_VDISABLE, which is 0 on Linux, 255 on macOS)
    [ 'undef', $VDISABLE, 'undef disables character (returns _POSIX_VDISABLE)' ],
    [ '^-',    $VDISABLE, '^- disables character (returns _POSIX_VDISABLE)' ],
);

plan tests => scalar @tests;

for my $test (@tests) {
    my ( $input, $expected, $desc ) = @$test;
    my $got = IO::Stty::_parse_char_value($input);
    is( $got, $expected, $desc );
}
