#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

use 5.004;
use strict;

{
  require Math::BigInt;
  my $two = Math::BigInt->new(2);
  foreach my $a (1, 2, 3, 4, 6, 7, 8, 11, 12, 14, 15, 16, 22, 23, 24, 27, 28, 30, 31, 32, 43, 44, 46, 47, 48, 54, 55,
                 56, 59, 60, 62, 63, 64, 86, 87, 88, 91, 92, 94, 95, 96, 107, 108, 110, 111, 112, 118, 119, 120, 123,
                 124, 126, 127, 128, 171, 172, 174, 175, 176, 182, 183, 184, 187) {
    printf "%b\n", $a;

  }
  exit 0;
}


