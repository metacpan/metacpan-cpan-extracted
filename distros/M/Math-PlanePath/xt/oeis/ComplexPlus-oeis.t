#!/usr/bin/perl -w

# Copyright 2016 Kevin Ryde

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
use Test;
plan tests => 13;
use Math::BigInt try => 'GMP';

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments '###';


use Math::PlanePath::ComplexPlus;
my $path = Math::PlanePath::ComplexPlus->new;


#------------------------------------------------------------------------------
# A077950, A077870 location of ComplexMinus origin in ComplexPlus

#   3         6   7        2  3         k=3 PlusOffsetJ=1+I
#   2     4   5               0  1 
#   1         2   3        6  7    
#  Y=0    0   1               4  5 
#
#        X=0  1   2

{
  my $max_count = 12;
  my ($A077950) = MyOEIS::read_values('A077950', max_count => $max_count);
  my ($A077870) = MyOEIS::read_values('A077870', max_count => $max_count);
  ### $A077950
  ### $A077870
  unshift @$A077950, 0, 0;
  unshift @$A077870, 0, 0, 0;

  require Math::PlanePath::ComplexMinus;
  my $minus = Math::PlanePath::ComplexMinus->new;
  foreach my $k (0 .. $max_count-1) {
    my ($n_lo, $n_hi) = $path->level_to_n_range($k);
    my (%minus_points, %plus_points);
    my $dx = $A077950->[$k];
    my $dy = $A077870->[$k];
    ### dxdy: "$dx, $dy"
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $minus->n_to_xy($n);
      if ($k&1) {
        $y = -$y;
      } else {
        $x = -$x;
      }
      $x += $dx;
      $y += $dy;
      $minus_points{"$x,$y"} = 1;

      ($x,$y) = $path->n_to_xy($n);
      $plus_points{"$x,$y"} = 1;
    }
    ### %plus_points
    ### %minus_points
    my $plus_str  = join(' ',sort keys %plus_points);
    my $minus_str = join(' ',sort keys %minus_points);
    ok ($plus_str, $minus_str);
  }
}

#------------------------------------------------------------------------------
# A146559 - dX at N=2^k-1, for k>=1

MyOEIS::compare_values
  (anum => 'A146559',
   max_count => 300,  # more than 64 bits
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $k = 0; @got < $count; $k++) {
       my $n = Math::BigInt->new(2)**$k - 1;
       ### N: "$n"
       my ($dx,$dy) = $path->n_to_dxdy ($n);
       push @got, $dx;
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
