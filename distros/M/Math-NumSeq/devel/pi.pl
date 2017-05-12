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
use Math::BigInt;
use Math::BigRat;
use Math::BigFloat;
use Math::NumSeq::Factorials;

{
  # Newton e = sum 1/n!
  print "  ";
  my $num = Math::BigInt->new(-1);
  my $den = Math::BigInt->new(1);
  my $n = 1;
  foreach (1 .. 15) {
    $num *= $n;
    $den *= $n;
    $num += 1;
    $n++;

    if ($num >= $den) {
      my $digit = int ($num / $den);
      $num %= $den;
      print "$digit";
      $num *= 10;
    }
  }
  foreach (1 .. 30) {
    $num *= $n;
    $den *= $n;
    $num += 1;
    $n++;

    $num *= 10;
    my $digit = int ($num / $den);
    $num %= $den;
    print "$digit";
  }
  print "\n";
  print exp(1),"\n";
  exit 0;
}

{
  # Newton e = sum 1/n!
  my $total = Math::BigRat->new(0);
  foreach my $n (1 .. 30) {
    my $term = Math::BigRat->new(1)
      / Math::NumSeq::Factorials->ith($n);
    print "$total\n";
    print "  ",$total->numify,"\n";
    print "  plus $term\n";
    $total += $term;
  }
  print "$total\n";
  exit 0;
}

{
  # Gosper pi
  my $total = Math::BigRat->new(3);
  foreach my $n (1 .. 30) {
    my $term = Math::BigRat->new(2)
      * $n
        * (5*$n+3)
          * Math::NumSeq::Factorials->ith(2*$n-1)
            * Math::NumSeq::Factorials->ith($n)
              / Math::NumSeq::Factorials->ith(3*$n+2)
                / Math::BigInt->new(2)**($n-1);
    print "$total\n";
    print "  ",$total->numify,"\n";
    print "  plus $term\n";
    $total += $term;
  }
  print "$total\n";
  exit 0;
}
