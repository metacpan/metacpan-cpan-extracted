#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

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

require 5;
use strict;
use Math::NumSeq::Fibbinary;

# uncomment this to run the ### lines
#use Smart::Comments;

{
  # Fibbinary ith() vs Math::Fibonacci decompose()

  require Math::Fibonacci;
  {
    require Math::NumSeq::Fibonacci;
   my $fibonacci = Math::NumSeq::Fibonacci->new;
    my $fibbinary = Math::NumSeq::Fibbinary->new;
  my @fib;
    sub my_decompose {
      my ($n) = @_;
      $n = $fibbinary->ith($n) || return 0;
      my @ret;
      for (my $i = 2; $n; $i++,$n>>=1) {
        if ($n & 1) {
          push @ret, ($fib[$i] ||= $fibonacci->ith($i));
        }
      }
      return reverse @ret;
    }
  }
  foreach my $n (0 .. 10000000) {
    my @sum = Math::Fibonacci::decompose($n);
    my @fff = my_decompose($n);
    my $sum = join(',',@sum);
    my $fff = join(',',@fff);
    if ($sum ne $fff) {
      print "$n  $sum $fff\n";
      die;
    }
  }
  exit 0;
}

{
  # value_to_i_floor()
  # value=2^31  at i=3,524,578
  # value=2^32  at i=5,702,887
  # value=2^64  at i=27,777,890,035,288

  require Math::BigInt;
  my $seq = Math::NumSeq::Fibbinary->new;
  foreach my $k (0 .. 64) {
    my $value = Math::BigInt->new(2)**$k;
    my $i = $seq->value_to_i_floor($value);
    printf "%d  i=%d value=%b\n", $k, $i, $value;
  }
  exit 0;
}

{
  # value_to_i_estimate()

  my $seq = Math::NumSeq::Fibbinary->new;
  my $prev_value = 0;
  foreach (1..5600) {
    my ($i, $value) = $seq->next;

    # foreach my $try_value ($prev_value+1 .. $value-1) {
    #   my $est_i = $seq->value_to_i_estimate($try_value);
    #   if (ref $est_i) { $est_i = $est_i->numify }
    #   my $factor = $est_i / ($i||1);
    #   printf "x  est=%d   tvalue=%b  f=%.3f\n",
    #     $est_i, $try_value, $factor;
    # }

    {
      # require Math::BigInt;
      # $value = Math::BigInt->new($value);

      my $est_i = $seq->value_to_i_estimate($value);
      if (ref $est_i) { $est_i = $est_i->numify }
      my $factor = $est_i / ($i||1);
      printf "i=%d est=%d   value=%b  f=%.3f\n", $i, $est_i, $value, $factor;
    }

    $prev_value = $value;
  }
  exit 0;
}

{
  # 2^32 F(k) = 3,524,578
  # 2^64 F(k) = 27,777,890,035,288 = 44 bits
  my $f0 = 0;
  my $f1 = 1;
  foreach my $i (0 .. 70) {
    ($f1,$f0) = ($f1+$f0,$f1);
    my $fibbinary = Math::NumSeq::Fibbinary->ith($f1);
    my $bits = sprintf "%b", $fibbinary;
    my $len = length($bits);
    printf "$i $f1  $len  $bits\n";
  }
  exit 0;
}
