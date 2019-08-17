#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018, 2019 Kevin Ryde

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
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099

use Test;
plan tests => 13;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::GrayCode;

use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use Math::PlanePath::Diagonals;

sub numeq_array {
  my ($a1, $a2) = @_;
  if (! ref $a1 || ! ref $a2) {
    return 0;
  }
  my $i = 0; 
  while ($i < @$a1 && $i < @$a2) {
    if ($a1->[$i] ne $a2->[$i]) {
      return 0;
    }
    $i++;
  }
  return (@$a1 == @$a2);
}
sub to_binary_gray {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,2) ];
  Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,2);
  return digit_join_lowtohigh($digits,2);
}


#------------------------------------------------------------------------------
# A048641 - binary gray cumulative sum

{
  my $anum = 'A048641';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $cumulative = 0;
    for (my $n = 0; @got < @$bvalues; $n++) {
      $cumulative += to_binary_gray($n);
      push @got, $cumulative;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - binary gray cumulative sum");
}

#------------------------------------------------------------------------------
# A048644 - binary gray cumulative sum difference from triangular(n)

{
  my $anum = 'A048644';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $cumulative = 0;
    for (my $n = 0; @got < @$bvalues; $n++) {
      $cumulative += to_binary_gray($n);
      push @got, $cumulative - triangular($n);
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - binary gray cumulative sum");
}

sub triangular {
  my ($n) = @_;
  return $n*($n+1)/2;
}

#------------------------------------------------------------------------------
# A048642 - binary gray cumulative product

{
  my $anum = 'A048642';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    require Math::BigInt;
    my $product = Math::BigInt->new(1);
    for (my $n = 0; @got < @$bvalues; $n++) {
      $product *= (to_binary_gray($n) || 1);
      push @got, $product;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - binary gray cumulative product");
}


#------------------------------------------------------------------------------
# A048643 - binary gray cumulative product, diff to factorial(n)

{
  my $anum = 'A048643';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    require Math::BigInt;
    my $product = Math::BigInt->new(1);
    my $factorial = Math::BigInt->new(1);
    for (my $n = 0; @got < @$bvalues; $n++) {
      $product *= (to_binary_gray($n) || 1);
      $factorial *= ($n||1);

      push @got, $product - $factorial;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - binary gray cumulative product");
}


#------------------------------------------------------------------------------
# A143329 - gray(prime(n)) which is prime too

{
  my $anum = 'A143329';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  my $diff;
  if ($bvalues) {
    for (my $n = 0; @got < @$bvalues; $n++) {
      next unless is_prime($n);
      my $gray = to_binary_gray($n);
      next unless is_prime($gray);
      push @got, $gray;
    }
    $diff = MyOEIS::diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..45]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..45]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum - gray(prime(n)) which is prime too");
}


#------------------------------------------------------------------------------
# A143292 - binary gray of primes

{
  my $anum = 'A143292';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    for (my $n = 0; @got < @$bvalues; $n++) {
      next unless is_prime($n);
      push @got, to_binary_gray($n);
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - binary gray of primes");
}


#------------------------------------------------------------------------------
# A005811 - count 1 bits in gray(n), is num runs

{
  my $anum = 'A005811';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    for (my $n = 0; @got < @$bvalues; $n++) {
      my $gray = to_binary_gray($n);
      push @got, count_1_bits($gray);
    }

    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - primes for which binary gray is also prime");
}

sub count_1_bits {
  my ($n) = @_;
  my $count = 0;
  while ($n) {
    $count += ($n & 1);
    $n >>= 1;
  }
  return $count;
}


#------------------------------------------------------------------------------
# A173318 - cumulative count 1 bits in gray(n) ie. of A005811

{
  my $anum = 'A173318';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $cumulative = 0;
    for (my $n = 0; @got < @$bvalues; $n++) {
      $cumulative += count_1_bits(to_binary_gray($n));
      push @got, $cumulative;
    }

    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - primes for which binary gray is also prime");
}


#------------------------------------------------------------------------------
# A099891 -- triangle cumulative XOR
# 
{
  my $anum = 'A099891';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my @array;
    for (my $y = 0; @got < @$bvalues; $y++) {
      my $gray = to_binary_gray($y,$radix);
      push @array, [ $gray ];
      for (my $x = 1; $x <= $y; $x++) {
        $array[$y][$x] = $array[$y-1][$x-1] ^ $array[$y][$x-1];
      }
      for (my $x = 0; $x <= $y && @got < @$bvalues; $x++) {
        push @got, $array[$y][$x];
      }
    }

    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..10]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..10]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1);
}


#------------------------------------------------------------------------------
# A195467 -- diagonals powered permutation, starting from perm^0=identity
# 
{
  my $anum = 'A195467';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    require Math::PlanePath::Diagonals;
    my $diagonal_path = Math::PlanePath::Diagonals->new;

    for (my $n = $diagonal_path->n_start; @got < @$bvalues; $n++) {
      my ($x, $y) = $diagonal_path->n_to_xy ($n);
      my $digits = [ digit_split_lowtohigh($y,$radix) ];
      foreach (1 .. $x) { # x=0 unpermuted
        Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
      }
      push @got, digit_join_lowtohigh($digits,$radix);
    }

    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..10]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..10]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1);
}


#------------------------------------------------------------------------------
# A064706 - binary gray reflected permutation applied twice

{
  my $anum = 'A064706';
  my $radix = 2;

  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    for (my $n = 0; @got < @$bvalues; $n++) {
      push @got, to_binary_gray(to_binary_gray($n));
    }

    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - binary gray applied twice");
}


#------------------------------------------------------------------------------
# A055975 - binary gray first diffs

{
  my $anum = 'A055975';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $prev = 0;
    for (my $n = 1; @got < @$bvalues; $n++) {
      my $digits = [ digit_split_lowtohigh($n,$radix) ];
      Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
      my $gray = digit_join_lowtohigh($digits,$radix);
      push @got, $gray - $prev;
      $prev = $gray;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - binary gray first diffs");
}

#------------------------------------------------------------------------------
# A055975 - binary gray first diffs

{
  my $anum = 'A055975';
  my $radix = 2;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $prev = 0;
    for (my $n = 1; @got < @$bvalues; $n++) {
      my $digits = [ digit_split_lowtohigh($n,$radix) ];
      Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
      my $gray = digit_join_lowtohigh($digits,$radix);
      push @got, $gray - $prev;
      $prev = $gray;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum - binary gray first diffs");
}

#------------------------------------------------------------------------------
exit 0;
