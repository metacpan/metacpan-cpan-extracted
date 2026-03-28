#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::OCI::Num2Word');
    $tests++;
}

use Lingua::OCI::Num2Word qw(num2oci_cardinal);

my @pairs = (
    [   0, 'zèro'                               ],
    [   1, 'un'                                  ],
    [   5, 'cinc'                                ],
    [   7, 'sèt'                                 ],
    [   8, 'uèch'                                ],
    [   9, 'nòu'                                 ],
    [  10, 'dètz'                                ],
    [  11, 'onze'                                ],
    [  14, 'catòrze'                             ],
    [  16, 'setze'                               ],
    [  17, 'dètz-e-sèt'                          ],
    [  18, 'dètz-e-uèch'                         ],
    [  19, 'dètz-e-nòu'                          ],
    [  20, 'vint'                                ],
    [  21, 'vint-e-un'                           ],
    [  25, 'vint-e-cinc'                         ],
    [  30, 'trenta'                              ],
    [  31, 'trenta-e-un'                         ],
    [  42, 'quaranta-e-dos'                      ],
    [  50, 'cinquanta'                           ],
    [  67, 'seissanta-e-sèt'                     ],
    [  70, 'setanta'                             ],
    [  80, 'ochanta'                             ],
    [  90, 'nonanta'                             ],
    [  99, 'nonanta-e-nòu'                       ],
    [ 100, 'cent'                                ],
    [ 123, 'cent vint-e-tres'                    ],
    [ 200, 'dos cents'                           ],
    [ 300, 'tres cents'                          ],
    [ 500, 'cinc cents'                          ],
    [ 999, 'nòu cents nonanta-e-nòu'             ],
    [1000, 'mila'                                ],
    [1001, 'mila un'                             ],
    [2000, 'dos mila'                            ],
    [5280, 'cinc mila dos cents ochanta'          ],
    [1000000, 'un milion'                        ],
    [2000000, 'dos milions'                      ],
    [1234567, 'un milion dos cents trenta-e-quatre mila cinc cents seissanta-e-sèt' ],
);

for my $pair (@pairs) {
    my ($num, $expected) = @$pair;
    my $result = num2oci_cardinal($num);
    is($result, $expected, "$num => $expected");
    $tests++;
}

# test that 0 returns defined value
my $result = num2oci_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

# test capabilities
my $cap = Lingua::OCI::Num2Word::capabilities();
is($cap->{cardinal}, 1, 'cardinal capability');
$tests++;
is($cap->{ordinal},  0, 'ordinal capability');
$tests++;

done_testing($tests);
