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

use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::SpiroFibonacci;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A079422 - cumulative absdiff to n^2

MyOEIS::compare_values
  (anum => 'A079422',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SpiroFibonacci->new (recurrence_type => 'absdiff');
     my @got;
     my $target = 1;
     my $target_n = 1;
     my $total = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($i >= $target) {
         $target = (++$target_n) ** 2;
         push @got, $total;
       }
       $total += $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
