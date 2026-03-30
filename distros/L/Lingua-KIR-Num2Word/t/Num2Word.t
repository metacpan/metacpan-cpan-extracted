#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::KIR::Num2Word');
    $tests++;
}

use Lingua::KIR::Num2Word qw(num2kir_cardinal);

my @cases = (
    [ 0,         'нөл'                                   ],
    [ 1,         'бир'                                    ],
    [ 2,         'эки'                                    ],
    [ 3,         'үч'                                     ],
    [ 4,         'төрт'                                   ],
    [ 5,         'беш'                                    ],
    [ 6,         'алты'                                   ],
    [ 7,         'жети'                                   ],
    [ 8,         'сегиз'                                  ],
    [ 9,         'тогуз'                                  ],
    [ 10,        'он'                                     ],
    [ 11,        'он бир'                                 ],
    [ 20,        'жыйырма'                               ],
    [ 23,        'жыйырма үч'                            ],
    [ 40,        'кырк'                                   ],
    [ 50,        'элүү'                                   ],
    [ 90,        'токсон'                                 ],
    [ 99,        'токсон тогуз'                           ],
    [ 100,       'жүз'                                    ],
    [ 101,       'жүз бир'                                ],
    [ 200,       'эки жүз'                                ],
    [ 123,       'жүз жыйырма үч'                        ],
    [ 555,       'беш жүз элүү беш'                      ],
    [ 999,       'тогуз жүз токсон тогуз'                ],
    [ 1000,      'миң'                                    ],
    [ 1001,      'миң бир'                                ],
    [ 2000,      'эки миң'                                ],
    [ 10_000,    'он миң'                                 ],
    [ 12_345,    'он эки миң үч жүз кырк беш'            ],
    [ 100_000,   'жүз миң'                                ],
    [ 999_999,   'тогуз жүз токсон тогуз миң тогуз жүз токсон тогуз' ],
    [ 1_000_000, 'бир миллион'                            ],
    [ 5_000_123, 'беш миллион жүз жыйырма үч'            ],
);

for my $case (@cases) {
    my ($num, $expected) = @$case;
    my $result = num2kir_cardinal($num);
    is($result, $expected, "$num => $expected");
    $tests++;
}

# capabilities
my $cap = Lingua::KIR::Num2Word::capabilities();
ok($cap->{cardinal}, 'capabilities reports cardinal');
$tests++;

done_testing($tests);
