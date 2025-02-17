#!/usr/bin/perl -w

# Copyright 2013, 2015, 2018, 2019, 2020, 2021 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Math::BigInt try => 'GMP';
use Math::PlanePath::AlternatePaperMidpoint;
use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;


#------------------------------------------------------------------------------
# A334576 -- X coordinate
# A334577 -- Y coordinate
# checked through PlanePathCoord

# my(g=OEIS_bfile_gf("A334576")); x(n) = polcoeff(g,n);
# my(g=OEIS_bfile_gf("A334577")); y(n) = polcoeff(g,n);
# plothraw(vector(3^7,n,n--; x(n)), \
#          vector(3^7,n,n--; y(n)), 1+8+16+32)


#------------------------------------------------------------------------------
# A016116 -- X/2 at N=2^k, starting k=1, being 2^floor(k/2)

MyOEIS::compare_values
  (anum => 'A016116',
   max_count => 200,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::AlternatePaperMidpoint->new;
     my @got;
     for (my $n = Math::BigInt->new(2); @got < $count; $n *= 2) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x/2;
     }
     return \@got;
   });


#------------------------------------------------------------------------------

exit 0;
