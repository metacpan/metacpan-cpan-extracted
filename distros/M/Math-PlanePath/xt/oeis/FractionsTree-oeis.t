#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2015 Kevin Ryde

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
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::FractionsTree;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A093873 -- Kepler numerators

# {
#   my $path  = Math::PlanePath::FractionsTree->new (tree_type => 'Kepler');
#   my $anum = 'A093873';
#   my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
#   my @got;
#   if ($bvalues) {
#     foreach my $n (1 .. @$bvalues) {
#       my ($x, $y) = $path->n_to_xy (int(($n+1)/2));
#       push @got, $x;
#     }
#   }
#   skip (! $bvalues,
#         numeq_array(\@got, $bvalues),
#         1, "$anum -- Kepler tree numerators");
# }
#
# sub sans_high_bit {
#   my ($n) = @_;
#   return $n ^ high_bit($n);
# }
# sub high_bit {
#   my ($n) = @_;
#   my $bit;
#   for ($bit = 1; $bit <= $n; $bit <<= 1) {
#     $bit <<= 1;
#   }
#   return $bit >> 1;
# }

#------------------------------------------------------------------------------
# A093875 -- Kepler denominators

# {
#   my $path  = Math::PlanePath::FractionsTree->new (tree_type => 'Kepler');
#   my $anum = 'A093875';
#   my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
#   my @got;
#   if ($bvalues) {
#     foreach my $n (2 .. @$bvalues) {
#       my ($x, $y) = $path->n_to_xy (int($n/2));
#       push @got, $y;
#     }
#   }
#   skip (! $bvalues,
#         numeq_array(\@got, $bvalues),
#         1, "$anum -- Kepler tree denominators");
# }


#------------------------------------------------------------------------------
# A086593 -- Kepler half-tree denominators, every second value

MyOEIS::compare_values
  (anum => 'A086593',
   name => 'Kepler half-tree denominators every second value',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path  = Math::PlanePath::FractionsTree->new (tree_type => 'Kepler');
     for (my $n = $path->n_start; @got < $count; $n += 2) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $y;
     }
     return \@got;
   });

# is also the sum X+Y, skipping initial 2
MyOEIS::compare_values
  (anum => q{A086593},
   name => 'as sum X+Y',
   func => sub {
     my ($count) = @_;
     my $path  = Math::PlanePath::FractionsTree->new (tree_type => 'Kepler');
     my @got = (2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $x+$y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
