#!/usr/bin/perl -w

# Copyright 2012, 2013, 2019 Kevin Ryde

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

use Math::NumSeq::DigitCountLow;

# uncomment this to run the ### lines
#use Smart::Comments '###';

#------------------------------------------------------------------------------
# A094267 -- first diffs of count low 0-bits, starting diff i=2,i=1

MyOEIS::compare_values
  (anum => 'A094267',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::DigitCountLow->new (radix => 2, digit => 0);
     $seq->seek_to_i(1);
     my @got;
     my ($i, $prev) = $seq->next;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value - $prev;
       $prev = $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A067251 numbers with no trailing 0s in decimal

MyOEIS::compare_values
  (anum => 'A067251',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::DigitCountLow->new (radix => 10, digit => 0);
     $seq->next; # skip i=0
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 0) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
