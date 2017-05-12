#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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
plan tests => 29;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Factorials;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A205509 Hamming distance between (n-1)! and n!

MyOEIS::compare_values
  (anum => 'A205509',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitCount;
     my $cnt = Math::NumSeq::DigitCount->new (radix => 2);
     my $seq = Math::NumSeq::Factorials->new;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $cnt->ith($seq->ith($i) ^ $seq->ith($i+1));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
