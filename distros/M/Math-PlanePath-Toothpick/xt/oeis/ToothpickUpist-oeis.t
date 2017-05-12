#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


use 5.004;
use strict;
use Test;
plan tests => 7;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::PlanePath::ToothpickUpist;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# A175098 grid points covered by length=2

MyOEIS::compare_values
  (anum => 'A175098',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickUpist->new;
     my @got = (0);
     my %seen;
     my $n = $path->n_start;
     for (my $depth = 0; @got < $count; $depth++) {
       my $n_end = $path->tree_depth_to_n_end($depth);
       for ( ; $n <= $n_end; $n++) {
         my ($x,$y) = $path->n_to_xy($n);
         $seen{"$x,$y"} = 1;

         if ($depth & 1) {
           $seen{($x+1).",$y"} = 1;
           $seen{($x-1).",$y"} = 1;
         } else {
           $seen{"$x,".($y+1)} = 1;
           $seen{"$x,".($y-1)} = 1;
         }
       }
       push @got, scalar(keys %seen);
     }
     return \@got;
   });

# grid(d) = cells to depth < d
# grid(0) = 0
# grid(1) = 3
# grid(2) = 5
# grid(4) = 5 + 2*5 - 2 - 1 = 12     mid touch, join overlap
# grid(8) = 12 + 2*12 - 2-2-1 = 31   mid, join, down dup
# grid(16) = 3*31 - 5 = 88
# grid(pow+rem) = grid(pow) + 2*grid(rem)
#                 - some
#
# 3*x-5  x=3*y-5
# 3*(3*y-5)-5
#   = 9*y - 3*5 - 5

use Math::PlanePath::Base::Digits 'round_down_pow';

sub A175098_func {
  my ($depth) = @_;
  ### A175098_func(): $depth
  if ($depth <= 0) { return 0; }
  if ($depth == 1) { return 3; }
  if ($depth == 2) { return 5; }

  # split to  pow=2^k  1 <= rem <= 2^k
  my ($pow,$exp) = round_down_pow($depth-1,2);
  my $rem = $depth - $pow;

  return (A175098_func($pow)
          + 2 * A175098_func($rem)
          - 2                          # join
          - ($rem >= 3 ? 2 : 0)        # down dup
          - ($rem == $pow ? 1 : 0)     # middle touch
         );
}

# 0,
#  3,
#  5, 9,
#  12, 16, 20, 26,
#  31, 35, 39, 45, 51, 59, 67, 79,
#  88,92,96,102,108,116,124,136,146,154,162,174,186,202,218,242,
# 259,263,267,273,279,287,295,307,317,325,333,345,357,373,389,413,431,439,447,459,471,487,503,527,547

MyOEIS::compare_values
  (anum => 'A175098',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, A175098_func($depth);
     }
     return \@got;
   });

{
  my $path = Math::PlanePath::ToothpickUpist->new;
  my @got;
  my %seen;
  my $n = $path->n_start;
  for (my $depth = 0; $depth < 1024; $depth++) {
    my $next_n = $path->tree_depth_to_n($depth);
    for ( ; $n < $next_n; $n++) {
      my ($x,$y) = $path->n_to_xy($n);
      $seen{"$x,$y"} = 1;

      if ($depth & 1) {
        $seen{"$x,".($y+1)} = 1;
        $seen{"$x,".($y-1)} = 1;
      } else {
        $seen{($x+1).",$y"} = 1;
        $seen{($x-1).",$y"} = 1;
      }
    }
    my $path_total = scalar(keys %seen);
    my $func_total = A175098_func($depth);
    if ($path_total != $func_total) {
      die "oops depth=$depth path=$path_total func=$func_total";
    }
  }
}

#------------------------------------------------------------------------------
# A160745 - added*3

MyOEIS::compare_values
  (anum => 'A160745',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickUpist->new;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       my $added = ($path->tree_depth_to_n($depth+1)
                    - $path->tree_depth_to_n($depth));
       push @got, 3 * $added;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A160742 - total*2

MyOEIS::compare_values
  (anum => 'A160742',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickUpist->new;
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, 2 * $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A160744 - total*3

MyOEIS::compare_values
  (anum => 'A160744',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickUpist->new;
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, 3 * $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A160746 - total*4

MyOEIS::compare_values
  (anum => 'A160746',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickUpist->new;
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, 4 * $path->tree_depth_to_n($depth);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A151566 - total cells leftist

MyOEIS::compare_values
  (anum => 'A151566',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickUpist->new;
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A060632,A151565 - cells added leftist

MyOEIS::compare_values
  (anum => 'A060632',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickUpist->new;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       my $added = ($path->tree_depth_to_n($depth+1)
                    - $path->tree_depth_to_n($depth));
       push @got, $added;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A151565',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickUpist->new;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       my $added = ($path->tree_depth_to_n($depth+1)
                    - $path->tree_depth_to_n($depth));
       push @got, $added;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
