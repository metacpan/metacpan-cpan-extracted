#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

{
  # BigFloat log()
  use Math::BigFloat;
  my $b = Math::BigFloat->new(3)**64;
  my $log = log($b);
  my $log3 = $log/log(3);
  # $b->blog(undef,100);
  print "$b\n$log\n$log3\n";
  exit 0;
}
{
  # BigInt log()
  use Math::BigInt;
  use Math::BigFloat;
  my $b = Math::BigInt->new(1025);
  my $log = log($b);
  $b->blog(undef,100);
  print "$b $log\n";
  exit 0;
}

