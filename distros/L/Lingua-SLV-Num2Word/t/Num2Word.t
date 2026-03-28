#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SLV::Num2Word');
    $tests++;
}

use Lingua::SLV::Num2Word qw(num2slv_cardinal);

my @cases = (
    [          0, 'nič',                                  '0 = nič'             ],
    [          1, 'ena',                                  '1 = ena'             ],
    [          2, 'dva',                                  '2 = dva'             ],
    [          5, 'pet',                                  '5 = pet'             ],
    [         10, 'deset',                                '10 = deset'          ],
    [         11, 'enajst',                               '11 = enajst'         ],
    [         20, 'dvajset',                              '20 = dvajset'        ],
    [         23, 'triindvajset',                         '23 = triindvajset'   ],
    [         99, 'devetindevetdeset',                    '99 = devetindevetdeset' ],
    [        100, 'sto',                                  '100 = sto'           ],
    [        200, 'dvesto',                               '200 = dvesto'       ],
    [        345, 'tristo petinštirideset',               '345 = tristo petinštirideset' ],
    [       1000, 'tisoč',                                '1000 = tisoč'        ],
    [       2000, 'dva tisoč',                            'dva tisoč = 2000'     ],
    [    1000000, 'en milijon',                           'en milijon'           ],
    [    2000000, 'dva milijona',                         'dva milijona'         ],
    [    5000000, 'pet milijonov',                        'pet milijonov'        ],
    [    3000000, 'tri milijone',                         'tri milijone'         ],
);

for my $case (@cases) {
    my ($input, $expected, $name) = @{$case};
    is(num2slv_cardinal($input), $expected, $name);
    $tests++;
}

my $result = num2slv_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
