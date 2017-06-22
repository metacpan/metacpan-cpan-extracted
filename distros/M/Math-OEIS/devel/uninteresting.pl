#!/usr/bin/perl -w

# Copyright 2016, 2017 Kevin Ryde

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


# Find the smallest "uninteresting" number, being a number which doesn't
# appear in the stripped file sample values.

use 5.004;
use strict;
use Math::OEIS::Stripped;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # When gaps in the interesting numbers are filled.
  #
  # If number n appears first in say A123456 then it was a gap in the
  # interesting numbers until that sequence.
  #
  # So going by successive numbers n, if it has a new high A-number then n
  # was a gap for a while.  Print here those n and A-numbers of new highs.

  $| = 1;
  my $stripped = Math::OEIS::Stripped->new (use_bigint => 0);
  my $fh = $stripped->fh;
  my @seen;
  my @seen_neg;
  my $limit = 20_000;
  my $last_anum;
  while (defined(my $line = readline $fh)) {
    my ($anum,$values) = $stripped->line_split_anum($line)
      or next;
    if (progress()) { print "reading $anum\r"; }
    foreach my $value ($stripped->values_split($values)) {
      if ($value >= 0 && $value <= $limit) {
        $seen[$value] //= $anum;
      }
      $value = -$value;
      if ($value >= 0 && $value <= $limit) {
        $seen_neg[$value] //= $anum;
      }
    }
    $last_anum = $anum;
  }

  foreach my $aref (\@seen, \@seen_neg) {
    my $anum = 'A000000';
    my $count = 2;
    foreach my $value (0 .. $limit) {
      if (! defined $aref->[$value]) {
        printf "%d uninteresting (binary %b)\n", $value, $value;
        last if ++$count > 3;
      } elsif ($aref->[$value] ge $anum) {
        $anum = $aref->[$value];
        print "$value filled by $anum\n";
      }
    }
    print "last anum is $last_anum\n";
    print "\n";
    print "negatives\n";
  }
  exit 0;
}

{
  $| = 1;
  my $stripped = Math::OEIS::Stripped->new (use_bigint => 0);
  my $fh = $stripped->fh;
  my $seen = '';
  my $seen_neg = '';
  my $limit = 100_000;
  while (defined(my $line = readline $fh)) {
    my ($anum,$values) = $stripped->line_split_anum($line)
      or next;
    if (progress()) { print "$anum\r"; }
    foreach my $value ($stripped->values_split($values)) {
      if ($value >= 0 && $value <= $limit) {
        vec($seen,$value,1) = 1;
      }
      $value = -$value;
      if ($value >= 0 && $value <= $limit) {
        vec($seen_neg,$value,1) = 1;
      }
    }
  }
  
  foreach my $str ($seen, $seen_neg) {
    my $count = 0;
    foreach my $value (0 .. $limit) {
      if (! vec($str,$value,1)) {
        printf "uninteresting  %d  %#b\n", $value, $value;
        last if ++$count > 3;
      }
    }
    print "negatives\n";
  }
  exit 0;

  # return true if a progress message should be printed
  my $t;
  sub progress {
    $t ||= 0;
    my $u = time();
    if (int($t/2) != int($u/2)) {
      $t = $u;
      return 1;
    } else {
      return 0;
    }
  }
}


#------------------------------------------------------------------------------

# GP-DEFINE  \\ select_first_n(f,n) returns a vector of length n which are the
# GP-DEFINE  \\ indices i for which function f(i) is true.
# GP-DEFINE  \\ Indices checked start from 0 so i=0,1,2,...
# GP-DEFINE  select_first_n(f,n) = {
# GP-DEFINE    my(l=List([]), i=0);
# GP-DEFINE    while(#l<n, if(f(i),listput(l,i)); i++);
# GP-DEFINE    Vec(l);
# GP-DEFINE  }
# GP-DEFINE  from_binary(n) = fromdigits(digits(n),2);
# GP-DEFINE  to_binary(n)=fromdigits(binary(n));
# GP-DEFINE  one_bit_run_lengths(n) = {
# GP-DEFINE    my(v=binary(n),l=List([]),i=1,s);
# GP-DEFINE    while(1,
# GP-DEFINE          while(i<=#v && v[i]==0, i++);
# GP-DEFINE          if(i>#v,break());
# GP-DEFINE          s=i;
# GP-DEFINE          while(i<=#v && v[i]==1, i++);
# GP-DEFINE          listput(l,i-s));
# GP-DEFINE    Vec(l);
# GP-DEFINE  }
# GP-Test  one_bit_run_lengths(from_binary(0)) == []
# GP-Test  one_bit_run_lengths(from_binary(1)) == [1]
# GP-Test  one_bit_run_lengths(from_binary(11100)) == [3]
# GP-Test  one_bit_run_lengths(from_binary(1011011101111)) == [1,2,3,4]
# GP-DEFINE  is_one_bit_run_lengths_successive(n) = {
# GP-DEFINE    my(v=one_bit_run_lengths(n));
# GP-DEFINE    v==vector(#v,n,n); \\ && #v>=4;
# GP-DEFINE  }
#
# GP-Test  select_first_n(is_one_bit_run_lengths_successive,20)
# GP-Test  apply(to_binary,select_first_n(is_one_bit_run_lengths_successive,30))
# not in OEIS: 1, 2, 4, 8, 11, 16, 19, 22, 32, 35, 38, 44, 64, 67, 70, 76, 88, 128, 131
# not in OEIS: 1, 10, 100, 1000, 1011, 10000, 10011, 10110, 100000, 100011, 100110, 101100, 1000000, 1000011, 1000110, 1001100, 1011000, 10000000, 10000011
#
# with >=4 runs
# GP-Test  select_first_n(is_one_bit_run_lengths_successive,20)
# GP-Test  apply(to_binary,select_first_n(is_one_bit_run_lengths_successive,30))
# not in OEIS: 5871, 9967, 11503, 11727, 11742, 18159, 19695, 19919, 19934, 22767, 22991, 23006, 23439, 23454, 23484, 34543, 36079, 36303, 36318, 39151
# not in OEIS: 1011011101111, 10011011101111, 10110011101111, 10110111001111, 10110111011110, 100011011101111, 100110011101111, 100110111001111, 100110111011110, 101100011101111, 101100111001111, 101100111011110, 101101110001111, 101101110011110, 101101110111100
#
# uninteresting  18159  0b100011011101111
