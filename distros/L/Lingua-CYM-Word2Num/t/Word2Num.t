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
    use_ok('Lingua::CYM::Word2Num');
    $tests++;
}

use Lingua::CYM::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'dim',
        0,
        '0 in Welsh'
    ],
    [
        'sero',
        0,
        '0 (sero) in Welsh'
    ],
    [
        'pump',
        5,
        '5 in Welsh'
    ],
    [
        'deg',
        10,
        '10 in Welsh'
    ],
    [
        'un deg tri',
        13,
        '13 in Welsh'
    ],
    [
        'dau ddeg',
        20,
        '20 in Welsh'
    ],
    [
        'tri deg pedwar',
        34,
        '34 in Welsh'
    ],
    [
        'pum deg chwech',
        56,
        '56 in Welsh'
    ],
    [
        'cant',
        100,
        '100 in Welsh'
    ],
    [
        'dau gant tri deg pump',
        235,
        '235 in Welsh'
    ],
    [
        'mil',
        1000,
        '1000 in Welsh'
    ],
    [
        'tri mil pum cant',
        3500,
        '3500 in Welsh'
    ],
    [
        'nonexisting',
        undef,
        'nonexisting char -> undef'
    ],
    [
        undef,
        undef,
        'undef args'
    ],
];

for my $test (@{$wn}) {
    my $got = w2n($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}

done_testing($tests);

__END__
