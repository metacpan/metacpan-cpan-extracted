#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use 5.10.1;

use Test::More;
use Test::More::UTF8;
# use utf8;

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::RUS::Number');
    $tests++;
}

use Lingua::RUS::Number            qw(rur_in_words get_string);

# }}}

# {{{ rur_in_words


my $nw = [
    [
        8,
        'восемь рублей ноль копеек',
        '8.00 RUR',
    ],
    [
        '8.9',
        'восемь рублей девяносто копеек',
        '8.90 RUR',
    ],
    [
        999_888,
        'девятьсот девяносто девять тысяч восемьсот восемьдесят восемь рублей ноль копеек',
        '999 888 RUR',
    ],
    [
        -5,
        ' ноль копеек',
        'negative',
    ],
    [
        0,
        ' ноль копеек',
        '0 RUR',
    ],
    [
        undef,
        ' ноль копеек',
        'undef args',
    ],
];

for my $test (@{$nw}) {
    my $got = rur_in_words($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}



# }}}
# {{{ get_string

my $gs = [
    [
        [0, 0],
        'ноль копеек',
        '0',
    ],
    [
        [1, 1],
        'один рубль',
        '1',
    ],
    [
        [2, 2],
        'две тысячи',
        '2000',
    ],
    [
        [3, 3],
        'три миллиона',
        '3 000 000 000',
    ],
    [
        [3],
        'три',
        '3',
    ],
    [
        [undef, 3],
        undef,
        'undef value',
    ],
    [
        undef,
        undef,
        'undef args',
    ],
];

for my $test (@{$gs}) {
    my $got = get_string(@{$test->[0]});
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in RUS');
    $tests++;
}

# }}}

done_testing($tests);

__END__
