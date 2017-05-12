#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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
use Math::PlanePath::Base::Digits 'digit_split_lowtohigh';

# uncomment this to run the ### lines
use Smart::Comments;


{
  # 2^64-1 base7 45012021522523134134601
  # decimal less first digit 2635249153387078802
  #                          2635249153387078656
  require Devel::Peek;
  my $n = ~0;
  my $radix = 7;
  my $digit = $n % $radix;
  ### $digit
  $n /= $radix;
  Devel::Peek::Dump($n);
  $n = int($n);
  Devel::Peek::Dump($n);

  require Math::PlanePath;
  my @digits = digit_split_lowtohigh(~0,$radix);
  ### @digits

  exit 0;
}

{
  # Diagonal
  require Math::BaseCnv;
  require Math::NumSeq::PlanePathN;
  my $seq = Math::NumSeq::PlanePathN->new (planepath=> 'DigitGroups',
                                           line_type => 'Diagonal');
  foreach my $i (0 .. 150) {
    my ($i,$value) = $seq->next;
    my $v2 = Math::BaseCnv::cnv($value,10,2);
    printf "%4d %20s\n", $value, $v2;
  }
  print "\n";
  exit 0;
}

{
  require Math::BaseCnv;
  require Math::PlanePath::DigitGroups;
  foreach my $radix (2 .. 7) {
    print "radix $radix\n";
    my $path = Math::PlanePath::DigitGroups->new (radix => $radix);
    foreach my $coord_max (0 .. 25) {
      my $n_max = $path->xy_to_n(0,0);
      my $x_max = 0;
      my $y_max = 0;
      foreach my $x (0 .. $coord_max) {
        foreach my $y (0 .. $coord_max) {
          my $n = $path->xy_to_n($x,$y);
          ### got: "$x,$y   $n"
          if ($n > $n_max) {
            $x_max = $x;
            $y_max = $y;
            $n_max = $n;
          }
        }
      }
      my $n_max_base = Math::BaseCnv::cnv($n_max,10,$radix);

      my ($n_lo, $n_hi) = $path->rect_to_n_range(0,0,$coord_max,$coord_max);
      my $n_hi_base = Math::BaseCnv::cnv($n_hi,10,$radix);

      print " $coord_max  $x_max,$y_max   n=$n_max [$n_max_base]     cf nhi=$n_hi [$n_hi_base]\n";
    }
    print "\n";
  }
  exit 0;
}

{
  require Math::BaseCnv;
  require Math::PlanePath::DigitGroups;
  foreach my $radix (2 .. 7) {
    print "radix $radix\n";
    my $path = Math::PlanePath::DigitGroups->new (radix => $radix);
    foreach my $exp (1 .. 5) {
      my $coord_min = $radix ** ($exp-1);
      my $coord_max = $radix ** $exp - 1;
      print " $coord_min $coord_max\n";
      my $x_min = $coord_min;
      my $y_min = $coord_min;
      my $n_min = $path->xy_to_n($x_min,$y_min);
      foreach my $x ($coord_min .. $coord_max) {
        foreach my $y ($coord_min .. $coord_max) {
          my $n = $path->xy_to_n($x,$y);
          ### got: "$x,$y   $n"
          if ($n < $n_min) {
            $x_min = $x;
            $y_min = $y;
            $n_min = $n;
          }
        }
      }
      my $n_min_base = Math::BaseCnv::cnv($n_min,10,$radix);

      my ($n_lo, $n_hi) = $path->rect_to_n_range(0,0,$coord_max,$coord_max);
      my $n_lo_base = Math::BaseCnv::cnv($n_lo,10,$radix);

      print " $exp  $x_min,$y_min   n=$n_min [$n_min_base]     cf nlo=$n_lo [$n_lo_base]\n";
    }
    print "\n";
  }
  exit 0;
}
{
  require Math::BaseCnv;
  require Math::PlanePath::DigitGroups;
  foreach my $radix (2 .. 7) {
    print "radix $radix\n";
    my $path = Math::PlanePath::DigitGroups->new (radix => $radix);
    foreach my $exp (1 .. 5) {
      my $coord_max = $radix ** $exp - 1;
      my $n_max = $path->xy_to_n(0,0);
      my $x_max = 0;
      my $y_max = 0;
      foreach my $x (0 .. $coord_max) {
        foreach my $y (0 .. $coord_max) {
          my $n = $path->xy_to_n($x,$y);
          ### got: "$x,$y   $n"
          if ($n > $n_max) {
            $x_max = $x;
            $y_max = $y;
            $n_max = $n;
          }
        }
      }
      my $n_max_base = Math::BaseCnv::cnv($n_max,10,$radix);

      my ($n_lo, $n_hi) = $path->rect_to_n_range(0,0,$coord_max,$coord_max);
      my $n_hi_base = Math::BaseCnv::cnv($n_hi,10,$radix);

      print " $exp  $x_max,$y_max   n=$n_max [$n_max_base]     cf nhi=$n_hi [$n_hi_base]\n";
    }
    print "\n";
  }
  exit 0;
}
