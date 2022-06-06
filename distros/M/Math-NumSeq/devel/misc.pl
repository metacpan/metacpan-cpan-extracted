#!/usr/bin/perl -w

# Copyright 2013, 2014, 2020, 2021, 2022 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use FindBin;
use Math::BaseCnv 'cnv';
use List::Util 'max','min';

use lib::abs "$FindBin::Bin/../xt";
use lib::abs "$FindBin::Bin/../t";
use MyOEIS;
use MyTestHelpers;
$|=1;

{
  # A064827 all digits of k in k^2 in any order

  # A046827 Numbers n such that n^2 contains all the digits of n with the same or higher multiplicity.
  # A064827 Numbers n such that each digit of n occurs among the digits of n^2.

  foreach my $k (1 .. 1000) {
    # if (is_A064827($k)) { print "$k,"; }
    if (is_A064827($k) != is_A064827_distinct($k)) {
      print "$k,";
    }
  }
  exit 0;
  sub is_A064827_distinct {
    my ($k) = @_;
    my $s = $k*$k;
    foreach my $d (split //,$k) {
      index($s,$d)>=0 or return 0;
    }
    return 1;
  }
  sub is_A064827 {
    my ($k) = @_;
    my @digs;
    foreach my $d (split //,$k*$k) { $digs[$d]++; }
    foreach my $d (split //,$k) {
      if (--$digs[$d] < 0) {
        return 0;
      }
    }
    return 1;
  }
}
{
  # A018834 Numbers k such that decimal expansion of k^2 contains k as a substring.
  # cf A064827 all digits any order
  my $k = 1;
  while ($k < 10000) {
    my $s = $k*$k;
    if (index($s,$k) >=0) {
      print "$k,";
    }
    $k++;
  }
  exit 0;
}
{
  # A032740 Numbers k such that k is a substring of 2^k.
  # 2^k digits contain k
  my $t = Math::BigInt->new(2);
  my $k = 1;
  while ($k < 100) {
    if (index($t,$k) >=0) {
      print "$k,";
    }
    $k++; $t<<=1;
  }
  exit 0;
}
{
  # A048715 Narayana bits
  my @want = (0, 1, 2, 4, 8, 9, 16, 17, 18, 32, 33, 34, 36, 64, 65, 66, 68, 72, 73);
  my @got = grep {cnv($_,10,2) =~ /^(100(0)*)*(0|1|10)?$/} 0 .. 73;
  print join(',',@want),"\n";
  print join(',',@got),"\n";
  print join(',',@want) eq join(',',@got),"\n";
  print( ('100' =~ /^(100(0)*)*(0|1|10)?$/), "\n");
  # (string-match "\\`\\(100\\(0\\)*\\)*\\(0|1|10\\)?\\'" "100")
  exit 0;
}
  

{
  # digits dup
  # sub Axx { my($n)=@_; $n =~ s/./$&$&/g; $n }
  exit 0;
}

{
  require Math::NumSeq::SternDiatomic;
  my $seq = Math::NumSeq::SternDiatomic->new;
  foreach my $i (0 .. 40) {
    my ($v0,$v1) = $seq->ith_pair($i);
    my $w0 = $seq->ith($i);
    my $w1 = $seq->ith($i+1);
    my $diff = ($w0==$v0 && $w1==$v1 ? '' : ' ***');
    print "$i  $w0 $w1  $v0 $v1$diff\n";
  }
  exit 0;
}
{
  require Math::NumSeq::FibonacciRepresentations;
  my $seq = Math::NumSeq::FibonacciRepresentations->new;
  { my $value = $seq->ith(3);
    print "$value\n";
  }
  { my $value = $seq->ith(4);
    print "$value\n";
  }
  { my $value = $seq->ith(5);
    print "$value\n";
  }
  exit 0;
}

{
  foreach my $y (reverse -5 .. 5) {
    foreach my $x (-5 .. 5) {
      my $v = max(abs($x+$y),abs($x-$y),2*abs($y));
      # my $v = max($x,$y);
      if ($v & 1) {
        print "  ";
      } else {
        printf '%2d', $v;
      }
    }
    print "\n";
  }
  exit 0;
}
{
  my @m = max();
  ### max empty: @m
  exit 0;
}

{
  unlink '/tmp/tie-file.txt';
  system 'echo one >/tmp/tie-file.txt';
  system 'echo two >>/tmp/tie-file.txt';
  system 'echo three >>/tmp/tie-file.txt';
  system 'cat /tmp/tie-file.txt';
  my @array; # = (1,2,3);
  require Tie::File;
  tie @array, 'Tie::File', '/tmp/tie-file.txt' or die;
  foreach my $i (-7 .. 5) {
    my $e = (exists $array[$i] ? "E" : "n");
    print "$i $e\n";
  }
  exit 0;
}
