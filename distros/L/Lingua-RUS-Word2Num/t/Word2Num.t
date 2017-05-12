#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use 5.10.1;

use utf8;
use Test::More;

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::RUS::Word2Num');
    $tests++;
}

use Lingua::RUS::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $test_lr =[
    [
        'ноль',
        0,
        '0 in Russia',
    ],
    [
        'восемь',
        8,
        '8 in Russian'
    ],
    [
        'пятьдесят',
        50,
        '50 in Russian',
    ],
    [
        'сто тридцать три',
        133,
        '133 in Russian',
    ],
    [
        'девятьсот девяносто девять',
        999,
        '999 in Russian'
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

for my $test (@{$test_lr}) {
    my $got = w2n($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Russian');
    $tests++;
}

# }}}

done_testing($tests);

__END__
