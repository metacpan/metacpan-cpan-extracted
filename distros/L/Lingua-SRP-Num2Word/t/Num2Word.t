#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SRP::Num2Word');
    $tests++;
}

use Lingua::SRP::Num2Word qw(num2srp_cardinal);

my @pairs = (
    [       0, 'нула'                        ],
    [       1, 'један'                       ],
    [       2, 'два'                         ],
    [       5, 'пет'                         ],
    [       9, 'девет'                       ],
    [      10, 'десет'                       ],
    [      11, 'једанаест'                   ],
    [      12, 'дванаест'                    ],
    [      19, 'деветнаест'                  ],
    [      20, 'двадесет'                    ],
    [      23, 'двадесет три'                ],
    [      42, 'четрдесет два'               ],
    [      99, 'деведесет девет'             ],
    [     100, 'сто'                         ],
    [     200, 'двеста'                      ],
    [     300, 'триста'                      ],
    [     400, 'четиристо'                   ],
    [     123, 'сто двадесет три'            ],
    [     555, 'петсто педесет пет'          ],
    [     999, 'деветсто деведесет девет'    ],
    [    1000, 'хиљада'                      ],
    [    2000, 'две хиљаде'                  ],
    [    3000, 'три хиљаде'                  ],
    [    5000, 'пет хиљада'                  ],
    [   21000, 'двадесет једна хиљада'       ],
    [   22000, 'двадесет две хиљаде'         ],
    [ 1000000, 'један милион'                ],
    [ 2000000, 'два милиона'                 ],
);

for my $pair (@pairs) {
    my ($num, $expected) = @$pair;
    my $got = num2srp_cardinal($num);
    is($got, $expected, "$num => $expected");
    $tests++;
}

# error handling
eval { num2srp_cardinal(-1) };
like($@, qr/interval/, 'negative number croaks');
$tests++;

eval { num2srp_cardinal(1_000_000_000) };
like($@, qr/interval/, 'too large number croaks');
$tests++;

done_testing($tests);
