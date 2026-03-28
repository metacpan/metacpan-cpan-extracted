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
    use_ok('Lingua::LTZ::Word2Num');
    $tests++;
}

use Lingua::LTZ::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [ 'null',                              0,     '0'    ],
    [ 'eent',                              1,     '1'    ],
    [ 'een',                               1,     '1 (compound form)' ],
    [ 'zwee',                              2,     '2'    ],
    [ 'dräi',                              3,     '3'    ],
    [ 'fënnef',                            5,     '5'    ],
    [ 'siwen',                             7,     '7'    ],
    [ 'zéng',                              10,    '10'   ],
    [ 'eelef',                             11,    '11'   ],
    [ 'zwielef',                           12,    '12'   ],
    [ 'dräizéng',                          13,    '13'   ],
    [ 'fofzéng',                           15,    '15'   ],
    [ 'siechzéng',                         16,    '16'   ],
    [ 'siwwenzéng',                        17,    '17'   ],
    [ 'uechtzéng',                         18,    '18'   ],
    [ 'nonzéng',                           19,    '19'   ],
    [ 'zwanzeg',                           20,    '20'   ],
    [ 'eenanzwanzeg',                      21,    '21'   ],
    [ 'dräiandrësseg',                     33,    '33'   ],
    [ 'eenafofzeg',                        51,    '51'   ],
    [ 'honnert',                           100,   '100'  ],
    [ 'honnerteenanzwanzeg',               121,   '121'  ],
    [ 'dausend',                           1000,  '1000' ],
    [ 'dausendzweehonnertnonzéng',         1219,  '1219' ],
    [ 'nonexisting',                       undef, 'nonexisting word' ],
    [ undef,                               undef, 'undef args' ],
];

for my $test (@{$wn}) {
    my $got = w2n($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Luxembourgish');
    $tests++;
}

# }}}

done_testing($tests);

__END__
