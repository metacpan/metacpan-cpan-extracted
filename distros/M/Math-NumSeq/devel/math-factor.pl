#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

# use blib "$ENV{HOME}/p/fx/38_02/blib";
use Math::Factor::XS 'prime_factors';

use 5.004;
use strict;
use Math::Factor::XS 'factors','matches','prime_factors';

# uncomment this to run the ### lines
use Smart::Comments;

{
  # factors() is slower, maybe due to arg checking overhead
  require Devel::TimeThis;

  my $class = 'Math::NumSeq::DivisorCount';
  $class = 'Math::NumSeq::LiouvilleFunction';
  $class = 'Math::NumSeq::MobiusFunction';
  $class = 'Math::NumSeq::PrimeFactorCount';
  $class = 'Math::NumSeq::PowerPart';
  eval "require $class";

  my $num = 100000;
  {
    my $seq = $class->new;
    my $t = Devel::TimeThis->new('ith');
    foreach (1 .. $num) {
      $seq->ith($_);
    }
  }
  {
    my $seq = $class->new;
    my $t = Devel::TimeThis->new('next');
    foreach (1 .. $num) {
      $seq->next;
    }
  }
  {
    my $t = Devel::TimeThis->new('factors');
    foreach (1 .. $num) {
      factors($_);
    }
  }
  # {
  #   my $t = Devel::TimeThis->new('xs_factors');
  #   foreach (1 .. $num) {
  #     Math::Factor::XS::xs_factors($_);
  #   }
  # }
  exit 0;
}

{
  # factors() on Math::BigInt
  require Math::BigInt;
  my $small = 123;
  my $big = Math::BigInt->new(123);
  print factors($small),"\n";
  print factors($big),"\n";
  exit 0;
}

{
  require Devel::TimeThis;
  require Math::NumSeq::PrimeFactorCount;
  my $seq = Math::NumSeq::PrimeFactorCount->new;

  my $num = 50000;
  {
    my $t = Devel::TimeThis->new('ith');
    foreach (1 .. $num) {
      $seq->ith($_);
    }
  }
  {
    my $t = Devel::TimeThis->new('prime_factors');
    foreach (1 .. $num) {
      my @f = prime_factors($_);
      scalar(@f);
    }
  }
  exit 0;
}

{
  # 1       1      1  +2
  # 3
  # 5       5
  # 7       7      7  +6
  # 9
  # 11     11     11  +4
  # 13     13     13  +2
  # 15
  # 17     17     17  +4
  # 19     19     19  +2
  # 21
  # 23     23     23  +4
  # 25     25
  # 27
  # 29     29     29  +6
  #
  # 2,6,4,2,
  # 4,2,4,6
  #
  # 11   ^01
  # 01   ^10
  # 11   ^10
  # 10   ^01
  # 01   ^11
  # 10   ^11
  # 01   ^11
  # 10   ^11
  #
  my $prev = -1;
  my $prev_d = 6;
  foreach my $i (0 .. 29) {
    next unless $i % 2;
    next unless $i % 3;
    next unless $i % 5;
    my $d = $i-$prev;
    printf "%2d  %+d  %+d\n", $i, $d, $d-$prev_d;
    $prev = $i;
    $prev_d = $d;
  }
  exit 0;
}



{
  require Math::NumSeq::DivisorCount;
  my $seq = Math::NumSeq::DivisorCount->new;
  foreach my $i (2 .. 2500) {
    my @f = factors($i);
    my $f = scalar(@f) + 2;
    my $ith = $seq->ith($i);
    $f == $ith or die "$f == $ith";
  }
  exit 0;
}

{
  print join(', ', factors(30)),"\n";
  ### factors(): factors(12345)
  ### factors(): factors(65536)
  ### factors(): factors(2*3*5*7)
  exit 0;
}

{
  foreach my $i (1 .. 32) {
    my $sign = 1;
    my $t = 0;
    for (my $bit = 1; $bit <= $i; $bit <<= 1, $sign = -$sign) {
      if ($i & $bit) {
        $t += $sign * $bit;
      }
    }
    print "$i  $t\n";
  }
  exit  0;
}

{
  { package MyTie;
    sub TIESCALAR {
      my ($class) = @_;
      return bless {}, $class;
    }
    sub FETCH {
      print "fetch\n";
      return { skip_multiples => 1 };
    }
  }
  my $t;
  tie $t, 'MyTie';

  {
    my @ret = matches(12,[2,2,3,4,6],{ skip_multiples => 1 });
    ### matches(): @ret
  }
  {
    my @ret = matches(12,[2,2,3,4,6],$t);
    ### matches(): @ret
  }
  for (;;) { matches(12,[2,2,3,4,6]); }
  exit 0;
}



{
  for (;;) {
    factors(12345);
  }
  exit 0;
}
