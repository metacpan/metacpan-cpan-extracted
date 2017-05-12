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
use Math::NumSeq::Primorials;

use Smart::Comments;

{
  # value_to_i_estimate()

  my $seq = Math::NumSeq::Primorials->new;
  my $prev_value = 0;
  foreach (1..5600) {
    my ($i, $value) = $seq->next;

    # foreach my $try_value ($prev_value+1 .. $value-1) {
    #   my $est_i = $seq->value_to_i_estimate($try_value);
    #   if (ref $est_i) { $est_i = $est_i->numify }
    #   my $factor = $est_i / ($i||1);
    #   printf "x  est=%d   tvalue=%b  f=%.3f\n",
    #     $est_i, $try_value, $factor;
    # }

    {
      # require Math::BigInt;
      # $value = Math::BigInt->new($value);

      my $est_i = $seq->value_to_i_estimate($value);
      if (ref $est_i) { $est_i = $est_i->numify }
      my $factor = $est_i / ($i||1);
      printf "i=%d est=%d   value=%s  f=%.3f\n",
        $i, $est_i, $value, $factor;
    }

    $prev_value = $value;
  }
  exit 0;
}

