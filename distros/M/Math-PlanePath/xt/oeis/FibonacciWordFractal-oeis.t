#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2018 Kevin Ryde

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
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::FibonacciWordFractal;


#------------------------------------------------------------------------------
# A003849 - Fibonacci word 0/1, 0=straight,1=left or right

MyOEIS::compare_values
  (anum => 'A003849',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new
       (planepath => 'FibonacciWordFractal',
        turn_type => 'LSR');   # turn_type=Straight
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value == 0 ? 1 : 0;
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
