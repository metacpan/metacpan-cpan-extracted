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
    use_ok('Lingua::JPN::Word2Num');
    $tests++;
}

use Lingua::JPN::Word2Num           qw(:ALL);

# }}}

# {{{ w2n

my $wn = [
    [
        'yon-sen-nana-hyaku-nana-ju-san',
        4773,
        '4773',
    ],
    [
        'ichi-man',
        10000,
        '10000',
    ],
    [
        'this is not valid number in Japan',
        q{},
        'invalid number'
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
    is($got, $exp, $test->[2] . ' in Japan');
    $tests++;
}

# }}}

done_testing($tests);

__END__
