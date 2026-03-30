#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-
#
# Copyright (c) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;

use Test::More;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::HIN::Word2Num');
    $tests++;
}

use Lingua::HIN::Word2Num          qw(w2n);

# }}}

# {{{ w2n — individual numbers 0-99

my $wn = [
    # single digits
    [ 'शून्य',       0,  '0 (zero)'          ],
    [ 'एक',         1,  '1 (one)'           ],
    [ 'दो',         2,  '2 (two)'           ],
    [ 'तीन',        3,  '3 (three)'         ],
    [ 'चार',        4,  '4 (four)'          ],
    [ 'पाँच',       5,  '5 (five)'          ],
    [ 'छह',         6,  '6 (six)'           ],
    [ 'सात',        7,  '7 (seven)'         ],
    [ 'आठ',         8,  '8 (eight)'         ],
    [ 'नौ',         9,  '9 (nine)'          ],

    # teens
    [ 'दस',         10, '10 (ten)'          ],
    [ 'ग्यारह',      11, '11 (eleven)'       ],
    [ 'बारह',       12, '12 (twelve)'       ],
    [ 'तेरह',       13, '13 (thirteen)'     ],
    [ 'चौदह',       14, '14 (fourteen)'     ],
    [ 'पंद्रह',      15, '15 (fifteen)'      ],
    [ 'सोलह',       16, '16 (sixteen)'      ],
    [ 'सत्रह',       17, '17 (seventeen)'    ],
    [ 'अट्ठारह',     18, '18 (eighteen)'     ],
    [ 'उन्नीस',      19, '19 (nineteen)'     ],

    # twenties
    [ 'बीस',        20, '20 (twenty)'       ],
    [ 'इक्कीस',      21, 'w2n 21'             ],
    [ 'पच्चीस',      25, 'w2n 25'             ],
    [ 'उनतीस',      29, 'w2n 29'             ],

    # thirties-forties
    [ 'तीस',        30, 'w2n 30'             ],
    [ 'छत्तीस',      36, 'w2n 36'             ],
    [ 'चालीस',      40, 'w2n 40'             ],
    [ 'उनचास',      49, 'w2n 49'             ],

    # fifties-sixties
    [ 'पचास',       50, 'w2n 50'             ],
    [ 'छप्पन',       56, 'w2n 56'             ],
    [ 'साठ',        60, 'w2n 60'             ],
    [ 'उनहत्तर',     69, 'w2n 69'             ],

    # seventies-eighties
    [ 'सत्तर',       70, 'w2n 70'             ],
    [ 'उन्यासी',     79, 'w2n 79'             ],
    [ 'अस्सी',       80, 'w2n 80'             ],
    [ 'नवासी',       89, 'w2n 89'             ],

    # nineties
    [ 'नब्बे',       90, 'w2n 90'             ],
    [ 'निन्यानवे',    99, 'w2n 99'             ],
];

for my $test (@{$wn}) {
    my $got = w2n($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}

# {{{ w2n — compounds (hundreds, thousands, lakhs, crores)

my $compounds = [
    [ 'सौ',                                     100,          '100 (bare sau)'        ],
    [ 'एक सौ',                                   100,          '100 (ek sau)'          ],
    [ 'एक सौ पच्चीस',                              125,          'w2n 125'               ],
    [ 'दो सौ',                                    200,          'w2n 200'               ],
    [ 'नौ सौ निन्यानवे',                             999,          'w2n 999'               ],
    [ 'हज़ार',                                    1_000,        '1000 (bare hazaar)'    ],
    [ 'एक हज़ार',                                  1_000,        '1000 (ek hazaar)'      ],
    [ 'एक हज़ार नौ सौ सैंतालीस',                      1_947,        'w2n 1947'              ],
    [ 'दस हज़ार',                                  10_000,       'w2n 10000'             ],
    [ 'लाख',                                     1_00_000,     '100000 (bare lakh)'    ],
    [ 'एक लाख',                                   1_00_000,     '100000 (ek lakh)'      ],
    [ 'पाँच लाख पचास हज़ार',                         5_50_000,     'w2n 550000'            ],
    [ 'करोड़',                                    1_00_00_000,  '10000000 (bare crore)' ],
    [ 'एक करोड़',                                  1_00_00_000,  '10000000 (ek crore)'   ],
    [ 'बारह करोड़ चौंतीस लाख छप्पन हज़ार सात सौ नवासी', 12_34_56_789, '123456789 (full)'      ],
];

for my $test (@{$compounds}) {
    my $got = w2n($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}

# {{{ w2n — edge cases

is(w2n('nonexisting'), undef, 'nonexisting word -> undef');
$tests++;

is(w2n(undef), undef, 'undef input -> undef');
$tests++;

# }}}

done_testing($tests);

__END__
