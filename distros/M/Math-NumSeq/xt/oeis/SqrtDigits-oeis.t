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
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::SqrtDigits;


#------------------------------------------------------------------------------
# A020807 - sqrt(1/50) in decimal
# sqrt(1/50) = sqrt(50)/50
#            = 2*sqrt(50)/100
#            = sqrt(200)/100

MyOEIS::compare_values
  (anum => 'A020807',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SqrtDigits->new (sqrt => 200);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A092855 - 1-bit positions of sqrt(2)-1 in binary

MyOEIS::compare_values
  (anum => 'A092855',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SqrtDigits->new (radix => 2, sqrt => 2);
     $seq->next; # skipping 1.xxx leading 1
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value) {
         push @got, $i-1;  # -1 to count from 1 as 0.x... digit
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
