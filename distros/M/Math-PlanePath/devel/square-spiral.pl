#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Math::PlanePath::SquareSpiral;

# uncomment this to run the ### lines
#use Smart::Comments;


{
  require Math::Prime::XS;
  my @primes = (0,
                Math::Prime::XS::sieve_primes (1000));
  my $path = Math::PlanePath::SquareSpiral->new;

  foreach my $y (reverse -4 .. 4) {
    foreach my $x (-4 .. 4) {
      my $n = $path->xy_to_n($x,$y);
      my $p = $primes[$n] // '';
      printf " %4d", $p;
    }
    print "\n";
  }
  exit 0;
}
