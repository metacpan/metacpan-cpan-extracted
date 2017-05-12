#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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
use Math::PlanePath::MultipleRings;
use Test;
plan tests => 11;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A090915 -- permutation X,-Y mirror across X axis

MyOEIS::compare_values
  (anum => 'A090915',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::MultipleRings->new(step=>8);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x,$y) = ($x,-$y);
       push @got, $path->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002024 - n repeated n times, is step=1 Radius+1

MyOEIS::compare_values
  (anum => 'A002024',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::MultipleRings->new(step=>1);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, $path->n_to_radius($n) + 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
