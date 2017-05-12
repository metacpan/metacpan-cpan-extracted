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
    use_ok('Lingua::NLD::Word2Num');
    $tests++;
}

use Lingua::NLD::Word2Num           qw(:ALL);

# }}}

# {{{ w2n

my $wn = [
    [
        'nul',
        0,
        'nul in nld',
    ],
    [
        'een',
        1,
        'one in nld',
    ],
    [
        'vijftien',
        15,
        '15 in nld',
    ],
    [
        'zevenentwintig',
        27,
        '27 in nld',
    ],
    [
        'twintigste',
        20,
        '20th - ordinal',
    ],
    [
        'vier honderd zes en vijftig duizend, zevenhonderd negenentachtig',
        456789,
        '456789 in nld',
    ],
    [
        'honderd drieentwintig',
        123,
        '123 in nld',
    ],
    [
        'this is not valid number in NLD',
        undef,
        'invalid number -> undef',
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

