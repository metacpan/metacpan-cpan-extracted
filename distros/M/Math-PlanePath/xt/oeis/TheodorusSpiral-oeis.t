#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
plan tests => 8;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::TheodorusSpiral;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A172164 -- differences of loop lengths

MyOEIS::compare_values
  (anum => 'A172164',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::TheodorusSpiral->new;
     my $n = $path->n_start + 1;
     my ($prev_x, $prev_y) = $path->n_to_xy ($n);
     my $prev_n = 1;
     my $prev_looplen = 0;
     my $first = 1;
     for ($n++; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       if ($y > 0 && $prev_y < 0) {
         my $looplen = $n-$prev_n;
         if ($first) {
           $first = 0;
         } else {
           push @got, $looplen - $prev_looplen;
         }
         $prev_n = $n;
         $prev_looplen = $looplen;
       }
       ($prev_x, $prev_y) = ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A137515 -- right triangles in n turns
# 16, 53, 109, 185, 280, 395, 531, 685, 860, 1054, 1268, 1502, 1756,

MyOEIS::compare_values
  (anum => 'A137515',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::TheodorusSpiral->new;
     my $n = $path->n_start + 1;
     my ($prev_x, $prev_y) = $path->n_to_xy ($n);
     for ($n++; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       if ($y > 0 && $prev_y < 0) {
         push @got, $n-2;
       }
       ($prev_x, $prev_y) = ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A072895 -- points to complete n revolutions
# 17, 54, 110, 186, 281, 396, 532, 686, 861, 1055, 1269, 1503, 1757,

MyOEIS::compare_values
  (anum => 'A072895',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::TheodorusSpiral->new;
     my $n = $path->n_start + 2;
     my ($prev_x, $prev_y) = $path->n_to_xy ($n);
     for ($n++; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       if ($y >= 0 && $prev_y <= 0) {
         push @got, $n-1;
       }
       ($prev_x, $prev_y) = ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
