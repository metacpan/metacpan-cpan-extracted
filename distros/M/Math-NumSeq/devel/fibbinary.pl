#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2020, 2021 Kevin Ryde

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
use Math::NumSeq::Fibonacci;
*_bit_split_hightolow = \&Math::NumSeq::Fibonacci::_bit_split_hightolow;

# uncomment this to run the ### lines
#use Smart::Comments;

{
  require FLAT;
  require MyFLAT;
  my $bin = FLAT::Regex->new('(1 0 0 0* )* (0 | 1 | 1 0 | [])');
  my $dec = FLAT::Regex->new('0 | (1 | 10 | 100*)* (1 | 10 | 100*)');
  print $bin->as_string,"\n";;
  print $dec->as_string,"\n";;
  $bin = $bin->as_min_dfa->MyFLAT::set_name('BIN');;
  $dec = $dec->as_dfa;
  print "has 11 = ",$dec->contains('11'),"\n";

  my $not = FLAT::Regex->new('(0|1)* (1 1  |  1 0 1) (0|1)*')->as_min_dfa->MyFLAT::set_name('NOT');
  my $any = FLAT::Regex->new('[] | 1 (0 | 1)*')->as_min_dfa->MyFLAT::set_name('ANY');
  print "ANY: ",$any->as_summary,"\n\n";
  print "NOT: ",$any->as_summary,"\n\n";
  my $notnot = $any->difference($not)->as_min_dfa->MyFLAT::set_name('NOTNOT');
  MyFLAT::FLAT_show_breadth($notnot,5,'hightolow',radix=>2);
  print "$bin\n";
  print "$notnot\n";
  print "BIN",$bin->as_summary,"\n\n";
  print "NOTNOT",$notnot->as_summary,"\n\n";
  MyFLAT::FLAT_check_is_equal($notnot,$bin);

  print $bin->equals($dec),"\n";
  MyFLAT::FLAT_check_is_equal($bin,$dec);

  exit 0;
}
{
  # 0
  # 1
  # 2
  # 3   11   1+2=3
  # 4  100   3
  # 6  110
  # 7  111
  # 8 1000
  # 9, 12, 14, 15, 16, 18, 19, 24, 25,
                      
  my @A336231_samp = (0, 1, 2, 3, 4, 6, 7, 8, 9, 12, 14, 15, 16, 18, 19, 24, 25,
                      28, 30, 31, 32, 33, 36, 38, 39, 48, 50, 51, 56, 57, 60, 62,
                      63, 64, 66, 67, 72, 73, 76, 78, 79, 96, 97, 100, 102, 103,
                      112, 114, 115, 120, 121, 124, 126, 127, 128, 129, 132, 134,
                      135, 144, 146, 147, 152);
  my $seq = Math::NumSeq::Fibbinary->new;
  foreach my $i (0 .. 20) {
    my $value = $seq->ith($i);
    print from_Zeckendorf_bits($value),",";
  }
  print "\n";

  foreach my $n (0 .. $#A336231_samp) {
    my $value = $A336231_samp[$n];
    print from_Zeckendorf_bits($value),",";
  }
  print "\n";
  exit 0;

  sub from_Zeckendorf_bits {
    my ($value) = @_;
    my @bits = _bit_split_hightolow($value);
    my @fibs;
    {
      my $f0 = ($value * 0);  # inherit bignum 0
      my $f1 = $f0 + 1;       # inherit bignum 1
      foreach (0 .. $#bits) {
        ($f1,$f0) = ($f1+$f0,$f1);
        push @fibs, $f1;
      }
    }
    if (@bits) {
      shift @bits;
      unshift @bits, 1,0;
      unshift @fibs, 0;
    }
    my $i = 0;
    foreach my $bit (@bits) {  # high to low
      my $fib = pop @fibs;
      if ($bit) { $i += $fib; }
    }
    return $i;
  }
}
{
  my @A334413_samp = (1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0,\
                      1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1,\
                      0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1,\
                      1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0,\
                      1, 1, 0, 1, 1, 0, 1, 0, 1);
  my $fib = Math::NumSeq::Fibbinary->new;
  foreach my $n (0 .. $#A334413_samp) {
    if ($A334413_samp[$n]) {
      my $z = $n && $fib->ith($n);
      my $zb = $z && sprintf '%b', $z;
      print "$zb\n";
    }
  }
  exit 0;
}
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
