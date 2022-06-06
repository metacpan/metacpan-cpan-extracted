#!/usr/bin/perl -w

# Copyright 2012, 2020 Kevin Ryde

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

use Math::NumSeq::PrimeIndexPrimes;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A175247 - primes at non-composite
# meaning primes at prime index, but including Prime(1)

MyOEIS::compare_values
  (anum => 'A175247',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::PrimeIndexPrimes->new;
     my @got = (2);  # Prime(1)
     while (@got < $count) {
       my ($i, $prime) = $seq->next;
       push @got, $prime;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
