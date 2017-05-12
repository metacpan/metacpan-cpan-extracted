#!/usr/bin/perl -w

# Copyright 2013, 2015 Kevin Ryde

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
use Math::PlanePath::AlternatePaperMidpoint;
use Test;
plan tests => 11;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;


# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A016116 -- X/2 at N=2^k, starting k=1, being 2^floor(k/2)

require Math::NumSeq::PlanePathN;
my $bigclass = Math::NumSeq::PlanePathN::_bigint();

MyOEIS::compare_values
  (anum => 'A016116',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::AlternatePaperMidpoint->new;
     my @got;
     for (my $n = $bigclass->new(2); @got < $count; $n *= 2) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x/2;
     }
     return \@got;
   });


#------------------------------------------------------------------------------

exit 0;
