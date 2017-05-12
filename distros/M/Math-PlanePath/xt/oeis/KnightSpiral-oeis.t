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

use 5.004;
use strict;
use Test;
plan tests => 8;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
#use Smart::Comments '###';

use Math::PlanePath::KnightSpiral;
use Math::PlanePath::SquareSpiral;
my $knight = Math::PlanePath::KnightSpiral->new;
my $square = Math::PlanePath::SquareSpiral->new;


#------------------------------------------------------------------------------
# A068608 - N values in square spiral order, same first step
MyOEIS::compare_values
  (anum => 'A068608',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068609 - rotate 90 degrees
MyOEIS::compare_values
  (anum => 'A068609',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ### knight: "$n  $x,$y"
       ($x, $y) = (-$y, $x);
       push @got, $square->xy_to_n ($x, $y);
       ### rotated: "$x,$y"
       ### is: "got[$#got] = $got[-1]"
     }
     return \@got;
   });

# A068610 - rotate 180 degrees
MyOEIS::compare_values
  (anum => 'A068610',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ($x, $y) = (-$x, -$y);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068611 - rotate 270 degrees
MyOEIS::compare_values
  (anum => 'A068611',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ($x, $y) = ($y, -$x);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068612 - rotate 180 degrees, opp direction, being X negated
MyOEIS::compare_values
  (anum => 'A068612',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       $x = -$x;
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068613 -
MyOEIS::compare_values
  (anum => 'A068613',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ($x, $y) = (-$y, -$x);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068614 - clockwise, Y negated
MyOEIS::compare_values
  (anum => 'A068614',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       $y = -$y;
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068615 - transpose
MyOEIS::compare_values
  (anum => 'A068615',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ($y, $x) = ($x, $y);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

exit 0;
