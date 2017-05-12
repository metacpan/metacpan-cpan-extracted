#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib/';
use Math::Symbolic qw/:all/;
use Math::Symbolic::VectorCalculus qw/:all/;

my $taylor = TaylorPolyTwoDim 'x*y', 'x', 'y', 8, 'x0', 'y0';
print $taylor, "\n\n";

print $taylor->apply_derivatives()->simplify();

