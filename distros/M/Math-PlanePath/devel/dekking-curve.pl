#!/usr/bin/perl -w

# Copyright 2015, 2016 Kevin Ryde

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
use List::MoreUtils;
use POSIX 'floor';
use Math::BaseCnv;
use Math::Libm 'M_PI', 'hypot', 'cbrt';
use List::Util 'min', 'max', 'sum';
use Math::PlanePath::DekkingCurve;
use Math::PlanePath::Base::Digits
  'round_down_pow','digit_split_lowtohigh';
use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::BaseCnv 'cnv';

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # axis segments, print numbers

  # X
  my $path = Math::PlanePath::DekkingCurve->new;
  foreach my $x (0 .. 20) {
    print $path->_UNDOCUMENTED__xseg_is_traversed($x)?1:0,",";
  }
  print "\n";
  foreach my $x (0 .. 50) {
    if ($path->_UNDOCUMENTED__xseg_is_traversed($x)) {
      print $x,",";
    }
  }
  print "\n";

  # Y
  foreach my $y (0 .. 20) {
    print $path->_UNDOCUMENTED__yseg_is_traversed($y)?1:0,",";
  }
  print "\n";
  foreach my $y (0 .. 50) {
    if ($path->_UNDOCUMENTED__yseg_is_traversed($y)) {
      print $y,",";
    }
  }
  print "\n";

  print "union\n";
  # 1,1,0,1,0,1,1,0,1,0,1,1,0,1,1,0,1,0,1,1,0
  foreach my $i (0 .. 40) {
    print $path->_UNDOCUMENTED__xseg_is_traversed($i)
      || $path->_UNDOCUMENTED__yseg_is_traversed($i) ?1:0,",";
  }
  print "\n";
  foreach my $i (0 .. 30) {
    if ($path->_UNDOCUMENTED__xseg_is_traversed($i)
        || $path->_UNDOCUMENTED__yseg_is_traversed($i)) {
      print $i,",";
    }
  }
  print "\n";

  exit 0;
}

{
  # axis segments by FLAT

  use lib '../dragon/tools';
  require MyFLAT;
  my $path = Math::PlanePath::DekkingCurve->new;

  my @xseg_state_table;
  my $S = 0;
  my $E = 1;
  my $N = 2;
  my $W = 3;
  $xseg_state_table[$S] = [$S,$S,$E,$N,$W];
  $xseg_state_table[$E] = [$S,$S,$E,$N,$N];
  $xseg_state_table[$N] = [$W,$S,$E,$N,$N];
  $xseg_state_table[$W] = [$W,$S,$E,$N,$W];
  my $xseg_flat = MyFLAT::aref_to_FLAT_DFA (\@xseg_state_table,
                                            name => 'xseg',
                                            accepting => 0); # South
  {
    my $bad = 0;
    foreach my $x (0 .. 1000) {
      my $str = cnv($x,10,5);
      my $by_path = $path->_UNDOCUMENTED__xseg_is_traversed($x) ?1:0;
      my $by_flat = $xseg_flat->contains($str) ?1:0;
      unless ($by_path == $by_flat) {
        print "X=$x [$str]  $by_path $by_flat\n";
        exit 1 if $bad++ > 10;
      }
    }
  }

  # zero
  # lowest non zero 1 at lowest, or 1 or 2 above
  my $xseg_regex = FLAT::Regex->new('0*
                                    | (0|1|2|3|4)*           1
                                    | (0|1|2|3|4)*  (1|2) 0* 0')->as_dfa;
  # MyFLAT::FLAT_show_breadth($xseg_flat,2);
  # MyFLAT::FLAT_show_breadth($xseg_regex,2);
  MyFLAT::FLAT_check_is_equal($xseg_flat, $xseg_regex);

  #-------------------

  my @yseg_state_table;
  $yseg_state_table[$S] = [$W,$N,$E,$S,$S];
  $yseg_state_table[$E] = [$N,$N,$E,$S,$S];
  $yseg_state_table[$N] = [$N,$N,$E,$S,$W];
  $yseg_state_table[$W] = [$W,$N,$E,$S,$W];
  my $yseg_flat = MyFLAT::aref_to_FLAT_DFA (\@xseg_state_table,
                                            name => 'yseg',
                                            accepting => $N);
  {
    my $bad = 0;
    foreach my $y (0 .. 1000) {
      my $str = cnv($y,10,5);
      my $by_path = $path->_UNDOCUMENTED__yseg_is_traversed($y) ?1:0;
      my $by_flat = $yseg_flat->contains($str) ?1:0;
      unless ($by_path == $by_flat) {
        print "Y=$y [$str]  $by_path $by_flat\n";
        exit 1 if $bad++ > 10;
      }
    }
  }

  # empty
  # lowest is 4
  # after low digit, lowest non-zero is 1 or 2
  my $yseg_regex = FLAT::Regex->new(' (0|1|2|3|4)*           3
                                    | (0|1|2|3|4)*  (2|3) 4* 4')->as_dfa;
  MyFLAT::FLAT_check_is_equal($yseg_flat, $yseg_regex);

  #-------------------
  # low 1 or 3
  # low 0 then lowest non-0 is 1 or 2
  # low 4 then lowest non-4 is 2 or 3
  my $union = $xseg_flat->union($yseg_flat)->MyFLAT::minimize;
  $union->MyFLAT::view;

  my $union_LtoH = $union->MyFLAT::reverse->MyFLAT::minimize;
  $union_LtoH->MyFLAT::view;

  exit 0;
}

{
  # X leading diagonal segments

  my $path = Math::PlanePath::DekkingCentres->new;
  my @values;
  my $prev = -1;
  foreach my $i (0 .. 500) {
    my $n = $path->xyxy_to_n($i,$i, $i+1,$i+1); # forward
    # my $n = $path->xyxy_to_n($i+1,$i+1, $i,$i); # reverse
    if (defined $n) {
      my $i5 = Math::BaseCnv::cnv($i,10,5);
      print "$i [$i5]  \n";
      push @values, $i;
    }
    $prev = $n;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}

{
  # X negative axis N not increasing

  my $path = Math::PlanePath::DekkingCurve->new (arms => 3);
  my @values;
  my $prev = -1;
  foreach my $i (0 .. 500) {
    my $n = $path->xy_to_n(-$i,0);
    if ($n < $prev) {
      my $i5 = Math::BaseCnv::cnv($i,10,5);
      print "$i [$i5]  \n";
      push @values, $i;
    }
    $prev = $n;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}

{
  # X,Y axis points in common (none)

  my $path = Math::PlanePath::DekkingCurve->new;
  my @values;
  foreach my $i (0 .. 500) {
    my $nx = $path->xy_to_n($i,0);
    my $ny = $path->xy_to_n(0,$i);
    if (defined $nx && defined $ny) {
      my $i5 = Math::BaseCnv::cnv($i,10,5);
      print "$i5  \n";
      push @values, $i;
    }
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}

{
  # Y axis points

  my %table = (S => ['W','N','E','S','S'],
               E => ['N','N','E','S','S'],
               N => ['N','N','E','S','W'],
               W => ['W','N','E','S','W']);
  sub yseg_to_side {
    my ($y) = @_;
    my $state = 'W';
    my @digits = digit_split_lowtohigh($y,5);
    foreach my $digit (reverse @digits) {  # high to low
      $state = $table{$state}->[$digit];
    }
    return $state;
  }

  my $path = Math::PlanePath::DekkingCurve->new;
  my @values;
  foreach my $y (0 .. 500) {
    my $path_point_visit = defined($path->xy_to_n(0,$y)) ? 1 : 0;
    my $path_seg_visit = defined($path->xyxy_to_n_either(0,$y, 0,$y+1)) ? 1 : 0;

    my $side = yseg_to_side($y);
    my $prev_side = $y>0 && yseg_to_side($y-1);
    my $htol_visit = ($side eq 'S' || $side eq 'W'
                      || $prev_side eq 'S' || $prev_side eq 'E'
                      ? 1 : 0);
    my $htol_seg_visit = ($side eq 'S' ? 1 : 0);

    my $diff = ($path_seg_visit == $htol_seg_visit ? '' : '  ***');

    my $y5 = Math::BaseCnv::cnv($y,10,5);
    print "$y5  $path_seg_visit ${htol_seg_visit}[$side] $diff\n";

    if (defined $path_seg_visit) {
      push @values, $y;
    }
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}

{
  # X axis points

  # X
  # S -> S,S,E,N,W
  # E -> S,S,E,N,N
  # N -> W,S,E,N,N
  # W -> W,N,E,S,W
  my %table = (S => ['S','S','E','N','W'],
               E => ['S','S','E','N','N'],
               N => ['W','S','E','N','N'],
               W => ['W','S','E','N','W']);
  sub x_to_side {
    my ($x) = @_;
    my $state = 'S';
    my @digits = digit_split_lowtohigh($x,5);
    foreach my $digit (reverse @digits) {  # high to low
      $state = $table{$state}->[$digit];
    }
    return $state;
  }

  my $path = Math::PlanePath::DekkingCurve->new;
  my @values;
  foreach my $x (0 .. 500) {
    my $path_point_visit = defined($path->xy_to_n($x,0)) ? 1 : 0;
    my $path_seg_visit = defined($path->xyxy_to_n_either($x,0, $x+1,0)) ? 1 : 0;

    my $side = x_to_side($x);
    my $prev_side = $x>0 && x_to_side($x-1);
    my $htol_visit = ($side eq 'S' || $side eq 'E'
                      || $prev_side eq 'S' || $prev_side eq 'W'
                      ? 1 : 0);
    my $htol_seg_visit = $path->_UNDOCUMENTED__xseg_is_traversed($x);

    my $diff = ($path_seg_visit == $htol_seg_visit ? '' : '  ***');

    my $x5 = Math::BaseCnv::cnv($x,10,5);
    print "$x5  $path_seg_visit ${htol_visit}[$side] $diff\n";

    if (defined $path_seg_visit) {
      push @values, $x;
    }
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}
