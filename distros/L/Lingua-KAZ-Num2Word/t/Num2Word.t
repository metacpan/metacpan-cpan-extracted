#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::KAZ::Num2Word');
    $tests++;
}

use Lingua::KAZ::Num2Word qw(num2kaz_cardinal);

my @cases = (
    [ 0,         'нөл'                                   ],
    [ 1,         'бір'                                    ],
    [ 2,         'екі'                                    ],
    [ 3,         'үш'                                     ],
    [ 4,         'төрт'                                   ],
    [ 5,         'бес'                                    ],
    [ 6,         'алты'                                   ],
    [ 7,         'жеті'                                   ],
    [ 8,         'сегіз'                                  ],
    [ 9,         'тоғыз'                                  ],
    [ 10,        'он'                                     ],
    [ 11,        'он бір'                                 ],
    [ 20,        'жиырма'                                 ],
    [ 23,        'жиырма үш'                              ],
    [ 40,        'қырық'                                  ],
    [ 50,        'елу'                                    ],
    [ 90,        'тоқсан'                                 ],
    [ 99,        'тоқсан тоғыз'                           ],
    [ 100,       'жүз'                                    ],
    [ 101,       'жүз бір'                                ],
    [ 200,       'екі жүз'                                ],
    [ 123,       'жүз жиырма үш'                          ],
    [ 555,       'бес жүз елу бес'                        ],
    [ 999,       'тоғыз жүз тоқсан тоғыз'                ],
    [ 1000,      'мың'                                    ],
    [ 1001,      'мың бір'                                ],
    [ 2000,      'екі мың'                                ],
    [ 10_000,    'он мың'                                 ],
    [ 12_345,    'он екі мың үш жүз қырық бес'            ],
    [ 100_000,   'жүз мың'                                ],
    [ 999_999,   'тоғыз жүз тоқсан тоғыз мың тоғыз жүз тоқсан тоғыз' ],
    [ 1_000_000, 'бір миллион'                            ],
    [ 5_000_123, 'бес миллион жүз жиырма үш'              ],
);

for my $case (@cases) {
    my ($num, $expected) = @$case;
    my $result = num2kaz_cardinal($num);
    is($result, $expected, "$num => $expected");
    $tests++;
}

# capabilities
my $cap = Lingua::KAZ::Num2Word::capabilities();
ok($cap->{cardinal}, 'capabilities reports cardinal');
$tests++;

done_testing($tests);
