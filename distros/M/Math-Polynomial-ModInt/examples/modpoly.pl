#!/usr/bin/env perl

# Copyright (c) 2019-2022 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Math::Polynomial::ModInt example: create a polynomial from its index

use strict;
use warnings;
use Math::Polynomial::ModInt;

if (2 != @ARGV || grep {!/^[0-9]+\z/} @ARGV) {
    die "usage: modpoly index modulus\n";
}
my ($index, $modulus) = @ARGV;

my $CONFIG = {
    prefix    => q[],
    suffix    => qq[ (mod $modulus)\n],
    fold_sign => 1,
    times     => q[*],
};

my $poly = Math::Polynomial::ModInt->from_index($index, $modulus);

print $poly->centerlift->as_string($CONFIG);
