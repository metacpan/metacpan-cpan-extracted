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

use Math::NumSeq::ProthNumbers;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# A080076 Proth number primes
#
# but Proth N is a prime iff exists a s.t. a^((N-1)/2) = 1 mod N

MyOEIS::compare_values
  (anum => 'A080076',
   max_value => 0xFFFF_FFFF,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $seq = Math::NumSeq::ProthNumbers->new;
     my $primes = Math::NumSeq::Primes->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($primes->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

# fixup => sub {
#   my ($bvalues) = @_;
#   while ($bvalues->[0] < 0xFFFF_000) {
#     shift @$bvalues;
#   }
# },
#   while (my ($i, $value) = $seq->next) {
#     last if $value >= 0xF000_0000;
#   }

#------------------------------------------------------------------------------
exit 0;
