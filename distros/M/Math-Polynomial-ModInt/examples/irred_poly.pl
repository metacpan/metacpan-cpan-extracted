#!/usr/bin/env perl

# Copyright (c) 2019-2022 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Math::Polynomial::ModInt example: enumerate irreducible polynomials

use strict;
use warnings;
use Math::BigInt try => 'GMP';
use Math::ModInt qw(mod);
use Math::Polynomial::ModInt qw(modpoly);
use Math::Polynomial::ModInt::Order qw($BY_INDEX);

my $p = @ARGV > 0? shift @ARGV: 5;
my $n = @ARGV > 0? shift @ARGV: 3;
if (@ARGV || grep { !/^[1-9][0-9]*\z/ } $p, $n) {
    die "usage: $0 prime exponent\n";
}

my %CONFIG = (
    prefix        => q[],
    suffix        => q[],
    times         => q[*],
    convert_coeff => sub { $_[0]->residue },
);

my $one   = mod(1, $p)->optimize_time;
my $poly  = Math::Polynomial::ModInt->monomial($n, $one);
my $count = 0;

$poly->string_config(\%CONFIG);

while ($poly->is_monic && $poly->degree == $n) {
    if ($poly->is_irreducible) {
        ++$count;
        print
            "modpoly(", $poly->index, q[, ], $poly->modulus, q[) = ],
            $poly->as_string, "\n";
    }
    $poly = $BY_INDEX->next_poly($poly);
}

print
    "There are $count monic irreducible polynomials ",
    "modulo $p of degree $n.\n";
