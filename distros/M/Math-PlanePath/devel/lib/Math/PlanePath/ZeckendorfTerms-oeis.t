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
use List::Util 'max';
use Test;
plan tests => 46;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::PlanePath::ZeckendorfTerms;

#------------------------------------------------------------------------------
# A134561 by anti-diagonals

MyOEIS::compare_values
  (anum => 'A134561',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $path = Math::PlanePath::ZeckendorfTerms->new;
     my $diag = Math::PlanePath::Diagonals->new (direction => 'up',
                                                 x_start=>1,y_start=>1);
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
       push @got, $path->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
