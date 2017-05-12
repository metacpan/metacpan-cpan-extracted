#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use 5.10.1;

use utf8;
use Test::More;

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::POR::Words2Nums');
    $tests++;
}

use Lingua::POR::Words2Nums        qw(:ALL);

# }}}

# {{{ word2num

my $wn = [
    [
        'zero',
        0,
        '0 in Portuguese',
    ],
    [
        'seis mil novecentos e oitenta',
        6980,
        '6980 in Portuguese',
    ],
    [
        'dezanove mil novecentos e noventa e nove',
        19999,
        '19999 in Portuguese',
    ],
    [
        'nonexisting',
        undef,
        'nonexisting number -> undef',
    ],
    [
        undef,
        undef,
        'undef args',
    ],
];

for my $test (@{$wn}) {
    my $got = word2num($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}

done_testing($tests);

__END__
