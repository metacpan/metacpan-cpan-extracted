#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';

use Math::Symbolic qw/:all/;
use Math::Symbolic::MiscAlgebra qw/:all/;

my @matrix =
  ( [ 'x*x', 'x*y', 'x*z' ], [ 'y*x', 'y*y', 'y*z' ], [ 'z*x', 'z*y', 'z*z' ],
  );

my $det = det @matrix;
print $det->simplify();

