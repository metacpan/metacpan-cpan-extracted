#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use POSIX 'fmod';
use Math::Libm 'M_PI', 'M_E', 'hypot';
use Math::Trig 'pi';
use POSIX;

# sqrt(pi*e/2) = 1 / (1+ 1/(1 + 2/(1+ 3/(1 + 4/(...)))))

{
  use Math::BigFloat;
  my $rot;
  $rot = M_PI;
  $rot = sqrt(17);
  # $rot = Math::BigFloat->bpi(1000);    # PI to 100 digits
  # $rot = Math::BigFloat->bsqrt(5);
  # $rot = (Math::BigFloat->bsqrt(5) +1) / 2;
  $rot = sqrt(M_PI() * M_E() / 2);
  $rot = 0.5772156649015328606065120;
  $rot = sqrt(5);

  foreach (1..30) {
    my $int = int($rot);
    my $frac = $rot - $int;
    print $int,"\n";
    $rot = 1/$frac;
  }
  # use constant ROTATION => PHI;
  # use constant ROTATION =>
  exit 0;
}
