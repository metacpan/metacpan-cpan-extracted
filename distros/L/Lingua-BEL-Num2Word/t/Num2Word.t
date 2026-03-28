#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::BEL::Num2Word');
    $tests++;
}

use Lingua::BEL::Num2Word qw(num2bel_cardinal);

# Basic single digits
my @basic = (
    [ 0,  'нуль'     ],
    [ 1,  'адзін'    ],
    [ 2,  'два'      ],
    [ 3,  'тры'      ],
    [ 5,  'пяць'     ],
    [ 9,  'дзевяць'  ],
);

for my $case (@basic) {
    my ($num, $expected) = @$case;
    is(num2bel_cardinal($num), $expected, "$num => $expected");
    $tests++;
}

# Teens
my @teens = (
    [ 10, 'дзесяць'        ],
    [ 11, 'адзінаццаць'     ],
    [ 15, 'пятнаццаць'      ],
    [ 19, 'дзевятнаццаць'   ],
);

for my $case (@teens) {
    my ($num, $expected) = @$case;
    is(num2bel_cardinal($num), $expected, "$num => $expected");
    $tests++;
}

# Tens and compounds
my @tens = (
    [ 20,  'дваццаць'          ],
    [ 25,  'дваццаць пяць'     ],
    [ 42,  'сорак два'         ],
    [ 90,  'дзевяноста'        ],
    [ 99,  'дзевяноста дзевяць' ],
);

for my $case (@tens) {
    my ($num, $expected) = @$case;
    is(num2bel_cardinal($num), $expected, "$num => $expected");
    $tests++;
}

# Hundreds
my @hundreds = (
    [ 100, 'сто'                   ],
    [ 200, 'дзвесце'               ],
    [ 123, 'сто дваццаць тры'      ],
    [ 500, 'пяцьсот'               ],
    [ 999, 'дзевяцьсот дзевяноста дзевяць' ],
);

for my $case (@hundreds) {
    my ($num, $expected) = @$case;
    is(num2bel_cardinal($num), $expected, "$num => $expected");
    $tests++;
}

# Thousands
my @thousands = (
    [ 1000,   'тысяча'                    ],
    [ 2000,   'дзве тысячы'               ],
    [ 3000,   'тры тысячы'                ],
    [ 5000,   'пяць тысяч'                ],
    [ 21000,  'дваццаць адна тысяча'       ],
    [ 100000, 'сто тысяч'                 ],
);

for my $case (@thousands) {
    my ($num, $expected) = @$case;
    is(num2bel_cardinal($num), $expected, "$num => $expected");
    $tests++;
}

# Millions
my @millions = (
    [ 1000000,  'мільён'                   ],
    [ 2000000,  'два мільёны'              ],
    [ 5000000,  'пяць мільёнаў'            ],
);

for my $case (@millions) {
    my ($num, $expected) = @$case;
    is(num2bel_cardinal($num), $expected, "$num => $expected");
    $tests++;
}

# Error handling
eval { num2bel_cardinal(-1) };
like($@, qr/You should specify/, 'negative number croaks');
$tests++;

eval { num2bel_cardinal(1_000_000_000) };
like($@, qr/You should specify/, 'number too large croaks');
$tests++;

done_testing($tests);
