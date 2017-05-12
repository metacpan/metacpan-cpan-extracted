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
    use_ok('Lingua::SPA::Word2Num');
    $tests++;
}

use Lingua::SPA::Word2Num          qw(:ALL);

# }}}

# {{{ w2n

my $wn = [
    [
        'ciento veinticuatro',
        124,
        '124 in SPA',
    ],
    [
        'trescientos cuarenta',
        340,
        '340 in SPA',
    ],
    [
        'nonexisting',
        undef,
        'nonexisting number',
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
