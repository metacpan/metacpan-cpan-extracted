#!perl -T

use strict;
use warnings;

use POSIX ();
use Test::More;
use IO::Stty;

# Determine platform's VDISABLE value (0 on Linux, 255 on macOS/BSD)
my $VDISABLE = eval { POSIX::_POSIX_VDISABLE() };
$VDISABLE = 0 unless defined $VDISABLE;

# _cc_to_hat is a private sub, call it fully qualified
my @tests = (
    # [ input, expected, description ]
    [ undef,      '<undef>', 'undef value' ],
    [ $VDISABLE,  '<undef>', 'VDISABLE value (disabled)' ],
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

# On Linux (VDISABLE=0), 255 is a valid character, not <undef>.
# On macOS/BSD (VDISABLE=255), 0 is ^@ (NUL), not <undef>.
if ($VDISABLE == 0) {
    push @tests, [ 255, chr(255), '255 is valid char when VDISABLE=0' ];
}
else {
    push @tests, [ 0, '^@', '0 (NUL/^@) is valid char when VDISABLE!=0' ];
}

plan tests => scalar @tests;

for my $t (@tests) {
    my ( $input, $expected, $desc ) = @$t;
    is( IO::Stty::_cc_to_hat($input), $expected, "_cc_to_hat: $desc" );
}
