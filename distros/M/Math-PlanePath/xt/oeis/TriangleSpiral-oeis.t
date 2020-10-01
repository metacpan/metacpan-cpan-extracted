#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2015, 2019, 2020 Kevin Ryde

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
use Math::BigInt;
use Test;
plan tests => 6;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use List::Util 'min', 'max';
use Math::PlanePath::TriangleSpiral;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A010054 -- turn sequence
#
# morphism
#   S -> S 1
#   1 -> 1 0
#   0 -> 0

MyOEIS::compare_values
  (anum => 'A010054',
   func => sub {
     my ($count) = @_;
     my @got = ('S');
     while (@got <= $count) {
       @got = map { $_ eq 'S' ? ('S',1)
                      : $_ eq '1' ? (1,0)
                      : $_ eq '0' ? (0)
                      : die } @got;
     }
     (shift @got) eq 'S' or die;
     $#got = $count-1;
     return \@got;
   });

#------------------------------------------------------------------------------
# A081272 -- N on Y axis

MyOEIS::compare_values
  (anum => 'A081272',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::TriangleSpiral->new;
     for (my $y = 0; @got < $count; $y -= 2) {
       push @got, $path->xy_to_n (0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A081275 -- N on slope=3 ENE

MyOEIS::compare_values
  (anum => 'A081275',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::TriangleSpiral->new (n_start => 0);
     my $x = 2;
     my $y = 0;
     while (@got < $count) {
       push @got, $path->xy_to_n ($x,$y);
       $x += 3;
       $y += 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A081589 -- N on slope=3 ENE

MyOEIS::compare_values
  (anum => 'A081589',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::TriangleSpiral->new;
     my $x = 0;
     my $y = 0;
     while (@got < $count) {
       push @got, $path->xy_to_n ($x,$y);
       $x += 3;
       $y += 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A038764 -- N on slope=2 WSW

MyOEIS::compare_values
  (anum => 'A038764',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::TriangleSpiral->new;
     my $x = 0;
     my $y = 0;
     while (@got < $count) {
       push @got, $path->xy_to_n ($x,$y);
       $x += -3;
       $y += -1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A063177 -- a(n) is sum of existing numbers in row of a(n-1)

MyOEIS::compare_values
  (anum => 'A063177',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::TriangleSpiral->new;
     my @got;
     my %plotted;
     $plotted{0,0} = Math::BigInt->new(1);
     my $xmin = 0;
     my $ymin = 0;
     my $xmax = 0;
     my $ymax = 0;
     push @got, 1;

     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($prev_x, $prev_y) = $path->n_to_xy ($n-1);
       my ($x, $y) = $path->n_to_xy ($n);
       ### at: "$x,$y  prev $prev_x,$prev_y"

       my $total = 0;
       if ($x > $prev_x) {
         ### forward diagonal ...
         foreach my $y ($ymin .. $ymax) {
           my $delta = $y - $prev_y;
           my $x = $prev_x + $delta;
           $total += $plotted{$x,$y} || 0;
         }
       } elsif ($y > $prev_y) {
         ### row: "$xmin .. $xmax at y=$prev_y"
         foreach my $x ($xmin .. $xmax) {
           $total += $plotted{$x,$prev_y} || 0;
         }
       } else {
         ### opp diagonal ...
         foreach my $y ($ymin .. $ymax) {
           my $delta = $y - $prev_y;
           my $x = $prev_x - $delta;
           $total += $plotted{$x,$y} || 0;
         }
       }
       ### total: "$total"

       $plotted{$x,$y} = $total;
       $xmin = min($xmin,$x);
       $xmax = max($xmax,$x);
       $ymin = min($ymin,$y);
       $ymax = max($ymax,$y);
       push @got, $total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
