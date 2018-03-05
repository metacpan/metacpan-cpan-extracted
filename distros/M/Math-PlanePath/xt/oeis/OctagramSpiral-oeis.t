#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018 Kevin Ryde

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

use Math::PlanePath::OctagramSpiral;


#------------------------------------------------------------------------------
# A125201 -- N on X axis, from X=1 onwards, 18-gonals + 1

MyOEIS::compare_values
  (anum => 'A125201',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::OctagramSpiral->new;
     my @got;
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
