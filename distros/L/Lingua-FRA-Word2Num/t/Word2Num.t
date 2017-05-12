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

my $tests;

BEGIN {
    use_ok('Lingua::FRA::Word2Num');
    $tests++;
}

use Lingua::FRA::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'cent vingt trois mille quatre cent cinquante six',
        123456,
        '123456 in French'
    ],
    [
        'un million neuf cent mille quatre cent cinquante',
        1_900_450,
        '1 900 450 in French'
    ],
    [
        'nonexisting',
        undef,
        'nonexisting char'
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
