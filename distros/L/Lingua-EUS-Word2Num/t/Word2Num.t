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
   use_ok('Lingua::EUS::Word2Num');
   $tests++;
}

use Lingua::EUS::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'milioi bat eta mila ehun eta bi',
        1_001_102,
        '1 001 102 in Euskara Basque'
    ],
    [
        'mila bederatziehun eta laurogeita lau',
        1984,
        '1984 in Euskara Basque'
    ],
    [
        'nonexisting',
        0,
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
