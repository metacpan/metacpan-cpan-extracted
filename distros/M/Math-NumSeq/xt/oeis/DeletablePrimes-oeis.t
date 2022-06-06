#!/usr/bin/perl -w

# Copyright 2012, 2018, 2020 Kevin Ryde

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
plan tests => 11;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::DeletablePrimes;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A096235 to A096245
# number of deletable primes of n digits

foreach my $num (96235 .. 96245) {
  my $anum = sprintf 'A%06d', $num;
  my $radix = $num - 96235 + 2; # A096235 binary
  my $trunc = 1;
  {
    my $pow = $radix;
    while ($pow < 100000) {
      $pow *= $radix;
      $trunc++;
    }
  }

  MyOEIS::compare_values
      (anum => $anum,
       max_count => $trunc,
       func => sub {
         my ($count) = @_;
         my $seq  = Math::NumSeq::DeletablePrimes->new (radix => $radix);
         my @got;
         my $pow = $radix;
         my $deletables = 0;
         while (@got < $count) {
           my ($i, $value) = $seq->next;
           if ($value >= $pow) {
             push @got, $deletables;
             $deletables = 0;
             $pow *= $radix;
           }
           $deletables++;
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
exit 0;
