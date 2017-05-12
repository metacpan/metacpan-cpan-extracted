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
    use_ok('Lingua::SWE::Num2Word');
    $tests++;
}

use Lingua::SWE::Num2Word          qw(num2sv_cardinal);

# }}}

# {{{ num2sv_cardinal

my $nw = [
    [
        123456,
        'etthundratjugotretusenfyrahundrafemtiosex',
        '123456 in SWE',
    ],
    [
        9999,
        'niotusenniohundranittionio',
        '9999 in SWE',
    ],
    [
        '0.33',
        'noll',
        'nonexisting number -> 0',
    ],
    [
        undef,
        'noll',
        'undef args -> 0'
    ],
];


for my $test (@{$nw}) {
    my $got = num2sv_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}

done_testing($tests);

__END__
