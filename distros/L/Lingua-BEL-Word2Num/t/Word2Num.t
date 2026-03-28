#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::BEL::Word2Num');
    $tests++;
}

use Lingua::BEL::Word2Num qw(w2n);

# Basic numbers
my @cases = (
    [ 'нуль',                              0     ],
    [ 'адзін',                             1     ],
    [ 'два',                               2     ],
    [ 'пяць',                              5     ],
    [ 'дзесяць',                           10    ],
    [ 'адзінаццаць',                        11    ],
    [ 'пятнаццаць',                         15    ],
    [ 'дзевятнаццаць',                      19    ],
    [ 'дваццаць',                           20    ],
    [ 'дваццаць пяць',                      25    ],
    [ 'сорак два',                          42    ],
    [ 'дзевяноста дзевяць',                 99    ],
    [ 'сто',                               100   ],
    [ 'дзвесце',                           200   ],
    [ 'сто дваццаць тры',                   123   ],
    [ 'пяцьсот',                           500   ],
    [ 'тысяча',                            1000  ],
    [ 'дзве тысячы',                       2000  ],
    [ 'пяць тысяч',                        5000  ],
    [ 'мільён',                            1000000 ],
    [ 'два мільёны',                       2000000 ],
    [ 'пяць мільёнаў',                     5000000 ],
);

for my $case (@cases) {
    my ($word, $expected) = @$case;
    is(w2n($word), $expected, "'$word' => $expected");
    $tests++;
}

# undef input
my $result = w2n(undef);
ok(!defined $result, 'undef input returns undef');
$tests++;

done_testing($tests);
