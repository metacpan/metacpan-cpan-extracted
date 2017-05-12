#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2016 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
use POSIX ();

# uncomment this to run the ### lines
use Smart::Comments;

{
  use Math::BigInt;
  my $b = Math::BigInt->new('463168356949264781694283940034751631414441068130246010011683834461379591405565');
  $b->bsqrt;
  print "$b\n";
  my $f = Math::BigRat->new('463168356949264781694283940034751631414441068130246010011683834461379591405565');
  ### $f
  print " = $f\n";
  $f->bsqrt;
  print "$f\n";
  my $n = Math::BigRat->new('57896044618658097711785492504343953926805133516280751251460479307672448925696');
  $n -= 1;
  my $r = 8*$n + 5;
  ### $r
  print " = $r\n";
  $r = sqrt(int($r));
  print "$r\n";
  exit 0;
}
{
  print int(sqrt(24));
  exit 0;
}

{
  use Math::BigRat;
  my $f = Math::BigRat->new('-1/2');
  ### $f
  my $int = int($f);
  ### $f
  ### $int
  my $result = ($int == 0);
  print $result ? "yes\n" : "no\n";
  exit 0;
}

{
  use Math::BigFloat;
  Math::BigFloat->accuracy(10);  # significant digits
  print int(Math::BigFloat->new('64.5')),"\n";
  exit 0;
}

# my $inf = 2**99999;
# my $nan = $inf/$inf;
# print "$inf, $nan","\n";
# print $nan==$nan,"\n";
# print $nan<=>0,"\n";
# print 0<=>$nan,"\n";

{
  use Math::BigFloat;
  Math::BigFloat->accuracy(15);
  my $n = Math::BigFloat->new(1);
  $n->accuracy(50);
  $n->batan2(.00000000, 100);
  print "$n\n";
  exit 0;
}
{
  use Math::BigFloat;
  my $n = Math::BigFloat->new('1.234567892345678923456789');
  $n->accuracy(15);
  # my $pi = $n->bpi(undef);
  # my $pi = Math::BigFloat->bpi;

   $n = Math::BigFloat->new(1);
  print "$n\n";
  $n->accuracy(10);
  my $pi = $n->batan2(.0000001);
  print "$pi\n";
  exit 0;
}
{
  use Math::BigFloat;
  # Math::BigFloat->precision(5);
  # Math::BigFloat->precision(-5);
  Math::BigFloat->accuracy(13);
  # my $n = Math::BigFloat->new('123456789.987654321');
  my $n = Math::BigFloat->bpi(50);
  print "$n\n";
  exit 0;
}

{
  use Math::BigFloat;
  my $n = Math::BigFloat->new(1234);
  ### accuracy: $n->accuracy()
  ### precision: $n->precision()
  my $global_accuracy = Math::BigFloat->accuracy();
  my $global_precision = Math::BigFloat->precision();
  ### $global_accuracy
  ### $global_precision
  my $global_div_scale = Math::BigFloat->div_scale();
  ### $global_div_scale

  Math::BigFloat->div_scale(500);
  $global_div_scale = Math::BigFloat->div_scale();
  ### $global_div_scale
  ### div_scale: $n->div_scale

  $n = Math::BigFloat->new(1234);
  ### div_scale: $n->div_scale


  exit 0;
}

{
  require Math::Complex;
  my $c = Math::Complex->new(123);
  ### $c
  print $c,"\n";
  print $c * 0,"\n";;
### int: int($c)
  print int($c),"\n";;
  exit 0;
}

{
  require Math::BigRat;

  use Math::BigFloat;
  Math::BigFloat->precision(2000);  # digits right of decimal point
  Math::BigFloat->accuracy(2000);

  {
    my $x = Math::BigRat->new('1/2') ** 512;
    print "$x\n";
    my $r = sqrt($x);
    print "$r\n";
    print $r*$r,"\n";

    # my $r = 8*$x-3;
    # print "$r\n";
  }
  exit 0;
  {
    my $x = Math::BigInt->new(2) ** 128 - 1;
    print "$x\n";
    my $r = 8*$x-3;
    print "$r\n";
  }
  {
    my $x = Math::BigRat->new('100000000000000000000'.('0'x200));
    $x = $x*$x-1;
    print "$x\n";
    my $r = sqrt($x);
    print "$r\n";
     $r = int($r);
    print "$r\n";
  }
}
