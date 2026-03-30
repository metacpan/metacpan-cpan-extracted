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

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::LAT::Word2Num');
    $tests++;
}

use Lingua::LAT::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    # basic numbers
    [ 'nulla',                  0,     '0'    ],
    [ 'unus',                   1,     '1'    ],
    [ 'quinque',                5,     '5'    ],
    [ 'decem',                  10,    '10'   ],
    [ 'undecim',                11,    '11'   ],
    [ 'duodecim',               12,    '12'   ],
    [ 'septendecim',            17,    '17'   ],

    # subtractive forms
    [ 'duodeviginti',           18,    '18 (subtractive)' ],
    [ 'undeviginti',            19,    '19 (subtractive)' ],
    [ 'duodetriginta',          28,    '28 (subtractive)' ],
    [ 'undetriginta',           29,    '29 (subtractive)' ],
    [ 'duodequinquaginta',      48,    '48 (subtractive)' ],
    [ 'undesexaginta',          59,    '59 (subtractive)' ],
    [ 'duodenonaginta',         88,    '88 (subtractive)' ],
    [ 'undecentum',             99,    '99 (subtractive)' ],

    # additive forms
    [ 'viginti',                20,    '20'   ],
    [ 'viginti unus',           21,    '21'   ],
    [ 'triginta tres',          33,    '33'   ],
    [ 'nonaginta octo',         98,    '98 (additive exception)' ],

    # hundreds
    [ 'centum',                 100,   '100'  ],
    [ 'centum unus',            101,   '101'  ],
    [ 'centum duodeviginti',    118,   '118'  ],
    [ 'ducenti',                200,   '200'  ],
    [ 'quingenti',              500,   '500'  ],
    [ 'nongenti',               900,   '900'  ],

    # thousands
    [ 'mille',                  1000,  '1000' ],
    [ 'mille unus',             1001,  '1001' ],
    [ 'duo milia',              2000,  '2000' ],
    [ 'quinque milia ducenti duodequinquaginta', 5248, '5248' ],

    # error cases
    [ 'nonexisting',            undef, 'nonexisting -> undef' ],
    [ undef,                    undef, 'undef args'           ],
];

for my $test (@{$wn}) {
    my $got = w2n($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Latin');
    $tests++;
}

# }}}

done_testing($tests);

__END__
