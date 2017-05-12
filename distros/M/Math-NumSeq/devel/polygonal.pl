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

#use Smart::Comments;


{
  # value_to_i_estimate() by polygonal

  require Math::NumSeq::Polygonal;
  for my $polygonal (3,4,5,6,7,8,9,10,
                     11,12,
                     20,30,40,
                     100,
                     1000,
                     10000,
                     100000,
                     1000000,
                     10000000,
                     100000000,
                     1000000000,
                    ) {
    my $seq = Math::NumSeq::Polygonal->new (polygonal => $polygonal);
    my $i = 100000;
    my $value = $seq->ith($i);
    ### $value
    my $est_i = $seq->value_to_i_estimate($value);
    my $factor = (ref $est_i ? $est_i->numify : $est_i) / $i;
    printf "%d %d   %.10s  factor=%.8f\n",
      $polygonal, $value, $est_i, $factor;
  }
  exit 0;
}

