#!perl -T

use strict;
use warnings;

use Test::More;
use IO::Stty;

# _cc_to_hat is a private sub, call it fully qualified
my @tests = (
    # [ input, expected, description ]
    [ undef, '<undef>', 'undef value' ],
    [ 0,     '<undef>', 'zero (disabled)' ],
    [ 255,   '<undef>', '255 (disabled)' ],
    [ 1,     '^A',      'SOH -> ^A' ],
    [ 3,     '^C',      'ETX -> ^C (intr)' ],
    [ 4,     '^D',      'EOT -> ^D (eof)' ],
    [ 8,     '^H',      'BS  -> ^H (erase)' ],
    [ 21,    '^U',      'NAK -> ^U (kill)' ],
    [ 26,    '^Z',      'SUB -> ^Z (susp)' ],
    [ 31,    '^_',      'US  -> ^_' ],
    [ 127,   '^?',      'DEL -> ^?' ],
    [ 65,    'A',       'printable A passes through' ],
    [ 97,    'a',       'printable a passes through' ],
);

plan tests => scalar @tests;

for my $t (@tests) {
    my ( $input, $expected, $desc ) = @$t;
    is( IO::Stty::_cc_to_hat($input), $expected, "_cc_to_hat: $desc" );
}
