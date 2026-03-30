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
    use_ok('Lingua::HYE::Word2Num');
    $tests++;
}

use Lingua::HYE::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'հարյուր երեսուն ութ',
        138,
        '138 in Armenian'
    ],
    [
        'ինը հարյուր իննսուն ինը',
        999,
        '999 in Armenian'
    ],
    [
        'քսան հինգ',
        25,
        '25 in Armenian'
    ],
    [
        'հազար',
        1000,
        '1000 in Armenian'
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
