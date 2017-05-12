#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;

use Test::More;

# }}}

# {{{ basic tests

my $DISABLE = 0;
my $module;
my $tests;
BEGIN {
    use_ok('Lingua::ENG::Word2Num');
    $tests++;
}

use Lingua::ENG::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'twelve thousand three hundred forty five',
        12345,
        '12345 in English'
    ],
    [
        'nine hundred ninety nine',
        999,
        '999 in English '
    ],
    [
        'nonexisting',
        undef,
        'nonexisting char -> 0'
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
