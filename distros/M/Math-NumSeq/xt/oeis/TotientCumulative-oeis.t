#!/usr/bin/perl -w

# Copyright 2012, 2019 Kevin Ryde

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
use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::TotientCumulative;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A015614 - totientcumulative - 1

MyOEIS::compare_values
  (anum => 'A015614',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::TotientCumulative->new (i_start => 1);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next or last;
       push @got, $value - 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
