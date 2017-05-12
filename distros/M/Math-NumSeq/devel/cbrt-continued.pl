#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
use List::Util 'min','max';
use Math::Libm 'cbrt';
use Math::NumSeq;
BEGIN { Math::NumSeq::_bigint(); }
use Math::BigRat;

# uncomment this to run the ### lines
use Smart::Comments;

# c = cbrt(7)
# (c-1)*(c^2+c+1)
# = c^3-c^2 + c^2-c +c-1
# = c^3-1=6
# 1/(c-1) = (c^2+c+1)/6
#
# (c^2+c+1)/6-1
#  = (c^2+c+1-6)/6
#  = (c^2+c-5)/6
#
# (c^2+c-5)*(c - 1)
#  = c^3+c^2-5c - c^2-c+5
#  = c^3 -5c-c + 5
#  = c^3 -6c + 5
#
#


{
  # common factor
  require Math::NumSeq::CbrtContinued;
  foreach my $cbrt (2000 .. 2016) {
    my $seq = Math::NumSeq::CbrtContinued->new (cbrt => $cbrt);
    foreach (1 .. 1000) {
      my ($i, $value) = $seq->next or last;
      my $g = gcd($seq->{'p'},
                  $seq->{'q'},
                  $seq->{'r'},
                  $seq->{'s'});
      if ($g > 1) {
        print "$i gcd=$g\n";
      }
    }
    # print "final values\n";
    # print "p ", $seq->{'p'}, "\n";
    # print "q ", $seq->{'q'}, "\n";
    # print "r ", $seq->{'r'}, "\n";
    # print "s ", $seq->{'s'}, "\n";
    print "final sizes\n";
    print "p ", $seq->{'p'}->babs->blog(2), "\n";
    print "q ", $seq->{'q'}->babs->blog(2), "\n";
    print "r ", $seq->{'r'}->babs->blog(2), "\n";
    print "s ", $seq->{'s'}->babs->blog(2), "\n";
  }
  exit 0;
}

{
  # A002945 - cbrt(2)  1,3,1,5,1,1,4,1,1,8,1,14,1,10,2,1,4,12,2,3,2,1,3,

  $| = 1;

  # rem = (aR+b)/(cR+d)
  # 1/(cR+d) = (R^2)/(cR^3+dR^2)
  #          = (R^2 - d/c*R)/(cR^3+dR^2 -dR^2+d^2/cR)
  #          = (R^2 - d/c*R + d^2/c^2)/(cR^3+dR^2 -dR^2-d^2/cR + d^2cR+d^3/c^2)
  #          = (R^2 - d/c*R + d^2/c^2)/(cR^3 + d^3/c^2)
  #          = (R^2 - d/c*R + d^2/c^2)/(c*C + d^3/c^2)
  #          = (c^2*R^2 - c*d*R + d^2)/(c^3*C + d^3)
  #
  # rem-k = (aR+b)/(cR+d) - k
  #       = (aR+b - kcR-dk)/(cR+d)
  # 1/(rem-k) = (cR+d)/((a-kc)R+(b-dk))
  #
  #
  my $cbrt = Math::BigInt->new(2);

  my $a = Math::BigInt->new(1);
  my $b = Math::BigInt->new(0);
  my $c = Math::BigInt->new(0);
  my $d = Math::BigInt->new(1);

  my $prec = 2000;
  my $R = Math::BigInt->new(2) * Math::BigInt->new(10)**(3*$prec);
  $R->broot(3);
  $R = Math::BigRat->new ($R, Math::BigInt->new(10)**$prec);

  $R = cbrt($cbrt);
  $R = Math::BigRat->new($R);

  for (1 .. 20) {
    print "$a,$b $c,$d   ";
    # my $int = (($R*$a+$b) * ($R*$R*$c*$c - $c*$d*$R + $d*$d)
    #            / ($c*$c*$c*$cbrt + $d*$d*$d));
    # my $int = (($R*$a+$b) * ($R*$R*$c*$c - $c*$d*$R + $d*$d)
    #            / ($R*$R*$R*$c*$c*$c + $d*$d*$d));
    my $int = (($R*$a+$b) * ($R*$R*$c*$c - $c*$d*$R + $d*$d)
               / (($R*$c+$d)*($R*$R*$c*$c - $c*$d*$R + $d*$d)));
    print "    ",$int->numify;
    # $int = ($R*$a+$b)/($R*$c+$d);
    # print "    ",$int->numify;
    $int = int($int);
    print "    int=$int";

    # -277,349 504,-635       8    8
    # 504,-635 -4309,5429       1    1

    # -277,349 504,-635       32900188820497533996257785164673222257265861/3953125000000000000000000000000000000000000    8
    # 504,-635 -4309,5429
    # 717562848155049611144510629999065280250205603
    # 722125000000000000000000000000000000000000000    0



    # (aC+b)/(cC+d) - j >= 0
    # (aC+b) - j*(cC+d) >= 0
    # aC + b - jcC - jd >= 0
    # (a-jc)C >= (jd-b)
    # CC*(a-jc)^3 >= (jd-b)^3
    # CC*(a-jc)^3 - (jd-b)^3 >= 0
    #  (-d^3 - c^3*CC)*j^3
    #  + (3*b*d^2 + 3*c^2*a*CC)*j^2
    #  + (-3*b^2*d - 3*c*a^2*CC)*j
    #  + (b^3 + a^3*CC)
    # p = -d^3 - c^3*CC
    # q = 3*b*d^2 + 3*c^2*a*CC
    # r = -3*b^2*d - 3*c*a^2*CC
    # s = b^3 + a^3*CC

    my $a2 = $a*$a;
    my $b2 = $b*$b;
    my $c2 = $c*$c;
    my $d2 = $d*$d;
    my $cbrt3 = 3*$cbrt*$d;
    my $p = -$d*$d2 - $c*$c2 * $cbrt;
    my $q = 3*$b*$d2 + $c2*$a * $cbrt3;
    my $r = -3*$b2*$d - $c*$a2 * $cbrt3;
    my $s = $b*$b2 + $a2*$a * $cbrt;
    ### p: "$p"
    ### q: "$q"
    ### r: "$r"
    ### s: "$s"

    my $poly = sub {
      my ($j) = @_;
      return (($p*$j + $q)*$j + $r)*$j + $s;
    };

    my $lo = 0;
    my $hi = 1;
    while ($poly->($hi) >= 0) {
      ### lohi: "$lo,$hi  poly ".$poly->($lo)." ".$poly->($hi)
      ### assert: $poly->($lo) >= 0
      ($lo,$hi) = ($hi,2*$hi);
    }
    my $j;
    for (;;) {
      ### $j
      ### assert: $poly->($lo) >= 0
      ### assert: $poly->($hi) < 0
      $j = int(($lo+$hi)/2);
      if ($j == $lo) {
        last;
      }
      if ($poly->($j) >= 0) {
        $lo = $j;
      } else {
        $hi = $j;
      }
    }
    print " j=$j";
    print "\n";


    $int = $j;
    ($a,$b,$c,$d) = ($c,
                     $d,
                     $a-$int*$c,
                     $b-$int*$d);

    # my $g = gcd($a,$b,$c,$d);
    # if ($g > 1) {
    #   print "  gcd=$g\n";
    #   $a /= $g;
    #   $b /= $g;
    #   $c /= $g;
    #   $d /= $g;
    # }
  }
  print "\n";

  sub gcd {
    my $g = shift;
    require Math::PlanePath::GcdRationals;
    while (@_) {
      $g = Math::PlanePath::GcdRationals::_gcd($g,shift);
    }
    return $g;
  }


  exit 0;
}

