#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use List::Util qw(max);
use Devel::Comments;

{
  require Math::PlanePath::DiamondArms;
  my @max;
  my $path = Math::PlanePath::DiamondArms->new;
  foreach my $n (2 .. 10000) {
    my ($x,$y) = $path->n_to_xy($n);
    $x = abs($x);
    $y = abs($y);
    my $d = abs($x)+abs($y);
    $max[$d] ||= 0;
    $max[$d] = max($max[$d], $n);
  }
  ### @max
  exit 0;
}
{
  require Math::PlanePath::HexArms;
  my @max;
  my $path = Math::PlanePath::HexArms->new;
  foreach my $n (2 .. 10000) {
    my ($x,$y) = $path->n_to_xy($n);
    $x = abs($x);
    $y = abs($y);
    my $d = ($y >= $x
             ? $y                 # middle
             : ($x + $y)/2);  # end
    $max[$d] ||= 0;
    $max[$d] = max($max[$d], $n);
  }
  ### @max
  exit 0;
}
{
  # cf A094268 smallest of N consecutive abundants
  # 5775 pair (3,4 mod 6)
  # 171078830 triplet (2,3,4 mod 6)
  # 141363708067871564084949719820472453374 first run of 4 consecutive
  #
  # cf A047802 first abundant not using the first N primes
  #
  my $limit = 33426748355;
  my $min = $limit;

  my $divsum = 1;
  for (my $p5 = 0; ; $p5++) {
    my $value = 5**$p5;
    last if $value > $limit;
    my $divsum = (5**($p5+1) - 1) / 4;

    for (my $p7 = 0; ; $p7++) {
      my $value = $value * 7**$p7;
      last if $value > $limit;
      my $divsum = $divsum * (7**($p7+1) - 1) / 6;

      for (my $p11 = 0; ; $p11++) {
        my $value = $value * 11**$p11;
        last if $value > $limit;
        my $divsum = $divsum * (11**($p11+1) - 1) / 10;

        for (my $p13 = 0; ; $p13++) {
          my $value = $value * 13**$p13;
          last if $value > $limit;
          my $divsum = $divsum * (13**($p13+1) - 1) / 12;

          for (my $p17 = 0; ; $p17++) {
            my $value = $value * 17**$p17;
            last if $value > $limit;
            my $divsum = $divsum * (17**($p17+1) - 1) / 16;

            for (my $p19 = 0; ; $p19++) {
              my $value = $value * 19**$p19;
              last if $value > $limit;
              my $divsum = $divsum * (19**($p19+1) - 1) / 18;

              for (my $p23 = 0; ; $p23++) {
                my $value = $value * 23**$p23;
                last if $value > $limit;
                my $divsum = $divsum * (23**($p23+1) - 1) / 22;

                for (my $p29 = 0; ; $p29++) {
                  my $value = $value * 29**$p29;
                  last if $value > $limit;
                  my $divsum = $divsum * (29**($p29+1) - 1) / 28;

                  for (my $p31 = 0; ; $p31++) {
                    my $value = $value * 31**$p31;
                    last if $value > $limit;
                    my $divsum = $divsum * (31**($p31+1) - 1) / 30;

                    if ($divsum > 2*$value) {
                      print "value $value  divsum $divsum\n";
                      print "$p5 $p7 $p11 $p13 $p17 $p19 $p23 $p29 $p31\n";
                      if ($value < $min) {
                        print "  smaller\n";
                        $min = $value;
                      }
                      print "\n";
                      last;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  exit 0;
}

{
  # 7^k divisors 1,...,7^k
  #   sum = (7^(k+1)-1)/6
  #   sum/7^k = (7 - 1/7^k) / 6
  #          -> 7/6
  # single 1,7
  #   sum = 7+1 = 8
  #   sum/7 = 8/7
  #
  use Math::BigInt;
  require Math::Prime::XS;
  my @primes = Math::Prime::XS::sieve_primes(10000);
  my $prod = 1;
  my $value = 1;
  # for (my $i = 7; $i < 1000; $i += 6) {
  foreach my $i (@primes) {
    if (($i % 6) != 1
        && ($i % 6) != 5
       ) {
      next;
    }
    # my $f = $i/($i-1);
    my $f = ($i+1)/$i;

    $prod *= $f;
    $value *= $i;

    print "$i  $prod\n";

    if ($prod > 2) {
      last;
    }
  }
  print "value $value\n";
  exit 0;
}




{
  # 7^k divisors 1,...,7^k = (7^(k+1)-1)/6

  use Math::BigInt;
  foreach my $i (1 .. 200) {
    foreach my $j (0 .. 10) {
      foreach my $k (0 .. 10) {
        my $n = Math::BigInt->new(7)**$i
          * Math::BigInt->new(13)**$j
            * Math::BigInt->new(19)**$k;
        my $sd = (Math::BigInt->new(7)**($i+1) - 1) / 6
          * (Math::BigInt->new(13)**($j+1) - 1) / 12
            * (Math::BigInt->new(19)**($k+1) - 1) / 18;
        if ($sd >= 2*$n) {
          print "$i, $j   $n  $sd\n";
        }
      }
    }
  }
  exit 0;
}


{
  require Math::NumSeq::Abundant;
  my $seq = Math::NumSeq::Abundant->new (hi => 5_000_000);
  my ($max_i, $max_value);
  while (my ($i, $value) = $seq->next) {
    # my $m = ($value % 6);
    # if ($m == 1 || $m == 5) {
    #   print "$i  $value is $m mod 6\n";
    # }

    if ($value % 2) {
      print "$i  $value odd\n";
    }

    ($max_i, $max_value) = ($i, $value);
  }
  print "to $max_i  $max_value\n";
  exit 0;
}
