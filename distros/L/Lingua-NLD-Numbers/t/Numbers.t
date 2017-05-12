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
    use_ok('Lingua::NLD::Numbers');
    $tests++;
}

use Lingua::NLD::Numbers           qw(:ALL);

# }}}

# {{{ parse

my $numbers = Lingua::NLD::Numbers->new;

my $nw = [
    [
        [$numbers, 123],
        'honderd drieentwintig',
        '123',
    ],
    [
        [$numbers, 456789],
        'vier honderd zes en vijftig duizend, zevenhonderd negenentachtig',
        '456789',
    ],
    [
        [$numbers, 100000000000000],
        q{},
        'out of bounds',
    ],
    [
        [$numbers, undef],
        q{},
        'undef args',
    ],
];

for my $test (@{$nw}) {
    my $got = parse(@{$test->[0]});
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in NLD');
    $tests++;
}

# }}}

done_testing($tests);

__END__
