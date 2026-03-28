#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
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
    use_ok('Lingua::GLG::Num2Word');
    $tests++;
}

use Lingua::GLG::Num2Word qw(num2glg_cardinal);

# }}}

# {{{ num2word

my $wn = [
    [       0, 'cero',                                              '0 in Galician'     ],
    [       1, 'un',                                                '1 in Galician'     ],
    [       2, 'dous',                                              '2 in Galician'     ],
    [       5, 'cinco',                                             '5 in Galician'     ],
    [       9, 'nove',                                              '9 in Galician'     ],
    [      10, 'dez',                                               '10 in Galician'    ],
    [      11, 'once',                                              '11 in Galician'    ],
    [      15, 'quince',                                            '15 in Galician'    ],
    [      19, 'dezanove',                                          '19 in Galician'    ],
    [      20, 'vinte',                                             '20 in Galician'    ],
    [      21, 'vinte e un',                                        '21 in Galician'    ],
    [      27, 'vinte e sete',                                      '27 in Galician'    ],
    [      30, 'trinta',                                            '30 in Galician'    ],
    [      42, 'corenta e dous',                                    '42 in Galician'    ],
    [      77, 'setenta e sete',                                    '77 in Galician'    ],
    [     100, 'cen',                                               '100 in Galician'   ],
    [     101, 'cento e un',                                        '101 in Galician'   ],
    [     200, 'douscentos',                                        '200 in Galician'   ],
    [     500, 'cincocentos',                                       '500 in Galician'   ],
    [     999, 'novecentos e noventa e nove',                       '999 in Galician'   ],
    [    1000, 'mil',                                               '1000 in Galician'  ],
    [    1001, 'mil e un',                                          '1001 in Galician'  ],
    [    2000, 'dous mil',                                          '2000 in Galician'  ],
    [    9999, 'nove mil novecentos e noventa e nove',              '9999 in Galician'  ],
    [   19999, 'dezanove mil novecentos e noventa e nove',          '19999 in Galician' ],
    [ 1000000, 'un millón',                                         '1000000 in Galician'],
    [ 2000000, 'dous millóns',                                      '2000000 in Galician'],
];

for my $test (@{$wn}) {
    my $got = num2glg_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}

done_testing($tests);

__END__
