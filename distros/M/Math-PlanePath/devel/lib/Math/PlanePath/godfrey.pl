#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
use POSIX ();
use List::Util 'sum';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use Math::PlanePath::Godfrey;

# uncomment this to run the ### lines
use Smart::Comments;


{
  my $path = Math::PlanePath::Godfrey->new;
  foreach my $n (1 .. 1+2+3+4+5+6+7) {
    my ($x,$y) = $path->n_to_xy($n);
    print "$y,";
  }
  print "\n";
  exit 0;
}
{
  require Math::NumSeq::OEIS::File;
  my $seq = Math::NumSeq::OEIS::File->new(anum=>'A126572'); # OFFSET=1
  my $perm = Math::NumSeq::OEIS::File->new(anum=>'A038722'); # OFFSET=1
  my @values;
  foreach my $n (1 .. 1+2+3+4+5+6+7) {
    my $pn = $perm->ith($n);
    push @values, $seq->ith($n);
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}
