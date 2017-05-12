#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

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
use Math::OEIS::Grep;

{
  require Devel::TimeThis;
  my @values = (81239, 1849, 1489);
  my $reps = 10;
  {
    my $t = Devel::TimeThis->new('mmap');
    for (1 .. $reps) {
      print "$_\n";
      Math::OEIS::Grep->search (array=>\@values,
                                verbose => 1);
    }
  }
  {
    my $t = Devel::TimeThis->new('fh');
    for (1 .. $reps) {
      print "$_\n";
      Math::OEIS::Grep->search (use_mmap => 0,
                                array=>\@values,
                                verbose => 1);
    }
  }
  exit 0;
}
