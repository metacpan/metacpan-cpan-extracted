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
    use_ok('Lingua::CES::Word2Num');
    $tests++;
}

use Lingua::CES::Word2Num           qw(:ALL);

# }}}

# {{{ w2n


my $w2n = [
    [
        'pět',
        5,
        '5'
    ],
    [
        'dvacet dva milionů',
        22_000_000,
        '22 000 000'
    ],
    [
        'dvacetdvamilionů',
        22_000_000,
        '22 000 000 without spaces - works as well'
    ],
    [
        'milion tisíc jedna',
        1_001_001,
        '1 001 001'
    ],
    [
        'this is not valid number in Czech',
        undef,
        'invalid number'
    ],
    [
        undef,
        undef,
        'undef args'
    ],
];

for my $test (@{$w2n}) {
    my $got = w2n($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Czech');
    $tests++;
}

# }}}

done_testing($tests);

__END__
