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
    use_ok('Lingua::POL::Numbers');
    $tests++;
}

use Lingua::POL::Numbers           qw(:ALL);

# }}}

# {{{ parse

my $numbers = Lingua::POL::Numbers->new;

my $nw = [
    [
        [$numbers, 707],
        'siedemset siedem ',
        '707',
    ],
    [
        [$numbers, 100000000000000],
        'out of range',
        'out of bounds',
    ],
    [
        [$numbers, undef],
        'zero',
        'undef args',
    ],
];

for my $test (@{$nw}) {
    my $got = parse(@{$test->[0]});
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in POL');
    $tests++;
}

# }}}

done_testing($tests);

__END__
