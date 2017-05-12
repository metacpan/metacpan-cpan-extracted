#!/usr/bin/perl
# Copyright (c) 2013 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: ramanujan.pl 3 2013-06-01 20:56:06Z demetri $

# This example verifies the Ramanujan 6-10-8 identity in a form written
# with bivariate polynomials.  This was taken from:
# Piezas, Tito III. "Ramanujan 6-10-8 Identity." From MathWorld --
# A Wolfram Web Resource, created by Eric W. Weisstein.
# http://mathworld.wolfram.com/Ramanujan6-10-8Identity.html
# (retrieved on May 31, 2013)

use strict;
use warnings;
use Math::Polynomial::Multivariate;

my $c1  = Math::Polynomial::Multivariate->const( 1);
my $c45 = Math::Polynomial::Multivariate->const(45);
my $c64 = Math::Polynomial::Multivariate->const(64);
my $x   = $c1->var('x');
my $y   = $c1->var('y');
my $xy  = $x * $y;

sub f {
    my ($exp) = @_;
    return
        + ($c1 +  $x +  $y) ** $exp
        + ( $x +  $y + $xy) ** $exp
        - ( $y + $xy + $c1) ** $exp
        - ($xy + $c1 +  $x) ** $exp
        + ($c1 - $xy      ) ** $exp
        - ( $x -  $y      ) ** $exp;
}

my $f2     = f( 2);
my $f4     = f( 4);
my $f6     = f( 6);
my $f8     = f( 8);
my $f10    = f(10);
my $d      = $c64 * $f6 * $f10 - $c45 * $f8**2;

print
    "f2                  = $f2\n",
    "f4                  = $f4\n",
    "64*f6*f10 - 45*f8^2 = $d\n";

__END__
