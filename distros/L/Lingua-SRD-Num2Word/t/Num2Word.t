#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SRD::Num2Word');
    $tests++;
}

use Lingua::SRD::Num2Word qw(num2srd_cardinal);

# --- Basic digits 0-9 ---
my @digits = (
    [ 0, 'zeru'    ],
    [ 1, 'unu'     ],
    [ 2, 'duos'    ],
    [ 3, 'tres'    ],
    [ 4, 'bàtoro'  ],
    [ 5, 'chimbe'  ],
    [ 6, 'ses'     ],
    [ 7, 'sete'    ],
    [ 8, 'oto'     ],
    [ 9, 'noe'     ],
);

for my $pair (@digits) {
    is(num2srd_cardinal($pair->[0]), $pair->[1], "$pair->[0] => $pair->[1]");
    $tests++;
}

# --- Teens 10-19 ---
my @teens = (
    [ 10, 'deghe'      ],
    [ 11, 'undighi'    ],
    [ 12, 'doighi'     ],
    [ 13, 'treighi'    ],
    [ 14, 'batordighi' ],
    [ 15, 'bindighi'   ],
    [ 16, 'seighi'     ],
    [ 17, 'deghesete'  ],
    [ 18, 'degheoto'   ],
    [ 19, 'deghenoe'   ],
);

for my $pair (@teens) {
    is(num2srd_cardinal($pair->[0]), $pair->[1], "$pair->[0] => $pair->[1]");
    $tests++;
}

# --- Tens ---
my @tens = (
    [ 20, 'binti'     ],
    [ 30, 'trinta'    ],
    [ 40, 'baranta'   ],
    [ 50, 'chinbanta' ],
    [ 60, 'sessanta'  ],
    [ 70, 'setanta'   ],
    [ 80, 'otanta'    ],
    [ 90, 'nonanta'   ],
);

for my $pair (@tens) {
    is(num2srd_cardinal($pair->[0]), $pair->[1], "$pair->[0] => $pair->[1]");
    $tests++;
}

# --- Compound numbers with apocope ---
my @compounds = (
    [ 21, 'bintunu'       ],
    [ 22, 'bintiduos'     ],
    [ 23, 'bintitres'     ],
    [ 24, 'bintibàtoro'   ],
    [ 25, 'bintichimbe'   ],
    [ 31, 'trintunu'      ],
    [ 33, 'trintatres'    ],
    [ 41, 'barantunu'     ],
    [ 42, 'barantaduos'   ],
    [ 51, 'chinbantunu'   ],
    [ 61, 'sessantunu'    ],
    [ 71, 'setantunu'     ],
    [ 81, 'otantunu'      ],
    [ 91, 'nonantunu'     ],
    [ 99, 'nonantanoe'    ],
);

for my $pair (@compounds) {
    is(num2srd_cardinal($pair->[0]), $pair->[1], "$pair->[0] => $pair->[1]");
    $tests++;
}

# --- Hundreds ---
my @hundreds = (
    [ 100, 'chentu'        ],
    [ 200, 'duchentos'     ],
    [ 300, 'trechentos'    ],
    [ 400, 'batorchentos'  ],
    [ 500, 'chinbichentos' ],
    [ 600, 'seschentos'    ],
    [ 700, 'setechentos'   ],
    [ 800, 'otochentos'    ],
    [ 900, 'nobichentos'   ],
);

for my $pair (@hundreds) {
    is(num2srd_cardinal($pair->[0]), $pair->[1], "$pair->[0] => $pair->[1]");
    $tests++;
}

# --- Compound hundreds ---
is(num2srd_cardinal(101), 'chentuunu',           '101 => chentuunu');           $tests++;
is(num2srd_cardinal(123), 'chentubintitres',      '123 => chentubintitres');     $tests++;
is(num2srd_cardinal(315), 'trechentosbindighi',   '315 => trechentosbindighi');  $tests++;
is(num2srd_cardinal(999), 'nobichentosnonantanoe','999 => nobichentosnonantanoe'); $tests++;

# --- Thousands ---
is(num2srd_cardinal(1000), 'milli',               '1000 => milli');     $tests++;
is(num2srd_cardinal(2000), 'duamiza',             '2000 => duamiza');   $tests++;
is(num2srd_cardinal(1001), 'milliunu',            '1001 => milliunu');  $tests++;
is(num2srd_cardinal(5000), 'chimbemiza',          '5000 => chimbemiza'); $tests++;

# --- Capabilities ---
my $cap = Lingua::SRD::Num2Word::capabilities();
is($cap->{cardinal}, 1, 'cardinal supported');     $tests++;
is($cap->{ordinal},  0, 'ordinal not supported');  $tests++;

done_testing($tests);
