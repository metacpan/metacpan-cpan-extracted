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
plan tests => 7;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::Staircase;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A128918 -- N on X axis except initial 1,1

MyOEIS::compare_values
  (anum => 'A128918',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Staircase->new (n_start => 2);
     my @got = (1,1);
     for (my $x = 0; @got < $count; $x++) {
       my $n = $path->xy_to_n ($x, 0);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
