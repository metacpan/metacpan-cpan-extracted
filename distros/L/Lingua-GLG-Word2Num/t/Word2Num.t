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
    use_ok('Lingua::GLG::Word2Num');
    $tests++;
}

use Lingua::GLG::Word2Num qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'cero',
        0,
        '0 in Galician',
    ],
    [
        'vinte e sete',
        27,
        '27 in Galician',
    ],
    [
        'cen',
        100,
        '100 in Galician',
    ],
    [
        'cento corenta e dous',
        142,
        '142 in Galician',
    ],
    [
        'mil',
        1000,
        '1000 in Galician',
    ],
    [
        'seis mil novecentos e oitenta',
        6980,
        '6980 in Galician',
    ],
    [
        'dezanove mil novecentos e noventa e nove',
        19999,
        '19999 in Galician',
    ],
    [
        'nonexisting',
        undef,
        'nonexisting number -> undef',
    ],
    [
        undef,
        undef,
        'undef args',
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
