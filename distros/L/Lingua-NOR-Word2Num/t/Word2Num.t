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
    use_ok('Lingua::NOR::Word2Num');
    $tests++;
}

use Lingua::NOR::Word2Num           qw(:ALL);

# }}}

# {{{ w2n

my $wn = [
    [
        'ti millioner og sytti tre tusen to hundre og femti to',
        10_073_252,
        '456789',
    ],
    [
        'fem tusen og fem',
        5005,
        '5005',
    ],
    [
        'this is not valid number in NLD',
        0,
        'invalid number -> 0',
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
    is($got, $exp, $test->[2] . ' in NOR');
    $tests++;
}


# }}}

done_testing($tests);

__END__
