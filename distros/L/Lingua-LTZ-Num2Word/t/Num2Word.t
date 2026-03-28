#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-
#
# Copyright (c) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;

use Test::Exception;
use Test::More;

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::LTZ::Num2Word');
    $tests++;
}

use Lingua::LTZ::Num2Word           qw(:ALL);

# }}}

# {{{ num2ltz_cardinal

my $n2l = [
    [ 0,          'null',                              '0'          ],
    [ 1,          'eent',                              '1'          ],
    [ 2,          'zwee',                              '2'          ],
    [ 3,          'dräi',                              '3'          ],
    [ 5,          'fënnef',                            '5'          ],
    [ 7,          'siwen',                             '7'          ],
    [ 10,         'zéng',                              '10'         ],
    [ 11,         'eelef',                             '11'         ],
    [ 12,         'zwielef',                           '12'         ],
    [ 13,         'dräizéng',                          '13'         ],
    [ 15,         'fofzéng',                           '15'         ],
    [ 16,         'siechzéng',                         '16'         ],
    [ 17,         'siwwenzéng',                        '17'         ],
    [ 18,         'uechtzéng',                         '18'         ],
    [ 19,         'nonzéng',                           '19'         ],
    [ 20,         'zwanzeg',                           '20'         ],
    [ 21,         'eenanzwanzeg',                      '21'         ],
    [ 22,         'zweeanzwanzeg',                     '22'         ],
    [ 31,         'eenandrësseg',                      '31'         ],
    [ 33,         'dräiandrësseg',                     '33'         ],
    [ 35,         'fënnefandrësseg',                   '35'         ],
    [ 42,         'zweeavéierzeg',                     '42'         ],
    [ 51,         'eenafofzeg',                        '51'         ],
    [ 67,         'siwenasechzeg',                     '67'         ],
    [ 73,         'dräiasiwwenzeg',                    '73'         ],
    [ 88,         'aachtanachtzeg',                    '88'         ],
    [ 99,         'néngannonzeg',                       '99'         ],
    [ 100,        'honnert',                           '100'        ],
    [ 121,        'honnerteenanzwanzeg',               '121'        ],
    [ 200,        'zweehonnert',                       '200'        ],
    [ 300,        'dräihonnert',                       '300'        ],
    [ 999,        'nénghonnertnéngannonzeg',            '999'        ],
    [ 1000,       'dausend',                           '1000'       ],
    [ 1219,       'dausendzweehonnertnonzéng',         '1219'       ],
    [ 2000,       'zweedausend',                       '2000'       ],
    [ 1000000,    'eng Millioun',                      '1000000'    ],
    [ 2000000,    'zwee Milliounen',                   '2000000'    ],
    [ 3567,       'dräidausendfënnefhonnertsiwenasechzeg', '3567'   ],
];

for my $test (@{$n2l}) {
    my $got = num2ltz_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Luxembourgish');
    $tests++;
}

dies_ok( sub { num2ltz_cardinal(100000000000); }, 'out of range');
$tests++;

dies_ok( sub { num2ltz_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
