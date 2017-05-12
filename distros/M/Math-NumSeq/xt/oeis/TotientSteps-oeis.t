#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use List::Util 'max';
use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::TotientSteps;

# uncomment this to run the ### lines
#use Smart::Comments '###';

#------------------------------------------------------------------------------
# A078767 - max steps up to n

MyOEIS::compare_values
  (anum => 'A078767',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::TotientSteps->new;
     my @got;
     my $max = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next or last;
       $max = max($max,$value);
       push @got, $max;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
