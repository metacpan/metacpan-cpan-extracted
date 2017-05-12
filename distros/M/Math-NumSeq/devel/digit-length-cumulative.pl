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
use Math::NumSeq::DigitLengthCumulative;
use Math::NumSeq::SelfLengthCumulative;

#use Smart::Comments;

{
  # value_to_i_estimate()

  # my $seq = Math::NumSeq::DigitLengthCumulative->new (radix => 20);
  my $seq = Math::NumSeq::SelfLengthCumulative->new (radix => 20);
  for (my $i = 5; $i < 120000000; $i = int($i*1.5)) {
    my ($next_i, $value);
    do {
      ($next_i, $value) = $seq->next($i);
    } until ($next_i >= $i);

    my $est_i = $seq->value_to_i_estimate($value);
    my $factor = $est_i / ($i||1);
    printf "i=%d est=%.2f value=%d    f=%.3f\n", $i, $est_i, $value, $factor;
  }
  exit 0;
}

{
  # estimate k*R^k

  my $radix = 3;
  my $seq = Math::NumSeq::DigitLengthCumulative->new (radix => $radix);
  foreach my $p (0 .. 30) {
    my $i = 3 **$p;
    my $value = $seq->ith($i);
    my $est_value = $p* $radix **$p;
    my $f = $est_value/$value;
    print "$i $value $est_value  f=$f\n";
  }
  exit 0;
}

