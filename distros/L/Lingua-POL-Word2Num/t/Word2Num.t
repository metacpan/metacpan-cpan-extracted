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
    use_ok('Lingua::POL::Word2Num');
    $tests++;
}

use Lingua::POL::Word2Num           qw(:ALL);

# }}}

# {{{ w2n

my $wn = [
    [
        'siedemset siedem',
        707,
        '707 in POL',
    ],
    [
        'this is not valid number in Polish',
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
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}

done_testing($tests);

__END__
