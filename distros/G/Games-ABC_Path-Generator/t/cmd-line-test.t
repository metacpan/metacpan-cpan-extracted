#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Test::Differences;

use File::Spec;

my $prog_path = File::Spec->catfile(
    File::Spec->curdir(), 'scripts', 'abc-path-gen'
);

{
    # TEST
    eq_or_diff(
        scalar(`$^X -Mblib $prog_path --seed=1 --mode=final`),
        <<'EOF',
Y | X | R | S | T
E | D | W | Q | U
F | B | C | V | P
G | A | K | L | O
H | I | J | N | M
EOF
        'For seed #1',
    );
}

{
    # TEST
    eq_or_diff(
        scalar(`$^X -Mblib $prog_path --seed=1 --mode=riddle`),
        <<'EOF',
ABC Path Solver Layout Version 1:
YGBJNUT
S     R
D     W
F     V
O A   K
M     I
HEXCQPL
EOF
        'Riddle mode for seed #1',
    );
}

{
    # TEST
    eq_or_diff(
        scalar(`$^X -Mblib $prog_path --seed=1`),
        <<'EOF',
ABC Path Solver Layout Version 1:
YGBJNUT
S     R
D     W
F     V
O A   K
M     I
HEXCQPL
EOF
        'Default is riddle mode (for seed #1)',
    );
}

{
    my $got_output = `$^X -Mblib $prog_path --help`;

    # TEST
    like ($got_output,
        qr/--help/,
        "Help output is relatively sane.",
    );
}
