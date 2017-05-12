#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2016 Kevin Ryde

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
use Test;

use lib 't';
use MyTestHelpers;

# uncomment this to run the ### lines
# use Smart::Comments '###';

my $test_count = (tests => 59)[1];
plan tests => $test_count;

require Math::BigFloat;
MyTestHelpers::diag ('Math::BigFloat version ', Math::BigFloat->VERSION);
{
  my $f;
  if (! eval { $f = Math::BigFloat->new(2) ** 3; 1 }) {
    MyTestHelpers::diag ('skip due to Math::BigFloat no "**" operator -- ',$@);
    MyTestHelpers::diag ('value ',$f);
    foreach (1 .. $test_count) {
      skip ('due to no Math::BigFloat "**" operator', 1, 1);
    }
    exit 0;
  }
}
unless (eval { Math::BigFloat->VERSION(1.993); 1 }) {
  # something fishy for PeanoCurve and ZOrderCurve fraction n_to_xy()
  MyTestHelpers::diag ('skip due to doubtful oldish Math::BigFloat, maybe');
  foreach (1 .. $test_count) {
    skip ('due to oldish Math::BigFloat', 1, 1);
  }
  exit 0;
}
# unless ($] > 5.008) {
#   # something fishy for BigFloat on 5.6.2, worry about it later
#   MyTestHelpers::diag ('skip due to doubtful Math::BigFloat on 5.6.x, maybe');
#   foreach (1 .. $test_count) {
#     skip ('due to Perl 5.6', 1, 1);
#   }
#   exit 0;
# }

require Math::BigInt;
MyTestHelpers::diag ('Math::BigInt version ', Math::BigInt->VERSION);
{
  my $n = Math::BigInt->new(2) ** 256;
  my $int = int($n);
  if (! ref $int) {
    MyTestHelpers::diag ('skip due to Math::BigInt no "int" operator');
    foreach (1 .. $test_count) {
      skip ('due to no Math::BigInt int() operator', 1, 1);
    }
    exit 0;
  }
}

MyTestHelpers::nowarnings(); # after exponentiation test warnings
Math::BigFloat->accuracy(150);  # significant digits

# Something dodgy in BigFloat 1.997 in perl 5.14.3 makes bpi() give NaN if
# precision() is set, so don't do that.
# Math::BigFloat->precision(-20);  # digits right of decimal point
#
# {
#   my $pi = Math::BigFloat->bpi;
#   ### bpi(): $pi
# }


#------------------------------------------------------------------------------
# round_down_pow()

use Math::PlanePath::Base::Digits 'round_down_pow';
{
  my $orig = Math::BigFloat->new(3) ** 64;
  my $n    = Math::BigFloat->new(3) ** 64;
  my ($pow,$exp) = round_down_pow($n,3);

  ok ($n, $orig, "round_down_pow(3) unmodified input");
  ok ($pow == Math::BigFloat->new(3.0) ** 64, 1,
      "round_down_pow(3) 3^64 + 1.25 power");
  ok ($exp == 64, 1,
      "round_down_pow(3) 3^64 + 1.25 exp");
}
{
  my $orig = Math::BigFloat->new(3) ** 64 + 1.25;
  my $n    = Math::BigFloat->new(3) ** 64 + 1.25;
  my ($pow,$exp) = round_down_pow($n,3);
  ### pow: "$pow"
  ### exp: "$exp"

  ok ($n, $orig, "round_down_pow(3) unmodified input");
  ok ($pow == Math::BigFloat->new(3.0) ** 64, 1,
      "round_down_pow(3) 3^64 + 1.25 power");
  ok ($exp == 64, 1,
      "round_down_pow(3) 3^64 + 1.25 exp");
}

#------------------------------------------------------------------------------
# round_nearest()

use Math::PlanePath::Base::Generic 'round_nearest';

ok (round_nearest(Math::BigFloat->new('-.75')) == -1,  1);
ok (round_nearest(Math::BigFloat->new('-.5'))  == 0,  1);
ok (round_nearest(Math::BigFloat->new('-.25')) == 0,  1);

ok (round_nearest(Math::BigFloat->new('.25'))  == 0,  1);
ok (round_nearest(Math::BigFloat->new('1.25')) == 1,  1);
ok (round_nearest(Math::BigFloat->new('1.5'))  == 2,  1);
ok (round_nearest(Math::BigFloat->new('1.75')) == 2,  1);
ok (round_nearest(Math::BigFloat->new('2'))    == 2,  1);

#------------------------------------------------------------------------------
# MultipleRings

{
  require Math::PlanePath::MultipleRings;
  my $width = 5;
  my $path = Math::PlanePath::MultipleRings->new (step => 6);

  {
    my $n = Math::BigFloat->new(4);
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok (!! (ref $got_x && $got_x->isa('Math::BigFloat')), 1);
    ok ($got_x >= -1.01 && $got_x <= -0.99,
        1,
       "MultipleRings n_to_xy($n) got_x $got_x");
    ok ($got_y == 0, 1);
  }

  {
    my $pi = Math::PlanePath::MultipleRings::_pi(0);
    ok ($pi > 3);
    ok ($pi < 4);
  }
  {
    my $n = Math::BigFloat->new(4);
    my $pi = Math::PlanePath::MultipleRings::_pi($n);
    ok ($pi > 3);
    ok ($pi < 4);
  }
}

#------------------------------------------------------------------------------
# Diagonals

{
  require Math::PlanePath::Diagonals;
  my $path = Math::PlanePath::Diagonals->new;
  {
    my $x = Math::BigFloat->new(2) ** 128 - 1;
    my $n = ($x+1)*($x+2)/2;  # triangular numbers on Y=0 horizontal

    my ($got_x,$got_y) = $path->n_to_xy($n);
    $got_x = $x->copy;
    ok ($got_x == $x, 1,
        "got x=$got_x want x=$x");
    ### $x
    ### $got_x
    ### diff: ($x-$got_x).""
    ### diff: ($x-$got_x)==0
    ok ($got_y == 0);

    my $got_n = $path->xy_to_n($x,0);
    ok ($got_n == $n, 1);
  }
  {
    my $x = Math::BigFloat->new(2) ** 128 - 1;
    my $n = ($x+1)*($x+2)/2;  # Y=0 horizontal

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $x, 1);
    ok ($got_y == 0, 1);

    my $got_n = $path->xy_to_n($x,0);
    ok ($got_n == $n, 1);
  }
  {
    my $y = Math::BigFloat->new(2) ** 128 - 1;
    my $n = $y*($y+1)/2 + 1;  # X=0 vertical

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == 0, 1, "Diagonals x of n_to_xy for x=0 y=2^128-1");
    ok ($got_y == $y, 1, "Diagonals x of n_to_xy for x=0 y=2^128-1");

    my $got_n = $path->xy_to_n(0,$y);
    ok ($got_n, $n, "Diagonals xy_to_n() at x=0 y=2^128-1");
  }
  {
    my $n = Math::BigFloat->new(-1);
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x, undef);
    ok ($got_y, undef);
  }
  {
    my $n = Math::BigFloat->new(0.5);
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ### $got_x
    ### $got_y
    ok (!! $got_x->isa('Math::BigFloat'), 1);
    ok (!! $got_y->isa('Math::BigFloat'), 1);
    ok ($got_x == -0.5, 1);
    ok ($got_y == 0.5, 1);
  }
}

#------------------------------------------------------------------------------
# is_infinite()

use Math::PlanePath::Base::Generic 'is_infinite';
{
  my $x = Math::BigFloat->new(0);
  $x->binf;
  MyTestHelpers::diag ("+inf is ",$x);
  ok (!! is_infinite($x), 1, '_is_infinte() BigFloat +inf');

  $x->binf('-');
  MyTestHelpers::diag ("-inf is ",$x);
  ok (!! is_infinite($x), 1, '_is_infinte() BigFloat -inf');

  $x->bnan();
  MyTestHelpers::diag ("nan is ",$x);
  ok (!! is_infinite($x), 1, '_is_infinte() BigFloat nan');
}

#------------------------------------------------------------------------------
# floor()

use Math::PlanePath::Base::Generic 'floor';

ok (floor(Math::BigFloat->new('-.75')) == -1,  1);
ok (floor(Math::BigFloat->new('-.5'))  == -1,  1);
ok (floor(Math::BigFloat->new('-.25')) == -1,  1);

ok (floor(Math::BigFloat->new('.25'))  == 0,  1);
ok (floor(Math::BigFloat->new('.75'))  == 0,  1);
ok (floor(Math::BigFloat->new('1.25')) == 1,  1);
ok (floor(Math::BigFloat->new('1.5'))  == 1,  1);
ok (floor(Math::BigFloat->new('1.75')) == 1,  1);
ok (floor(Math::BigFloat->new('2'))    == 2,  1);

#------------------------------------------------------------------------------
# Rows

{
  require Math::PlanePath::Rows;
  my $width = 5;
  my $path = Math::PlanePath::Rows->new (width => $width);

  {
    my $y = Math::BigFloat->new(2) ** 128;
    my $x = 4;
    my $n = $y*$width + $x + 1;

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $x, 1, "got x=$got_x want x=$x");
    ok ($got_y == $y);
  
    my $got_n = $path->xy_to_n($x,$y);
    ok ($got_n == $n, 1);
  }
  {
    my $n = Math::BigFloat->new('1.5');
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == 0.5, 1);
    ok ($got_y == 0, 1);
  }
  {
    my $n = Math::BigFloat->new('1.5') + 15;
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == 0.5, 1);
    ok ($got_y == 3, 1);
  }
}

#------------------------------------------------------------------------------
# PeanoCurve

require Math::PlanePath::PeanoCurve;
{
  my $path = Math::PlanePath::PeanoCurve->new;

  require Math::BigFloat;
  my $n = Math::BigFloat->new(9) ** 128 + 1.5;
  my $want_x = Math::BigFloat->new(3) ** 128 + 1.5;
  my $want_y = Math::BigFloat->new(3) ** 128 - 1;

  my ($got_x,$got_y) = $path->n_to_xy($n);
  ok ($got_x == $want_x, 1, "PeanoCurve 9^128 + 1.5 X got $got_x want $want_x");
  ok ($got_y == $want_y, 1, "PeanoCurve 9^128 + 1.5 Y got $got_y want $want_y");
}

#------------------------------------------------------------------------------
# ZOrderCurve

require Math::PlanePath::ZOrderCurve;
{
  my $path = Math::PlanePath::ZOrderCurve->new;

  require Math::BigFloat;
  my $n = Math::BigFloat->new(4) ** 128 + 0.5;
  my $want_x = Math::BigFloat->new(2) ** 128 + 0.5;
  my $want_y = 0;

  my ($got_x,$got_y) = $path->n_to_xy($n);
  ok ($got_x == $want_x, 1,
      "ZOrderCurve 4^128 + 0.5 X got $got_x want $want_x");
  ok ($got_y == $want_y, 1,
      "ZOrderCurve 4^128 + 0.5 Y got $got_y want $want_y");
}

exit 0;
