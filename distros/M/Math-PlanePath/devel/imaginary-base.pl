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
use Math::PlanePath::Base::Generic
  'is_infinite';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use Math::PlanePath::ImaginaryBase;

# uncomment this to run the ### lines
use Smart::Comments;



{
  # nega min/max level

  my $radix = 3;
  # for (my $x2 = 0; $x2 < 100; $x2++) {
  #   _negaradix_range_digits($radix, $x2,$x2);
  # }
  # for (my $x1 = -1; $x1 > -100; $x1--) {
  #   _negaradix_range_digits($radix, $x1,$x1);
  # }
  for (my $x1 = 0; $x1 > -100; $x1--) {
    for (my $x2 = 0; $x2 < 1; $x2++) {
      my ($len, $level, $base)
        = Math::PlanePath::ImaginaryBase::_negaradix_range_level($x1,$x2, $radix);
      my $want_xmin = _level_to_xmin($level,$radix);
      my $want_xmax = _level_to_xmax($level,$radix);

      $len == $radix ** $level or die;

      print "$x1  $want_xmin len=$len, level=$level, base=$base\n";
      # print "$x2  $want_xmax len=$len, level=$level, base=$base\n";
      unless ($base <= $x1 && $base+$len > $x2) {
        print "$x1..$x2  got len=$len, level=$level, base=$base not cover\n";
      }

    }
  }

  exit 0;
}
{
  my $radix = 4;
  foreach my $level (0 .. 10) {
    my $xmin = _level_to_xmin($level,$radix);
    my $xmax = _level_to_xmax($level,$radix);
    print "$level $xmin  $xmax\n";
  }
  # Xmin = r*(r-1) + r^2 + r^4 + r^6

  # Xmax = r-1 + r^2 + r^4 + r^6

  # Xmax = 1 + (4^(k+1) - 1) / (4-1)
  # k+1 = round down pow (X-1)*(R2-1) + 1
  # 0,1,5,21
  sub _level_to_xmax {
    my ($level, $radix) = @_;

    my $max = 0;
    for (my $i = 1; $i < $level; $i += 2) {
      $max += ($radix-1) * $radix ** ($i-1)
    }
    return $max;

    my $rsquared = $radix*$radix;  # r2 = radix**2
    return ($radix**(2*$level) - 1) / ($rsquared-1);

    return ($radix * $rsquared**$level + 1) / ($rsquared-1);

  }

  # -Xmin = 1 + R*(R2^(k+1) - 1) / (R2-1)
  # R2^(k+2) = (X-1)*(R2-1)*R + R2
  # 0,-2,-10,-42
  sub _level_to_xmin {
    my ($level, $radix) = @_;

    my $min = 0;
    for (my $i = 1; $i < $level; $i += 2) {
      $min -= ($radix-1) * $radix ** $i;
    }
    return $min;

    my $rsquared = $radix*$radix;  # rsquared = radix**2
    return 1 - ($radix**(2*$level+1) + 1) / ($rsquared-1);
    return 1 - ($radix * $rsquared**$level + 1) / ($rsquared-1);

  }
  exit 0;
}
{
  # nega min/max
  #
  my $radix = 4;
  # for (my $x2 = 0; $x2 < 100; $x2++) {
  #   _negaradix_range_digits($radix, $x2,$x2);
  # }
  # for (my $x1 = -1; $x1 > -100; $x1--) {
  #   _negaradix_range_digits($radix, $x1,$x1);
  # }
  for (my $x1 = 0; $x1 > -1; $x1--) {
    foreach my $x2 (0 .. 1) {
      my ($min_digits, $max_digits)
        = Math::PlanePath::ImaginaryBase::_negaradix_range_digits_lowtohigh($x1,$x2, $radix);
      my $min = digit_join_lowtohigh ($min_digits, $radix);
      my $max = digit_join_lowtohigh ($max_digits, $radix);
      my ($want_min, $want_max)
        = negaradix_index_range($x1,$x2, $radix);
      if ($min != $want_min || $max != $want_max) {
        print "$x1..$x2  got $min,$max want $want_min,$want_max\n";
        print "  min_digits ",join(',',@$min_digits),"\n";
        print "  max_digits ",join(',',@$max_digits),"\n";
      }
    }
  }

  exit 0;
}

{
  # nega conversions

  my $radix = 2;
  my %seen;
  foreach my $n (0 .. 1024) {
    my $nega = index_to_negaradix($n,$radix);
    if ($seen{$nega}++) {
      print "duplicate nega=$nega\n";
    }
    my $rev_n = negaradix_to_index($nega,$radix);
    if ($rev_n != $n) {
      print "rev_n=$rev_n want n=$n\n";
    }

    print "$n  $nega   $rev_n\n";
  }
  sub index_to_negaradix {
    my ($n, $radix) = @_;
    my $power = 1;
    my $ret = 0;
    while ($n) {
      my $digit = $n % $radix;  # low to high
      $n = int($n/$radix);
      $ret += $power * $digit;
      $power *= -$radix;
    }
    return $ret;
  }
  sub negaradix_to_index {
    my ($n, $radix) = @_;
    my $power = 1;
    my $ret = 0;
    while ($n) {
      my $digit = $n % $radix;  # low to high
      $ret += $power * $digit;
      $n = - int(($n-$digit)/$radix);
      $power *= $radix;
    }
    return $ret;
  }

  sub negaradix_index_range {
    my ($nega1, $nega2, $radix) = @_;
    my @indices = map {negaradix_to_index($_,$radix)} $nega1 .. $nega2;
    return (min(@indices), max(@indices));
  }
  exit 0;
}

{
  # "**" operator
  for (my $n = 1; $n < 0xFFFFFFFF; $n = 2*$n+1) {
    my $cube = $n ** 3;
    my $mod = $cube % $n;
    print "$cube  $mod\n";
  }
  exit 0;
}

{
  # max Dir4

  require Math::BaseCnv;

  print 4-atan2(2,1)/atan2(1,1)/2,"\n";

  require Math::NumSeq::PlanePathDelta;
  my $radix = 8;
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath => "ImaginaryBase,radix=$radix",
                                               delta_type => 'Dir4');
  my $dx_seq = Math::NumSeq::PlanePathDelta->new (planepath => "ImaginaryBase,radix=$radix",
                                                  delta_type => 'dX');
  my $dy_seq = Math::NumSeq::PlanePathDelta->new (planepath => "ImaginaryBase,radix=$radix",
                                                  delta_type => 'dY');
  my $max = 0;
  # for (1 .. 1000000) {
  #   my ($i, $value) = $seq->next;

  foreach my $k (1 .. 1000000) {
    my $i = $radix ** (4*$k+3) - 1;
    my $value = $seq->ith($i);

    if ($value > $max) {
      my $dx = $dx_seq->ith($i);
      my $dy = $dy_seq->ith($i);
      my $ri = Math::BaseCnv::cnv($i,10,$radix);
      my $rdx = Math::BaseCnv::cnv($dx,10,$radix);
      my $rdy = Math::BaseCnv::cnv($dy,10,$radix);
      my $f = $dx/$dy;
      printf "%d %s %.5f  %s %s   %.3f\n", $i, $ri, $value, $rdx,$rdy, $f;
      $max = $value;
    }
  }

  exit 0;
}

# $aref->[0] high digit
sub digit_join_hightolow {
  my ($aref, $radix, $zero) = @_;
  my $n = (defined $zero ? $zero : 0);
  foreach my $digit (@$aref) {
    $n *= $radix;
    $n += $digit;
  }
  return $n;
}
