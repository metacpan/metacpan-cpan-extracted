#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
use POSIX 'floor';
use List::Util 'min', 'max';
use Math::PlanePath::CfracDigits;
use Math::PlanePath::Base::Digits
  'round_down_pow';
use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::KochCurve;
*_digit_join_hightolow = \&Math::PlanePath::KochCurve::_digit_join_hightolow;



# 121313322

{
  require Math::PlanePath::CfracDigits;
  my $path = Math::PlanePath::CfracDigits->new;
  foreach my $n (0 .. 120) {
    my ($x,$y) = $path->n_to_xy($n);
    print "$x,";
  }
  print "\n";
  print "\n";

  foreach my $n (0 .. 120) {
    my ($x,$y) = $path->n_to_xy($n);
    print "$y,";
  }
  print "\n";
  print "\n";

  foreach my $n (0 .. 120) {
    my ($x,$y) = $path->n_to_xy($n);
    print "$x/$y, ";
  }
  print "\n";
  print "\n";

  exit 0;
}

{
  require Math::PlanePath::CfracDigits;
  require Number::Fraction;
  my $path = Math::PlanePath::CfracDigits->new (radix => 1);
  my $rat = Math::PlanePath::RationalsTree->new (tree_type => 'HCS');
  my $nf = Number::Fraction->new(1,7);
  $nf = 1 / (4 + 1 / (2 + Number::Fraction->new(1,7)));
  print "$nf\n";
  my $x = $nf->{num};
  my $y = $nf->{den};
  my $n = $path->xy_to_n($x,$y);
  printf "%5d  %17b\n", $n, $n;
  $n = $rat->xy_to_n($y-$x,$x);
  printf "%5d  %17b\n", $n, $n;
  exit 0;
}

{
  # +1 at low end to turn 1111 into 10000
  require Math::PlanePath::CfracDigits;
  my $rat = Math::PlanePath::RationalsTree->new (tree_type => 'HCS');
  my $cf = Math::PlanePath::CfracDigits->new (radix => 1);
  for (my $n = $rat->n_start; $n < 200; $n++) {
    my ($cx,$cy) = $cf->n_to_xy($n);
    # my ($rx,$ry) = $rat->n_to_xy($n);
    my $rn = $rat->xy_to_n($cy,$cx);
    printf "%d,%d  %b  %b\n",
      $cx,$cy, $n, $rn-1;
  }
  exit 0;
}
{
  # Fibonacci F[k]/F[k+1]
  require Math::NumSeq::Fibonacci;
  my $seq = Math::NumSeq::Fibonacci->new;
  my $radix = 3;
  my $path = Math::PlanePath::CfracDigits->new (radix => $radix);
  for (my $i = 1; $i < 20; $i++) {
    my $x = $seq->ith($i);
    my $y = $seq->ith($i+1);
    my $log = Math::PlanePath::CfracDigits::_log_phi_estimate($y);
    my $n = $path->xy_to_n($x,$y);
    # {
    #   my @digits = ($radix+1) x ($i-2);
    #   my $carry = 0;
    #   foreach my $digit (@digits) {   # low to high
    #     if ($carry = (($digit += $carry) >= $radix)) {  # modify array contents
    #       $digit -= $radix;
    #     }
    #   }
    #   if ($carry) {
    #     push @digits, 1;
    #   }
    #   print join(',',@digits),"\n";
    # }
    my @digits = ($radix+1) x ($i-2);
    my $d = Math::PlanePath::CfracDigits::_digit_join_1toR_destructive(\@digits,$radix+1,0);
    my $pow = ($radix+1)**$i;
    my ($nlo,$nhi) = $path->rect_to_n_range(0,0, $x,$y);
    print "$n   $log $nhi $d $pow\n";
  }
  exit 0;
}


{
  # range vs GcdRationals

  my $radix = 2;
  require Math::PlanePath::CfracDigits;
  require Math::PlanePath::GcdRationals;
  my $cf = Math::PlanePath::CfracDigits->new (radix => $radix);
  my $gc = Math::PlanePath::GcdRationals->new;

  foreach my $y (2 .. 1000) {
    my ($cf_nlo,$cf_nhi) = $cf->rect_to_n_range(0,0, 1,$y);
    my ($gc_nlo,$gc_nhi) = $gc->rect_to_n_range(0,0, $y,$y);
    my $flag = '';
    if ($cf_nhi > $gc_nhi) {
      $flag = "*****";
    }
    print "$y   $cf_nhi  $gc_nhi$flag\n";
  }
  exit 0;
}
{
  # maximum N

  require Math::PlanePath::CfracDigits;
  my $radix = 6;
  my $path = Math::PlanePath::CfracDigits->new (radix => $radix);

  foreach my $y (2 .. 1000) {
    my $nmax = -1;
    my $xmax;
    foreach my $x (1 .. $y-1) {
      my $n = $path->xy_to_n($x,$y) // next;
      my $len = $n; # length_1toR($n);
      if ($len > $nmax) {
        $nmax = $len;
        $xmax = $x;
        # print "   $xmax  $nmax   ",groups_string($n),"\n";
      }
    }

    my ($nlo,$nhi) = $path->rect_to_n_range(0,0,1,$y);

    my $groups = groups_string($nmax);
    my $ysquared = ($radix+1) ** (_fib_log($y) - 1.5);
    # my $ysquared = ($radix+1) ** (log2($y)*2);
    # my $ysquared = int($y ** (5/2));
    my $yfactor = sprintf '%.2f', $ysquared / ($nmax||1);
    my $flag = '';
    if ($ysquared < $nmax) {
      $flag = "*****";
    }
    print "$y x=$xmax  n=$nmax  $ysquared$flag $yfactor   $groups\n";


    my $log = Math::PlanePath::CfracDigits::_log_phi_estimate($y);
    $flag = '';
    if ($nhi < $nmax) {
      $flag = "*****";
    }
    print "   nhi=$nhi$flag   log=$log\n";
  }
  exit 0;


  sub groups_string {
    my ($n) = @_;
    my @groups = Math::PlanePath::CfracDigits::_n_to_quotients($n,$radix);
    return join(',',reverse @groups);
  }
  sub length_1toR {
    my ($n) = @_;
    my @digits = Math::PlanePath::CfracDigits::_digit_split_1toR_lowtohigh($n,$radix);
    return scalar(@digits);
  }
  sub log2 {
    my ($x) = @_;
    return int(log($x)/log(2));
  }

  sub _fib_log {
    my ($x) = @_;
    ### _fib_log(): $x
    my $f0 = ($x * 0);
    my $f1 = $f0 + 1;
    my $count = 0;
    while ($x > $f0) {
      $count++;
      ($f0,$f1) = ($f1,$f0+$f1);
    }
    return $count;
  }
}


{
  # minimum N in each row is at X=1

  require Math::PlanePath::CfracDigits;
  my $path = Math::PlanePath::CfracDigits->new;

  foreach my $y (2 .. 1000) {
    my $nmin = 1e308;
    my $xmin;
    foreach my $x (1 .. $y-1) {
      my $n = $path->xy_to_n($x,$y) // next;
      if ($n < $nmin) {
        $nmin = $n;
        $xmin = $x;
      }
    }
    print "$y $xmin  $nmin\n";
  }
  exit 0;
}
