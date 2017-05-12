#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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

# "type-2" skewed to the right
#
#                               4  
#                             / |  
#   14  4                    5  3  ...     skew="right"
#   13  3  5               /    |   |
#   12  2  1  6           6  1--2  12
#   11 10  9  8  7      /           |
#                      7--8--9--10-11

# "type-3" diagonal first                 29
#                     16 15 14 13-12-11 28
#                                   /  
#    7                17  4--3--2 10 27    skew="up"
#    6  8                 |   /   /
#    5  1  9          18  5  1  9 26
#    4  3  2 10           |    /
#   15 14 13 12 11    19  6  8 25
#                         | /
#                     20  7 24
#                          /
#                     21 23
#                      |/ 
#                     22


# TriangleSpiralSkewed
#
#   4 
#   |\ 
#   5  3   ...
#   |   \   \
#   6  1--2 12 
#   |         \ 
#   7--8--9-10-11 
#                 


use 5.004;
use strict;
use Test;
plan tests => 14;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use List::Util 'min', 'max';
use Math::PlanePath::TriangleSpiralSkewed;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A214230 -- sum of 8 neighbouring N, skew="left"
MyOEIS::compare_values
  (anum => 'A214230',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::TriangleSpiralSkewed->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, path_n_sum_surround8($path,$n);
     }
     return \@got;
   });

# A214251 -- sum of 8 neighbouring N, "type 2" skew="right"
MyOEIS::compare_values
  (anum => 'A214251',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::TriangleSpiralSkewed->new (skew => 'right');
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, path_n_sum_surround8($path,$n);
     }
     return \@got;
   });

# A214252 -- sum of 8 neighbouring N, "type 3" skew="up"
MyOEIS::compare_values
  (anum => 'A214252',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::TriangleSpiralSkewed->new (skew => 'up');
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, path_n_sum_surround8($path,$n);
     }
     return \@got;
   });

sub path_n_sum_surround8 {
  my ($path, $n) = @_;
  my ($x,$y) = $path->n_to_xy ($n);
  return ($path->xy_to_n($x+1,$y)
          + $path->xy_to_n($x-1,$y)
          + $path->xy_to_n($x,$y+1)
          + $path->xy_to_n($x,$y-1)
          + $path->xy_to_n($x+1,$y+1)
          + $path->xy_to_n($x-1,$y-1)
          + $path->xy_to_n($x-1,$y+1)
          + $path->xy_to_n($x+1,$y-1));
}

#------------------------------------------------------------------------------
# A214231 -- sum of 4 neighbouring N

MyOEIS::compare_values
  (anum => 'A214231',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::TriangleSpiralSkewed->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, path_n_sum_surround4($path,$n);
     }
     return \@got;
   });

sub path_n_sum_surround4 {
  my ($path, $n) = @_;
  my ($x,$y) = $path->n_to_xy ($n);
  return ($path->xy_to_n($x+1,$y)
          + $path->xy_to_n($x-1,$y)
          + $path->xy_to_n($x,$y+1)
          + $path->xy_to_n($x,$y-1)
         );
}

#------------------------------------------------------------------------------
# A081272 -- N on slope=2 SSE

MyOEIS::compare_values
  (anum => 'A081272',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::TriangleSpiralSkewed->new;
     my $x = 0;
     my $y = 0;
     while (@got < $count) {
       push @got, $path->xy_to_n ($x,$y);
       $x += 1;
       $y -= 2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A081275 -- N on X=Y+1 diagonal

MyOEIS::compare_values
  (anum => 'A081275',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::TriangleSpiralSkewed->new (n_start => 0);
     for (my $y = 0; @got < $count; $y++) {
       my $x = $y + 1;
       push @got, $path->xy_to_n ($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A217010 -- permutation N values by SquareSpiral order

MyOEIS::compare_values
  (anum => 'A217010',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::SquareSpiral;
     my $tsp = Math::PlanePath::TriangleSpiralSkewed->new;
     my $square = Math::PlanePath::SquareSpiral->new;
     my @got;
     for (my $n = $square->n_start; @got < $count; $n++) {
       my ($x, $y) = $square->n_to_xy ($n);
       push @got, $tsp->xy_to_n ($x,$y);
     }
     return \@got;
   });

# A217291 -- inverse, TriangleSpiralSkewed X,Y order, SquareSpiral N
MyOEIS::compare_values
  (anum => 'A217291',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::SquareSpiral;
     my $tsp = Math::PlanePath::TriangleSpiralSkewed->new;
     my $square = Math::PlanePath::SquareSpiral->new;
     my @got;
     for (my $n = $tsp->n_start; @got < $count; $n++) {
       my ($x, $y) = $tsp->n_to_xy ($n);
       push @got, $square->xy_to_n ($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A217011 -- permutation N values by SquareSpiral order, type-2, skew="right"
# SquareSpiral North first then clockwise
# Triangle West first then clockwise
# rotate 90 degrees to compensate

MyOEIS::compare_values
  (anum => 'A217011',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::SquareSpiral;
     my $tsp = Math::PlanePath::TriangleSpiralSkewed->new (skew => 'right');
     my $square = Math::PlanePath::SquareSpiral->new;
     my @got;
     for (my $n = $square->n_start; @got < $count; $n++) {
       my ($x, $y) = $square->n_to_xy ($n);
       ($x,$y) = (-$y,$x);  # rotate +90
       push @got, $tsp->xy_to_n ($x,$y);
     }
     return \@got;
   });

# A217292 -- inverse, TriangleSpiralSkewed X,Y order, SquareSpiral N
MyOEIS::compare_values
  (anum => 'A217292',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::SquareSpiral;
     my $tsp = Math::PlanePath::TriangleSpiralSkewed->new (skew => 'right');
     my $square = Math::PlanePath::SquareSpiral->new;
     my @got;
     for (my $n = $tsp->n_start; @got < $count; $n++) {
       my ($x, $y) = $tsp->n_to_xy ($n);
       ($x,$y) = ($y,-$x);  # rotate -90
       push @got, $square->xy_to_n ($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A217012 -- permutation N values by SquareSpiral order, type-3, skew="up"
# SquareSpiral North first then clockwise
# Triangle South-East first then clockwise
# rotate 90 degrees to compensate

MyOEIS::compare_values
  (anum => 'A217012',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::SquareSpiral;
     my $tsp = Math::PlanePath::TriangleSpiralSkewed->new (skew => 'up');
     my $square = Math::PlanePath::SquareSpiral->new;
     my @got;
     for (my $n = $square->n_start; @got < $count; $n++) {
       my ($x, $y) = $square->n_to_xy ($n);
       ($x,$y) = ($y,-$x);  # rotate -90
       push @got, $tsp->xy_to_n ($x,$y);
     }
     return \@got;
   });

# A217293 -- inverse, TriangleSpiralSkewed X,Y order, SquareSpiral N
MyOEIS::compare_values
  (anum => 'A217293',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::SquareSpiral;
     my $tsp = Math::PlanePath::TriangleSpiralSkewed->new (skew => 'up');
     my $square = Math::PlanePath::SquareSpiral->new;
     my @got;
     for (my $n = $tsp->n_start; @got < $count; $n++) {
       my ($x, $y) = $tsp->n_to_xy ($n);
       ($x,$y) = (-$y,$x);  # rotate +90
       push @got, $square->xy_to_n ($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A217012 -- permutation N values by SquareSpiral order
# SquareSpiral North first then clockwise
# Triangle South-East first then clockwise
# rotate 180 degrees to compensate to skew="down"

MyOEIS::compare_values
  (anum => q{A217012},
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::SquareSpiral;
     my $tsp = Math::PlanePath::TriangleSpiralSkewed->new (skew => 'down');
     my $square = Math::PlanePath::SquareSpiral->new;
     my @got;
     for (my $n = $square->n_start; @got < $count; $n++) {
       my ($x, $y) = $square->n_to_xy ($n);
       ($x,$y) = (-$x,-$y);  # rotate 180
       push @got, $tsp->xy_to_n ($x,$y);
     }
     return \@got;
   });

# A217293 -- inverse, TriangleSpiralSkewed X,Y order, SquareSpiral N
MyOEIS::compare_values
  (anum => q{A217293},
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::SquareSpiral;
     my $tsp = Math::PlanePath::TriangleSpiralSkewed->new (skew => 'down');
     my $square = Math::PlanePath::SquareSpiral->new;
     my @got;
     for (my $n = $tsp->n_start; @got < $count; $n++) {
       my ($x, $y) = $tsp->n_to_xy ($n);
       ($x,$y) = (-$x,-$y);  # rotate 180
       push @got, $square->xy_to_n ($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
