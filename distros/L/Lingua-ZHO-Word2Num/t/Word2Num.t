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
    use_ok('Lingua::ZHO::Word2Num');
    $tests++;
}

use Lingua::ZHO::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'ErWan WuQian SiBai SiShi Jiu',
        25449,
        '25449 in PinYin',
    ],
    [
        'Ling',
        0,
        '0 in PinYin'
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
