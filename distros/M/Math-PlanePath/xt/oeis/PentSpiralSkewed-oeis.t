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
plan tests => 3;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::PentSpiralSkewed;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A140066 - N on Y axis

MyOEIS::compare_values
  (anum => 'A140066',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PentSpiralSkewed->new;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A147875 - N on Y negative axis, n_start=0, second heptagonals

MyOEIS::compare_values
  (anum => 'A147875',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PentSpiralSkewed->new (n_start => 0);
     my @got;
     for (my $y = 0; @got < $count; $y--) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A134238 - N on Y negative axis

MyOEIS::compare_values
  (anum => 'A134238',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PentSpiralSkewed->new;
     my @got;
     for (my $y = 0; @got < $count; $y--) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
