#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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

#use Smart::Comments;


{
  # value_to_i_estimate()
  require Math::NumSeq::PrimeIndexPrimes;

  my @f;
  foreach my $pip_type ('minimum','exact') {
    foreach my $level (2 .. 5) {
      print "level $level, $pip_type\n";

      my $seq = Math::NumSeq::PrimeIndexPrimes->new
        (level => $level,
         pip_type => $pip_type);

      my $target = 2;
      for (;;) {
        my ($i, $value) = $seq->next;
        if ($value >= 1000_000) {
          last;
        }
        if ($i >= $target) {
          $target *= 1.5;

          require Math::BigInt;
          $value = Math::BigInt->new($value);

          # require Math::BigRat;
          # $value = Math::BigRat->new($value);

          # require Math::BigFloat;
          # $value = Math::BigFloat->new($value);

          my $est_i = $seq->value_to_i_estimate($value);
          my $factor = (ref $est_i ? $est_i->numify : $est_i) / $i;
          printf "%d %d   %.10s  factor=%.3f\n",
            $i, $est_i, $value, $factor;

          $f[$level] = $factor;
        }
      }

      print "f ratio ",$f[$level]/($f[$level-1]||1),"\n";
    }
  }
  exit 0;
}

{
  # values_min
  require Math::NumSeq::PrimeIndexPrimes;
  foreach my $level_type ('minimum', 'exact') {
    foreach my $level (0 .. 10) {
      my $seq = Math::NumSeq::PrimeIndexPrimes->new
        (level      => $level,
         level_type => $level_type);
      my $values_min = $seq->values_min;
      my ($i, $value) = $seq->next;
      my $diff = ($value == $values_min ? '' : '   ***');
      print "$level $values_min $value$diff\n";
    }
  }
  exit 0;
}
