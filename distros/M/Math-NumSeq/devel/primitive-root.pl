#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use POSIX;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use Math::Factor::XS 0.39 'prime_factors'; # version 0.39 for prime_factors()
use List::Util 'max','min';
use List::MoreUtils 'uniq';

#use Smart::Comments;

{
  # value_to_i_estimate()
  require Math::NumSeq::Primes;
  my $primes = Math::NumSeq::Primes->new;

  require Math::NumSeq::LeastPrimitiveRoot;
  my $seq = Math::NumSeq::LeastPrimitiveRoot->new;

  for my $i (1 .. 10000) {
    next if $primes->pred($i);
    my $root = $seq->ith($i);
    if ($root != 2) {
      print "$i $root\n";
      foreach my $p (uniq(prime_factors($i))) {
        print "  $p ",$seq->ith($p),"\n";
      }
    }
  }
  exit 0;
}


