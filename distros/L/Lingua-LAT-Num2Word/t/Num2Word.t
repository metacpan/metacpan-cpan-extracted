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
    use_ok('Lingua::LAT::Num2Word');
    $tests++;
}

use Lingua::LAT::Num2Word          qw(:ALL);

# }}}

# {{{ num2lat_cardinal

my $n2l = [
    # basic numbers
    [ 0,    'nulla',                '0'    ],
    [ 1,    'unus',                 '1'    ],
    [ 5,    'quinque',              '5'    ],
    [ 9,    'novem',                '9'    ],
    [ 10,   'decem',                '10'   ],
    [ 11,   'undecim',              '11'   ],
    [ 12,   'duodecim',             '12'   ],
    [ 15,   'quindecim',            '15'   ],
    [ 17,   'septendecim',          '17'   ],

    # subtractive forms
    [ 18,   'duodeviginti',         '18 (subtractive)' ],
    [ 19,   'undeviginti',          '19 (subtractive)' ],
    [ 28,   'duodetriginta',        '28 (subtractive)' ],
    [ 29,   'undetriginta',         '29 (subtractive)' ],
    [ 38,   'duodequadraginta',     '38 (subtractive)' ],
    [ 48,   'duodequinquaginta',    '48 (subtractive)' ],
    [ 59,   'undesexaginta',        '59 (subtractive)' ],
    [ 88,   'duodenonaginta',       '88 (subtractive)' ],
    [ 89,   'undenonaginta',        '89 (subtractive)' ],
    [ 99,   'undecentum',           '99 (subtractive)' ],

    # additive exception
    [ 98,   'nonaginta octo',       '98 (additive exception)' ],

    # additive forms
    [ 20,   'viginti',              '20'   ],
    [ 21,   'viginti unus',         '21'   ],
    [ 25,   'viginti quinque',      '25'   ],
    [ 33,   'triginta tres',        '33'   ],
    [ 47,   'quadraginta septem',   '47'   ],
    [ 50,   'quinquaginta',         '50'   ],
    [ 64,   'sexaginta quattuor',   '64'   ],
    [ 76,   'septuaginta sex',      '76'   ],
    [ 90,   'nonaginta',            '90'   ],

    # hundreds
    [ 100,  'centum',               '100'  ],
    [ 101,  'centum unus',          '101'  ],
    [ 118,  'centum duodeviginti',  '118'  ],
    [ 200,  'ducenti',              '200'  ],
    [ 300,  'trecenti',             '300'  ],
    [ 400,  'quadringenti',         '400'  ],
    [ 500,  'quingenti',            '500'  ],
    [ 666,  'sescenti sexaginta sex', '666' ],
    [ 900,  'nongenti',             '900'  ],

    # thousands
    [ 1000, 'mille',                '1000' ],
    [ 1001, 'mille unus',           '1001' ],
    [ 1999, 'mille nongenti undecentum', '1999' ],
    [ 2000, 'duo milia',            '2000' ],
    [ 3000, 'tres milia',           '3000' ],
    [ 5248, 'quinque milia ducenti duodequinquaginta', '5248' ],
];

for my $test (@{$n2l}) {
    my $got = num2lat_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Latin');
    $tests++;
}

dies_ok( sub { num2lat_cardinal(1_000_000); }, 'out of range');
$tests++;

dies_ok( sub { num2lat_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
