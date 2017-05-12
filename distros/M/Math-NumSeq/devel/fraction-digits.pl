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
use Math::NumSeq::FractionDigits;

{
  # ith() modulo powering

  my $num = 5;
  my $den = 29000000000;
  my $radix = 10;
  my $seq = Math::NumSeq::FractionDigits->new (fraction => "$num/$den");

  foreach (1 .. 20000) {
    my ($i, $value) = $seq->next;
    my $ith_value = $seq->ith($i);
    if ($value != $ith_value) {
      printf "%d %d %d\n", $i, $value, $num;
    }
  }
  exit 0;
}


{
  my $radix = 10;
  require Math::BigInt;
  $radix = Math::BigInt->new($radix);
  $radix->copy->bmodpow(10,7);
  print "$radix\n";
  exit 0;
}

