#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SLV::Word2Num');
    $tests++;
}

use Lingua::SLV::Word2Num qw(w2n);

my @cases = (
    [ 'nič',                              0,          'nič = 0'            ],
    [ 'ena',                              1,          'ena = 1'            ],
    [ 'dva',                              2,          'dva = 2'            ],
    [ 'pet',                              5,          'pet = 5'            ],
    [ 'deset',                           10,          'deset = 10'         ],
    [ 'enajst',                          11,          'enajst = 11'        ],
    [ 'dvajset',                         20,          'dvajset = 20'       ],
    [ 'tri in dvajset',                  23,          'triindvajset = 23'  ],
    [ 'sto',                            100,          'sto = 100'          ],
    [ 'dvesto',                         200,          'dvesto = 200'       ],
    [ 'tristo pet in štirideset',       345,          'tristo petinštirideset = 345' ],
    [ 'tisoč',                         1000,          'tisoč = 1000'       ],
    [ 'dva tisoč',                     2000,          'dva tisoč = 2000'   ],
    [ 'milijon',                    1000000,          'milijon = 1000000'  ],
);

for my $case (@cases) {
    my ($input, $expected, $name) = @{$case};
    is(w2n($input), $expected, $name);
    $tests++;
}

my $result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
