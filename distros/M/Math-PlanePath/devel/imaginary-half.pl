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

use 5.004;
use strict;
use List::Util 'min', 'max';

# uncomment this to run the ### lines
#use Smart::Comments;


{
  # Dir4 maximum
  my $radix = 3;
  require Math::PlanePath::ImaginaryHalf;
  require Math::NumSeq::PlanePathDelta;
  require Math::BigInt;
  require Math::BaseCnv;
  my $path = Math::PlanePath::ImaginaryHalf->new (radix => $radix);
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath_object => $path,
                                               delta_type => 'Dir4');
  my $dir4_max = 0;
  foreach my $n (0 .. 600000) {
    # my $n = Math::BigInt->new(2)**$level - 1;
    my $dir4 = $seq->ith($n);
    if ($dir4 > $dir4_max) {
      $dir4_max = $dir4;
      my ($dx,$dy) = $path->n_to_dxdy($n);
      my $nr = Math::BaseCnv::cnv($n,10,$radix);
      printf "%d %7s  %2d,%2d %8.6f\n", $n,$nr, ($dx),($dy), $dir4;
    }
  }
  exit 0;
}

{
  # ProthNumbers
  require Math::BaseCnv;
  require Math::PlanePath::ImaginaryHalf;
  require Math::NumSeq::ProthNumbers;
  $|=1;
  my $radix = 2;
  my $path = Math::PlanePath::ImaginaryHalf->new (radix => $radix);
  my $seq = Math::NumSeq::ProthNumbers->new;
  my %seen;
  for (1 .. 200) {
    my (undef, $n) = $seq->next;
    my ($x, $y) = $path->n_to_xy($n);
    my $n2 = Math::BaseCnv::cnv($n,10,$radix);
    print "$x $y    $n $n2\n";
    $seen{$x} .= " ${y}[$n2]";
  }
  foreach my $x (sort {$a<=>$b} keys %seen) {
    print "$x $seen{$x}\n";
  }
  exit 0;
}

{
  # min/max extents
  require Math::BaseCnv;
  require Math::PlanePath::ImaginaryHalf;
  $|=1;
  my $radix = 3;
  my $path = Math::PlanePath::ImaginaryHalf->new (radix => $radix);
  my $xmin = 0;
  my $xmax = 0;
  my $ymax = 0;
  my $n = $path->n_start;
  for (my $level = 1; $level < 25; $level++) {
    my $n_next = $radix**$level;

    for ( ; $n < $n_next; $n++) {
      my ($x,$y) = $path->n_to_xy($n);
      $xmin = min ($xmin, $x);
      $xmax = max ($xmax, $x);
      $ymax = max ($ymax, $y);
    }
    printf "%2d  %12s %12s   %12s\n",
      $level,
        Math::BaseCnv::cnv($xmin,10,$radix),
            Math::BaseCnv::cnv($xmax,10,$radix),
                Math::BaseCnv::cnv($ymax,10,$radix);
  }
  exit 0;
}
