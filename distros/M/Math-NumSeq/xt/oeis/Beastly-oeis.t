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

use Math::NumSeq::Beastly;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A131645 beastly primes (decimal)

MyOEIS::compare_values
  (anum => 'A131645',
   max_value => 1_000_000,
   func => sub {
     my ($count) = @_;
     my $beastly = Math::NumSeq::Beastly->new;
     require Math::NumSeq::Primes;
     my $primes  = Math::NumSeq::Primes->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $primes->next;
       if ($beastly->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
