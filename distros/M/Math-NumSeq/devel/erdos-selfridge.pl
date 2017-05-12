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
use List::MoreUtils;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use Math::Factor::XS 0.39 'prime_factors'; # version 0.39 for prime_factors()

{
  # Erdos-Selfridge breakdowns

  require Math::NumSeq::Primes;
  my $seq = Math::NumSeq::Primes->new;
  foreach (1 .. 1000) {
    my ($i, $p) = $seq->next;
    breakdown($p,0);
  }
  exit 0;

  sub breakdown {
    my ($p, $depth) = @_;
    my @p = prime_factors($p+1);
    @p = List::MoreUtils::uniq(@p);
    if (($p[0]||0) == 2) { shift @p; }
    if (($p[0]||0) == 3) { shift @p; }
    printf "%*s%d = %s\n",
      $depth, '', $p, join(', ',@p);
    foreach (@p) {
      breakdown($_,$depth+2);
    }
  }
}

{
  # Erdos-Selfridge
  # 1+ 2, 3, 5, 7, 11, 17, 23, 31, 47, 53, 71, 107, 127, 191, 383, 431, 647,
  # 2+ 13, 19, 29, 41, 43, 59, 61, 67, 79, 83, 89, 97, 101, 109, 131, 137,
  # 3+ 37, 103, 113, 151, 157, 163, 173, 181, 193, 227, 233, 257, 277, 311,
  # 4+ 73, 313, 443, 617, 661, 673, 677, 691, 739, 757, 823, 887, 907, 941,
  my @es_class = (undef, undef, 0, 0);
  sub es_class {
    my ($prime) = @_;
    return ($es_class[$prime]
            //= max (map { es_class($_)+1 } prime_factors($prime+1)));
  }

  my @by_class;
  my $seq = Math::NumSeq::Primes->new;
  foreach (1 .. 50) {
    my ($i, $value) = $seq->next;
    my $es_class = es_class($value);
    print "$value  $es_class\n";
    push @{$by_class[$es_class]}, $value;
  }

  foreach my $i (keys @by_class) {
    my $aref = $by_class[$i] || next;
    print "$i  ",join(',',@$aref),"\n";
  }

  exit 0;
}
