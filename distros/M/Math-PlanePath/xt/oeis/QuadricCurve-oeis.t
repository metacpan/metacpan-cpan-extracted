#!/usr/bin/perl -w

# Copyright 2013, 2018, 2019 Kevin Ryde

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
use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::QuadricCurve;


#------------------------------------------------------------------------------
# A133851 -- Y at N=2^k is 2^(k/4) when k=0mod4, starting 

MyOEIS::compare_values
  (anum => 'A133851',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::QuadricCurve->new;
     my @got;
     for (my $n = Math::BigInt->new(2); @got < $count; $n *= 2) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
