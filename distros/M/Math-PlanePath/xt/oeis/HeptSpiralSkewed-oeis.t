#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2015 Kevin Ryde

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
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use List::Util 'min', 'max';
use Math::PlanePath::HeptSpiralSkewed;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A140065 - N on Y axis

MyOEIS::compare_values
  (anum => 'A140065',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::HeptSpiralSkewed->new;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       my $n = $path->xy_to_n(0,$y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
