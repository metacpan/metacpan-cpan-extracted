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
    use_ok('Lingua::ITA::Word2Num');
    $tests++;
}

use Lingua::ITA::Word2Num           qw(:ALL);

# }}}

# {{{ w2n

my $wn = [
    [
        'trecentoquarantacinque milioni seicentosettantottomilanovecentouno',
        345678901,
        '345678901',
    ],
    [
        'this is not valid number in Italian',
        undef,
        'invalid number',
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
    is($got, $exp, $test->[2] . ' in Italian');
    $tests++;
}


# }}}

done_testing($tests);

__END__
