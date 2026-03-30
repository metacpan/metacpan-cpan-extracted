#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::AZE::Num2Word');
    $tests++;
}

use Lingua::AZE::Num2Word qw(num2aze_cardinal);

my @cases = (
    [ 0,         'sıfır'                               ],
    [ 1,         'bir'                                  ],
    [ 2,         'iki'                                  ],
    [ 3,         'üç'                                   ],
    [ 4,         'dörd'                                 ],
    [ 5,         'beş'                                  ],
    [ 6,         'altı'                                 ],
    [ 7,         'yeddi'                                ],
    [ 8,         'səkkiz'                               ],
    [ 9,         'doqquz'                               ],
    [ 10,        'on'                                   ],
    [ 11,        'on bir'                               ],
    [ 20,        'iyirmi'                               ],
    [ 23,        'iyirmi üç'                            ],
    [ 40,        'qırx'                                 ],
    [ 50,        'əlli'                                 ],
    [ 90,        'doxsan'                               ],
    [ 99,        'doxsan doqquz'                        ],
    [ 100,       'yüz'                                  ],
    [ 101,       'yüz bir'                              ],
    [ 200,       'iki yüz'                              ],
    [ 123,       'yüz iyirmi üç'                        ],
    [ 555,       'beş yüz əlli beş'                     ],
    [ 999,       'doqquz yüz doxsan doqquz'             ],
    [ 1000,      'min'                                  ],
    [ 1001,      'min bir'                              ],
    [ 2000,      'iki min'                              ],
    [ 10_000,    'on min'                               ],
    [ 12_345,    'on iki min üç yüz qırx beş'          ],
    [ 100_000,   'yüz min'                              ],
    [ 999_999,   'doqquz yüz doxsan doqquz min doqquz yüz doxsan doqquz' ],
    [ 1_000_000, 'bir milyon'                           ],
    [ 5_000_123, 'beş milyon yüz iyirmi üç'            ],
);

for my $case (@cases) {
    my ($num, $expected) = @$case;
    my $result = num2aze_cardinal($num);
    is($result, $expected, "$num => $expected");
    $tests++;
}

# capabilities
my $cap = Lingua::AZE::Num2Word::capabilities();
ok($cap->{cardinal}, 'capabilities reports cardinal');
$tests++;

done_testing($tests);
