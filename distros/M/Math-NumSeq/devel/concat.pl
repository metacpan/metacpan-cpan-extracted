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
use Math::NumSeq::ConcatNumbers;

#use Smart::Comments;


{
  # value_to_i_estimate() by radix

  require Math::BaseCnv;
  require Math::NumSeq::ConcatNumbers;
  for my $concat_count (1,2,3,4,5,6,7,8,9,10,11) {
    print "concat count $concat_count\n";
    for my $radix (3,4,5,6,7,8,9,10,
                   11,12,
                   20,30,40,
                   100,
                   1000,
                   10000,
                   100000,
                  ) {
      my $seq = Math::NumSeq::ConcatNumbers->new (radix => $radix,
                                                  concat_count => $concat_count);
      foreach my $i (0, 1, 12, 123, 1234,
                     9, 99, 999, 9999) {
        my $value = $seq->ith($i);
        ### $value
        my $est_i = $seq->value_to_i_estimate($value);
        my $factor = (ref $est_i ? $est_i->numify : $est_i) / ($i||1);

        my $valueR = Math::BaseCnv::cnv($value,10,$radix);
        if ($factor != 1 && $i != 0) {
          printf "r=%d i=%d v=r%s   est=%.10s  factor=%.8f\n",
            $radix, $i, $valueR, $est_i, $factor;
        }
      }
    }
  }
  exit 0;
}


{
  require Math::BaseCnv;
  my $radix = 2;
  my $seq = Math::NumSeq::ConcatNumbers->new (radix => $radix);
  foreach (1 .. 256) {
    my ($i, $value) = $seq->next;
    my $est_i = $seq->value_to_i_estimate($value);
    my $factor = $est_i / ($i||1);
    my $valueR = Math::BaseCnv::cnv($value,10,$radix);
    printf "%d %d   %s[%d]  %.3f\n", $i, $est_i, $valueR,$radix,  $factor;
  }
  exit 0;
}

