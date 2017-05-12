#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use POSIX;
use List::Util 'max','min';
use Math::NumSeq::Fibonacci;
use Math::NumSeq::FibonacciRepresentations;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # print array by rows

  my $seq = Math::NumSeq::FibonacciRepresentations->new;
  my ($v0,$v1) = $seq->ith_pair(12);
  print "ith_pair  $v0  $v1\n";
  exit 0;
}
{
  # print array by rows

  my $depth = 10;

  my $fib = Math::NumSeq::Fibonacci->new;
  my $diatomic = Math::NumSeq::FibonacciRepresentations->new;

  my $width = $fib->ith($depth);
  foreach my $y (1 .. $depth) {
    my $i_lo = $fib->ith($y)-1;
    my $i_hi = $fib->ith($y+1)-1;
    foreach my $i ($i_lo .. $i_hi) {
      my $r = $diatomic->ith($i);
      printf "%1d ",$r;
    }
    print "      i=$i_lo to $i_hi\n";
  }
  exit 0;

  # 1                                         1
  # 1                    2                    1
  # 1               2         2               1
  # 1       3       2         2       3       1
  # 1     3   3     2    4    2     3   3     1
  # 1  4  3   3  5  2   4 4   2  5  3   3  4  1
  # 1 4 4 3 6 3 5 5 2 6 4 4 6 2 5 5 3 6 3 4 4 1

  # 1 5 4 4 7 3 6 6 3 8 5 5 7 2 6 6 4 8 4 6 6 2 7 5 5 8 3 6 6 3 7 4 4 5 1

}
{
  # vs A000119
  require Math::NumSeq::Fibbinary;
  require Math::NumSeq::OEIS::File;
  my $zeck = Math::NumSeq::Fibbinary->new;
  my $diatomic = Math::NumSeq::FibonacciRepresentations->new;
  my $oeis = Math::NumSeq::OEIS::File->new(anum=>'A000119');
  foreach my $i (0 .. 3) {
    my $z = $zeck->ith($i);
    my $got = $diatomic->ith($i);
    my $want = $oeis->ith($i);
    my $diff = ($got == $want ? '' : '  ***');
    printf "i=%2d z=%8b  $want $got$diff\n",
      $i, $z;
  }
  exit 0;
}
{
  # R(i) and R(i+1)

  # 0-bit
  # down_r = r0+r1 when z1 = z-1 has low 1-zeck
  # which is z even trailing zero bits
  #
  # 1-bit
  # down_r unchanged always
  # down_r1

  # 4 = 101
  # r     = 1   R(1) = 1
  # rsub1 = 0   R(0) = 1
  #
  # 0-bit, even trailing, no change
  # r     = 10  R(2) = 1
  # rsub1 =  1  R(1) = 1
  #
  # r     = 101  R(4) = 1
  # rsub1 = 100  R(3) = 2

  # 16 = 100100
  # r     = 1   R(1) = 1
  # rsub1 = 0   R(0) = 1
  #
  # r     = 10   R(2) = 1
  # rsub1 =  1   R(1) = 1
  #
  # r     = 100  R(3) = 2
  # rsub1 =  10  R(2) = 1
  #
  # r     = 1001  R(6) = 2
  # rsub1 = 1000  R(5) = 2

  # 3 = 100
  # r      = 0   R(0) = 1
  # rplus1 = 1   R(1) = 1
  #
  # r      =  1   R(1) = 1
  # rplus1 = 10   R(2) = 1
  #
  # r      =  10  R(2) = 1
  # rplus1 = 100  R(3) = 2
  #
  # r      = 100  R(3) = 2
  # rplus1 = 101  R(4) = 1
  #
  #   001   0010  00101  001010   0010101   
  #   010   0100  01000  010000   0100000   trailing zeros
  #   odd   even   odd    even     odd
  # 10 is 00 in i+1 at low end, but no change above low

  require Math::NumSeq::Fibbinary;
  require Math::NumSeq::OEIS::File;
  my $zeck = Math::NumSeq::Fibbinary->new;
  my $fib = Math::NumSeq::Fibonacci->new;
  my $diatomic = Math::NumSeq::OEIS::File->new(anum=>'A000119');
  # my $diatomic = Math::NumSeq::FibonacciRepresentations->new;

  $fib->next;
  $fib->next;
  (undef, my $target) = $fib->next;
  my $delta = -1;
  my %saw_types;
  for my $i (1 .. $fib->ith(14)) {
    if ($i >= $target) {
      print "\n";
      (undef, $target) = $fib->next;
    }
    my $i1 = $i + $delta;
    my $z = $zeck->ith($i);
    my $z1 = $zeck->ith($i1);
    my $r0 = $diatomic->ith($i);
    my $r1 = $diatomic->ith($i1);

    foreach my $bit (0,
                     # ($z & 1) ? () : (1)
                    ) {
      my $down_z = 2*$z + $bit;
      my $down_i = $zeck->value_to_i($down_z) // die;
      my $down_r = $diatomic->ith($down_i);
      my $down_i1 = $down_i + $delta;
      my $down_r1 = $diatomic->ith($down_i1);
      my $down_z1 = $zeck->ith($down_i1);

      my $down_type = '?';
      if ($down_r == $r0 && $down_r == $r1) {
        $down_type = 'r0=r1';
      } elsif ($down_r == $r0) {
        $down_type = 'r0';
      } elsif ($down_r == $r1) {
        $down_type = 'r1';
      } elsif ($down_r == $r0 + $r1) {
        $down_type = 'r0 + r1';
      }

      my $down_type1 = '?';
      if ($down_r1 == $r0 && $down_r1 == $r1) {
        $down_type1 = 'r0=r1';
      } elsif ($down_r1 == $r0) {
        $down_type1 = 'r0';
      } elsif ($down_r1 == $r1) {
        $down_type1 = 'r1';
      } elsif ($down_r1 == $r0 + $r1) {
        $down_type1 = 'r0 + r1';
      }

      my $star = ' ';;
      if ($bit == 0) {
        $star = (0 && end_10_p($z) && end_01_p($z1)
                 ? '*' : ' ');  # no ?
        $star = ($z1 & 1 ? '*' : ' '); # yes
        $star = (count_low_0_bits($z) & 1 ? '*' : ' '); # yes
      } else {
        # $star = ($z & 1 ? '*' : ' ');
        $star = (count_low_0_bits($z) & 1 ? '*' : ' ');
      }
      my $bad = ($bit == 0 && ($star eq '*') ne ($down_type eq 'r0 + r1') ? '  bad' : '');
      my $bad1 = ($bit == 1 && ($star eq '*') ne ($down_type1 eq 'r0 + r1') ? '  bad' : '');

      printf "z  %12b  $bit-bit\n", $z;
      printf "z1 %12b\n", $z1;
      printf "   %12b %-7s    %2d %2d -> %2d $star $bad\n",
        $down_z, $down_type, $r0, $r1, $down_r;
      printf "   %12b %-7s    %2d %2d -> %2d $star $bad1\n",
        $down_z1, $down_type1, $r0, $r1, $down_r1;
      print "\n";

      my $z_end = sprintf '%04b', $z & 0b1111;
      my $z1_end = sprintf '%04b', $z1 & 0b1111;
      $saw_types{$bit}->{'z-e'}->{$z_end}->{$down_type} = 1;
      $saw_types{$bit}->{'z1-e'}->{$z1_end}->{$down_type} = 1;
      $saw_types{$bit}->{'z-e1'}->{$z_end}->{$down_type1} = 1;
      $saw_types{$bit}->{'z1-e1'}->{$z1_end}->{$down_type1} = 1;
    }
  }
  # ### types: %saw_types

  exit 0;

  sub count_low_0_bits {
    my ($n) = @_;
    if ($n <= 0) {
      return 0;
    }
    my $count = 0;
    until ($n % 2) {
      $count++;
      $n /= 2;
    }
    return $count;
  }
}

{
  # zeck
  require Math::NumSeq::Fibbinary;
  my $zeck = Math::NumSeq::Fibbinary->new;
  my $fib = Math::NumSeq::Fibonacci->new;
  my $diatomic = Math::NumSeq::FibonacciRepresentations->new;

  $fib->next;
  $fib->next;
  (undef, my $target) = $fib->next;
  for my $i (1 .. $fib->ith(12)) {
    if ($i >= $target) {
      print "\n";
      (undef, $target) = $fib->next;
    }
    my $z = $zeck->ith($i);
    my $d = $diatomic->ith($i);
    my $z_next = $zeck->ith($i+1);
    my $z_prev = $zeck->ith($i-1);

    my $p = $z >> 1;
    my $pi = $zeck->value_to_i($p);
    my $pd = $diatomic->ith($pi);

    my $qi = $pi-1;                  # q at i-1
    my $q = $zeck->ith($qi);
    my $qd = $diatomic->ith($qi);

    my $which;
    if ($d == $pd) { $which = 'p'; }
    elsif ($d == $qd) { $which = 'q'; }
    elsif ($d == $pd + $qd) { $which = 'p+q'; }
    else { $which = ''; }

    my $star = ((! end_101_p($z_next) && end_101_p($z_prev))
                || (! end_101_p($z_prev) && end_101_p($z_next))
                ? '*'
                : ' ');
    $star = (end_1010_p($z_prev) || end_101_p($z_next)
             ? '*' : ' ');
    $star = (end_01_p($q)        # wrong
             ? '*' : ' ');
    $star = (end_10_p($p) && end_01_p($q)   # right for low 0-bit
             ? '*' : ' ');

    my $bad = (($star eq '*') ne ($which eq 'p+q') ? '  bad' : '');
    printf "%3d %8b%s %2d   %7b %2d %2d %7b  %-3s%s\n",
      $i, $z,$star, $d,
        $p, $pd, $qd, $q,
          $which, $bad;
  }
  exit 0;

  sub end_10_p {
    my ($n) = @_;
    return (($n & 0b11) == 0b10);
  }
  sub end_01_p {
    my ($n) = @_;
    return (($n & 0b11) == 0b01);
  }
  sub end_101_p {
    my ($n) = @_;
    return (($n & 0b111) == 0b101);
  }
  sub end_1010_p {
    my ($n) = @_;
    return (($n & 0b1111) == 0b1010);
  }

  #     101010010
  #     101010001
  #     101010010
  #
  #     101010000
  #     101010001
  # 138 1010100010   4     4  7   p
  # 139 1010100100*  8     4  4   p+q
  # 140 1010100101*  4     4  4 101010001  p    bad
  #
  #
  # 101010001
  # 1010100010
  # 101010010
  # 1010100100
  #
  # 101010001     *2+1
  # 1010100100
  # 101010010     *2+1
  # 1010100101
}
