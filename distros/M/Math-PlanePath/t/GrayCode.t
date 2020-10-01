#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
use List::Util 'min';
use Test;
plan tests => 309;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::Base::Digits 'digit_split_lowtohigh';
use Math::PlanePath::GrayCode;
use Math::PlanePath::Base::Digits
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


sub binary_to_decimal {
  my ($str) = @_;
  my $ret = 0;
  foreach my $digit (split //, $str) {
    $ret = ($ret << 1) + $digit;
  }
  return $ret;
}

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::GrayCode::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::GrayCode->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::GrayCode->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::GrayCode->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# to/from binary Gray

sub to_gray_reflected {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}
sub from_gray_reflected {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_from_gray_reflected($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}

sub to_gray_modular {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_to_gray_modular($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}
sub from_gray_modular {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_from_gray_modular($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}

{
  my @gray = (binary_to_decimal('00000'),
              binary_to_decimal('00001'),
              binary_to_decimal('00011'),
              binary_to_decimal('00010'),
              binary_to_decimal('00110'),
              binary_to_decimal('00111'),
              binary_to_decimal('00101'),
              binary_to_decimal('00100'),

              binary_to_decimal('01100'),
              binary_to_decimal('01101'),
              binary_to_decimal('01111'),
              binary_to_decimal('01110'),
              binary_to_decimal('01010'),
              binary_to_decimal('01011'),
              binary_to_decimal('01001'),
              binary_to_decimal('01000'),

              binary_to_decimal('11000'),
              binary_to_decimal('11001'),
              binary_to_decimal('11011'),
              binary_to_decimal('11010'),
              binary_to_decimal('11110'),
              binary_to_decimal('11111'),
              binary_to_decimal('11101'),
              binary_to_decimal('11100'),

              binary_to_decimal('10100'),
              binary_to_decimal('10101'),
              binary_to_decimal('10111'),
              binary_to_decimal('10110'),
              binary_to_decimal('10010'),
              binary_to_decimal('10011'),
              binary_to_decimal('10001'),
              binary_to_decimal('10000'),
             );
  ### @gray

  foreach my $i (0 .. $#gray) {
    my $gray = $gray[$i];
    if ($i > 0) {
      my $prev_gray = $gray[$i-1];
      my $xor = $gray ^ $prev_gray;
      ok (is_pow2($xor), 1,
          "at i=$i   $gray ^ $prev_gray = $xor");
    }

    my $got_gray = to_gray_reflected($i,2);
    ok ($got_gray, $gray);
    $got_gray = to_gray_modular($i,2);
    ok ($got_gray, $gray);

    my $got_i = from_gray_reflected($gray,2);
    ok ($got_i, $i);
    $got_i = from_gray_modular($gray,2);
    ok ($got_i, $i);
  }
}

sub is_pow2 {
  my ($n) = @_;
  while (($n & 1) == 0) {
    if ($n == 0) {
      return 0;
    }
    $n >>= 1;
  }
  return ($n == 1);
}

#------------------------------------------------------------------------------
# to/from modular Gray

{
  my @gray = (000,
              001,
              002,
              003,
              004,
              005,
              006,
              007,

              017,
              010,
              011,
              012,
              013,
              014,
              015,
              016,

              026,
              027,
              020,
              021,
              022,
              023,
              024,
              025,

              035,
              036,
              037,
              030,
              031,
              032,
              033,
              034,

              044,
              045,
              046,
              047,
              040,
              041,
              042,
              043,

              053,
              054,
              055,
              056,
              057,
              050,
              051,
              052,

              062,
              063,
              064,
              065,
              066,
              067,
              060,
              061,

              071,
              072,
              073,
              074,
              075,
              076,
              077,
              070,

              0170,
              0171,
              0172,
              0173,
              0174,
              0175,
              0176,
              0177,
             );
  ### @gray

  foreach my $i (0 .. $#gray) {
    my $gray = $gray[$i];

    my $got_gray = to_gray_modular($i,8);
    ok ($got_gray, $gray);

    my $got_i = from_gray_modular($gray,8);
    ok ($got_i, $i);
  }
}

{
  # to/from are inverses
  my $bad = 0;
 OUTER: foreach my $funcs ([\&to_gray_modular, \&from_gray_modular],
                     [\&to_gray_reflected, \&from_gray_reflected],
                    ) {
    my ($to,$from) = @$funcs;
    foreach my $radix (2 .. 7) {
      foreach my $i (0 .. min(256,$radix**4)) {
        my $g = $to->($i,$radix);
        unless ($from->($g,$radix) == $i) {
          MyTestHelpers::diag ("bad radix=$radix i=$i");
          last OUTER if $bad++ > 10;
        }
      }
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# turn sequence claimed in the pod -- default BRGC

{
  my $path = Math::PlanePath::GrayCode->new;
  my $bad = 0;
  my $n_start = $path->n_start;
 OUTER: foreach my $n ($n_start+1 .. 500) {
    {
      my $path_turn = path_n_turn ($path, $n);
      my $calc_turn = calc_n_turn_by_low0s ($n);
      if ($path_turn != $calc_turn) {
        MyTestHelpers::diag ("turn n=$n  path $path_turn calc $calc_turn");
        last OUTER if $bad++ > 10;
      }
    }
    {
      my $path_turn = path_n_turn ($path, $n);
      my $calc_turn = calc_n_turn_by_base4 ($n);
      if ($path_turn != $calc_turn) {
        MyTestHelpers::diag ("turn n=$n  path $path_turn calc $calc_turn");
        last OUTER if $bad++ > 10;
      }
    }
  }
  ok ($bad, 0, "turn sequence");
}

# with Y reckoned increasing upwards
sub dxdy_to_dir4 {
  my ($dx, $dy) = @_;
  if ($dx > 0) { return 0; }  # east
  if ($dx < 0) { return 2; }  # west
  if ($dy > 0) { return 1; }  # north
  if ($dy < 0) { return 3; }  # south
}

# return 0=E,1=N,2=W,3=S
sub path_n_dir {
  my ($path, $n) = @_;
  my ($dx,$dy) = $path->n_to_dxdy($n) or die "Oops, no point at ",$n;
  return dxdy_to_dir4 ($dx, $dy);
}
# return 0,1,2,3 to the left
sub path_n_turn {
  my ($path, $n) = @_;
  my $prev_dir = path_n_dir ($path, $n-1);
  my $dir = path_n_dir ($path, $n);
  return ($dir - $prev_dir) & 3;
}

# return 0,1,2,3 to the left
sub calc_n_turn_by_low0s {
  my ($n) = @_;
  # in floor (N+1)/2
  # even number of 0 bits is turn=1 left
  # odd number of 0 bits is turn=2 reversal
  $n = ($n+1)>>1;
  return (count_low_0_bits($n) % 2 ? 2 : 1);
}
sub count_low_0_bits {
  my ($n) = @_;
  if ($n == 0) { die; }
  my $count = 0;
  until ($n % 2) {
    $count++;
    $n /= 2;
  }
  return $count;
}

# return 0,1,2,3 to the left
sub calc_n_turn_by_base4 {
  my ($n) = @_;
  $n = ($n+1)>>1;
  my $digit = base4_lowest_nonzero_digit($n);
  return ($digit == 1 || $digit == 3 ? 1
          : 2);
}
sub base4_lowest_nonzero_digit {
  my ($n) = @_;
  while (($n & 3) == 0) {
    $n >>= 2;
    if ($n == 0) { die "oops, no nonzero digits at all"; } 
  }
  return $n & 3;
}

#------------------------------------------------------------------------------
exit 0;
