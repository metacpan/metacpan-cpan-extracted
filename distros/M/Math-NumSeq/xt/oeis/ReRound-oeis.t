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

use Math::NumSeq::ReRound;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A113749 k multiples

# 1, 1, 1, 1, 1
# 1, 2, 4, 6, 10
# 1, 3, 7, 13,
# 1, 4, 10, 18,

MyOEIS::compare_values
  (anum => 'A113749',
   func => sub {
     my ($count) = @_;
     my @got;
     my $i = 0;
     my $j = 0;
     while (@got < $count) {
       ### at: "i=$i j=$j"
       if ($j == 0) {
         push @got, 1;
       } else {
         my $seq  = Math::NumSeq::ReRound->new (extra_multiples => $j-1);
         push @got, $seq->ith($i+1);
       }
       $i++;  # by diagonals
       $j--;
       if ($j < 0) {
         $j = $i;
         $i = 0;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
