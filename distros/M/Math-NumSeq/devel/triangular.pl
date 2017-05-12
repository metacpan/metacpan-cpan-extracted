#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

use Smart::Comments;

{
  require Math::TriangularNumbers;
  foreach my $i (0 .. 40) {
    printf "%d  %d\n",
      $i,
        Math::TriangularNumbers::T($i);
  }
  exit 0;
}

{
  my $is_t = sub {
    my ($N) = @_;
    $N = sqrt(2*abs($N)+.25) + .5;
    return ($N == int($N));
  };
  require Math::TriangularNumbers;
  foreach my $i (-50 .. 50) {
    printf "%d  %d   %d %d\n",
      $i,
        Math::TriangularNumbers::Ti($i),
            Math::TriangularNumbers::is_T($i),
                $is_t->($i);
  }
  exit 0;
}

{
  require Math::TriangularNumbers;
  foreach my $i (0 .. 40) {
    printf "%d  %d  %d\n",
      $i,
        Math::TriangularNumbers::Ti($i),
            Math::TriangularNumbers::is_T($i);
  }
  exit 0;
}
