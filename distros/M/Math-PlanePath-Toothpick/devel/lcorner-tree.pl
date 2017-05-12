#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use List::Util 'min', 'max';
use Math::BigInt try => 'GMP';
use Math::BigFloat;
use Math::PlanePath::LCornerTree;
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;

{
  my $y = Math::BigFloat->new(109);
  my $x = Math::BigFloat->new(-63);
  ### $y
  ### $x
  $y /= $x;
  ### $y
}

{
  require Math::NumSeq::PlanePathTurn;
  require Math::BigFloat;
   Math::BigFloat->accuracy(15);
  require Math::BaseCnv;
  my $radix = 4;
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath => "DigitGroups,radix=$radix",
                                              turn_type => 'Turn4',
                                             );
  my $max = 0;
  for my $len (4 .. 200) {
    # my @array = ((2)x(2*$len-2), 0, (1)x$len);
    my @array = ((3)x$len, 0, 3, 1);
     print join(',',@array),"\n";
    my $i = digit_join_lowtohigh(\@array, $radix, Math::BigInt->new(0));
    print "$i\n";
    my $ri = Math::BaseCnv::cnv($i,10,$radix);
    print "[$radix] $ri\n";
    my $value = $seq->ith($i);
    my $newmax = '';
    if ($value > $max) {
      $max = $value;
      $newmax = ' ****';
    }
    print "  $value$newmax\n";
    $i *= 4;
    $i += 3;
  }

  # my $max = 0;
  # for (1 .. 200) {
  #   my $value = $seq->ith($i);
  #   my $ri = Math::BaseCnv::cnv($i,10,4);
  #   my $newmax = '';
  #   if ($value > $max) {
  #     $max = $value;
  #     $newmax = ' ****';
  #   }
  #   print "$i $ri $value$newmax\n";
  #   $i *= 4;
  #   $i += 3;
  # }
  exit 0;
}

{
  require Math::NumSeq::PlanePathTurn;
  require Math::BigInt;
  require Math::BaseCnv;
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'LCornerReplicate',
                                              turn_type => 'Turn4',
                                             );
  my $i = Math::BigInt->new(3);
  my $min = 99;
  for (1 .. 200) {
    my $value = $seq->ith($i);
    my $ri = Math::BaseCnv::cnv($i,10,4);
    my $newmin = '';
    if ($value < $min) {
      $min = $value;
      $newmin = ' ****';
    }
    print "$i $ri $value$newmin\n";
    $i *= 4;
    $i += 3;
  }

  # my $max = 0;
  # for (1 .. 200) {
  #   my $value = $seq->ith($i);
  #   my $ri = Math::BaseCnv::cnv($i,10,4);
  #   my $newmax = '';
  #   if ($value > $max) {
  #     $max = $value;
  #     $newmax = ' ****';
  #   }
  #   print "$i $ri $value$newmax\n";
  #   $i *= 4;
  #   $i += 3;
  # }
  exit 0;
}

{
  my $path = Math::PlanePath::LCornerTree->new (parts => 'diagonal-1');
  foreach my $depth (0 .. 20) {
    my $n = $path->tree_depth_to_n($depth);
    print "$n,";
  }
  print "\n";

  require Math::PlanePath::LCornerTreeByCells;
  $path = Math::PlanePath::LCornerTreeByCells->new (parts => 'diagonal-1');
  foreach my $depth (0 .. 20) {
    my $n = $path->tree_depth_to_n($depth);
    print "$n,";
  }
  print "\n";
  exit 0;
}
