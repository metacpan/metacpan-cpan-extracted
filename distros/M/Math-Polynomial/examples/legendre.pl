#!/usr/bin/perl

# Copyright (c) 2008-2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: legendre.pl 30 2009-05-19 13:48:07Z demetri $

# Math::Polynomial usage example: calculating Legendre polynomials.
#
# Legendre polynomials are a special and well-known (to scientists,
# at least) kind of orthogonal polynomial series.  This script generates
# the first few of them using a recursion formula and shows their
# orthogonality feature by calculating the related inner product of
# any two of them, yielding zero whenever two different polynomials
# are multiplied, and a positive value if a polynomial is multiplied
# by itself.

use strict;
use warnings;
use Math::Polynomial 1.000;
use Math::BigRat try => 'GMP,Pari';

my $max_degree = 5;

# adjust some printing options
Math::Polynomial->string_config({
    'fold_sign' => 1,
    'prefix'    => q{},
    'suffix'    => q{},
});

# create p[0] = 1 and p[1] = x
# using arbitrary precision rational coefficients
my $p0 = Math::Polynomial->new(Math::BigRat->new('1'));
my $p1 = $p0 << 1;
my @p = ($p0, $p1);

# recursion: (n+1)*p[n+1] = (2n+1)*x*p[n] - n*p[n-1]
foreach my $n (1..$max_degree-1) {
    $p[$n+1] = ($p[$n] * $p1 * ($n+$n+1) - $p[$n-1] * $n) / ($n + 1);
}

# print polynomials
foreach my $n (0..$#p) {
    print "P_$n = $p[$n]\n";
}

# demonstrate orthogonality
foreach my $n (0..$#p) {
    foreach my $m (0..$n) {
        my $s = ($p[$n] * $p[$m])->definite_integral(-1, 1);
        print "<P_$m, P_$n> = $s\n";
    }
}

__END__
