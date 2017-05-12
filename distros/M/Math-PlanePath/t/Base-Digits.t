#!/usr/bin/perl -w

# Copyright 2012, 2013, 2015 Kevin Ryde

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
plan tests => 80;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::Base::Digits
  'parameter_info_array',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh',
  'round_down_pow',
  'round_up_pow';


my $have_64bits = ((1 << 63) != 0);
my $modulo_64bit_dodginess = ($have_64bits
                              && ((~0)%2) != ((~0)&1));
my $skip_64bit = ($modulo_64bit_dodginess
                  ? 'due to 64-bit modulo dodginess ((~0)%2) != ((~0)&1)'
                  : undef);
MyTestHelpers::diag ("modulo operator dodginess ((~0)%2) != ((~0)&1): ",
                     $modulo_64bit_dodginess ? "yes (bad)" : "no (good)");


#------------------------------------------------------------------------------
# parameter_info_array()

{
  my $aref = parameter_info_array();
  ok (scalar(@$aref), 1);
  ok ($aref->[0], Math::PlanePath::Base::Digits::parameter_info_radix2());
}

#------------------------------------------------------------------------------
# round_down_pow()

foreach my $elem ([ 1, 1,0 ],
                  [ 2, 1,0 ],
                  [ 3, 3,1 ],
                  [ 4, 3,1 ],
                  [ 5, 3,1 ],

                  [ 8, 3,1 ],
                  [ 9, 9,2 ],
                  [ 10, 9,2 ],

                  [ 26, 9,2 ],
                  [ 27, 27,3 ],
                  [ 28, 27,3 ],
                 ) {
  my ($n, $want_pow, $want_exp) = @$elem;
  my ($got_pow, $got_exp)
    = round_down_pow($n,3);
  ok ($got_pow, $want_pow);
  ok ($got_exp, $want_exp);
}

# return 3**$k if it is exactly representable, or 0 if not
sub pow3_if_exact {
  my ($k) = @_;
  my $p = 3**$k;
  if ($p+1 <= $p
      || $p-1 >= $p
      || ($p % 3) != 0
      || (($p+1) % 3) != 1
      || (($p-1) % 3) != 2) {
    return 0;
  }
  return $p;
}

{
  my $bad = 0;
  foreach my $i (2 .. 200) {
    my $p = pow3_if_exact($i);
    if (! $p) {
      MyTestHelpers::diag ("round_down_pow(3) tests stop for round-off at i=$i");
      last;
    }

    {
      my $n = $p-1;
      my $want_pow = $p/3;
      my $want_exp = $i-1;
      my ($got_pow, $got_exp)
        = round_down_pow($n,3);
      if ($got_pow != $want_pow
          || $got_exp != $want_exp) {
        MyTestHelpers::diag ("round_down_pow($n,3) i=$i prev got $got_pow,$got_exp want $want_pow,$want_exp");
        $bad++;
      }
    }
    {
      my $n = $p;
      my $want_pow = $p;
      my $want_exp = $i;
      my ($got_pow, $got_exp)
        = round_down_pow($n,3);
      if ($got_pow != $want_pow
          || $got_exp != $want_exp) {
        MyTestHelpers::diag ("round_down_pow($n,3) i=$i exact got $got_pow,$got_exp want $want_pow,$want_exp");
        $bad++;
      }
    }
    {
      my $n = $p+1;
      my $want_pow = $p;
      my $want_exp = $i;
      my ($got_pow, $got_exp) = round_down_pow($n,3);
      if ($got_pow != $want_pow
          || $got_exp != $want_exp) {
        MyTestHelpers::diag ("round_down_pow($n,3) i=$i post got $got_pow,$got_exp want $want_pow,$want_exp");
        $bad++;
      }
    }
  }
  ok ($bad,0);
}

#------------------------------------------------------------------------------
# round_up_pow()

foreach my $elem ([ 1, 1,0 ],
                  [ 2, 3,1 ],
                  [ 3, 3,1 ],
                  [ 4, 9,2 ],
                  [ 5, 9,2 ],

                  [ 8, 9,2 ],
                  [ 9, 9,2 ],
                  [ 10, 27,3 ],

                  [ 26, 27,3 ],
                  [ 27, 27,3 ],
                  [ 28, 81,4 ],
                 ) {
  my ($n, $want_pow, $want_exp) = @$elem;
  my ($got_pow, $got_exp) = round_up_pow($n,3);
  ok ($got_pow, $want_pow, "n=$n");
  ok ($got_exp, $want_exp, "n=$n");
}

{
  my $bad = 0;
  foreach my $i (2 .. 200) {
    my $p = pow3_if_exact($i);
    if (! $p) {
      MyTestHelpers::diag ("round_up_pow(3) tests stop for round-off at i=$i");
      last;
    }

    {
      my $n = $p-1;
      my $want_pow = $p;
      my $want_exp = $i;
      my ($got_pow, $got_exp) = round_up_pow($n,3);
      if ($got_pow != $want_pow
          || $got_exp != $want_exp) {
        MyTestHelpers::diag ("round_up_pow($n,3) i=$i prev got $got_pow,$got_exp want $want_pow,$want_exp");
        $bad++;
      }
    }
    {
      my $n = $p;
      my $want_pow = $p;
      my $want_exp = $i;
      my ($got_pow, $got_exp) = round_up_pow($n,3);
      if ($got_pow != $want_pow
          || $got_exp != $want_exp) {
        MyTestHelpers::diag ("round_up_pow($n,3) i=$i exact got $got_pow,$got_exp want $want_pow,$want_exp");
        $bad++;
      }
    }
    {
      my $n = $p+1;
      my $want_exp = $i+1;
      my $want_pow = pow3_if_exact($want_exp);
      if ($want_pow) {
        my ($got_pow, $got_exp) = round_up_pow($n,3);
        if ($got_pow != $want_pow
            || $got_exp != $want_exp) {
          MyTestHelpers::diag ("round_up_pow($n,3) i=$i post got $got_pow,$got_exp want $want_pow,$want_exp");
          $bad++;
        }
      }
    }
  }
  ok ($bad,0);
}

#------------------------------------------------------------------------------
# digit_split_lowtohigh()

ok (join(',',digit_split_lowtohigh(0,2)), '');
ok (join(',',digit_split_lowtohigh(13,2)), '1,0,1,1');

{
  my $n = ~0;
  foreach my $radix (2,3,4, 5, 6,7,8,9, 10, 16, 37) {
    my @digits = digit_split_lowtohigh($n,$radix);
    my $lowtwo = $n % ($radix * $radix);
    my $lowmod = $lowtwo % $radix;
    skip ($skip_64bit,
          $digits[0], $lowmod,
          "$n radix $radix lowest digit");
    my $secondmod = ($lowtwo - ($lowtwo % $radix)) / $radix;
    skip ($skip_64bit,
          $digits[1], $secondmod,
          "$n radix $radix second lowest digit");
  }
}
{
  my $uv_max = ~0;
  my $ones = 1;
  my @bits = digit_split_lowtohigh($uv_max,2);
  foreach my $bit (@bits) {
    $ones &&= $bit;
  }
  skip ($skip_64bit,
        $ones, 1,
        "~0 uv_max $uv_max should be all 1s");
  if (! $ones) {
    MyTestHelpers::diag ("~0 uv_max $uv_max is: ",
                         @bits);
  }
}

#------------------------------------------------------------------------------
# bit_split_lowtohigh()

ok (join(',',bit_split_lowtohigh(0)), '');
ok (join(',',bit_split_lowtohigh(13)), '1,0,1,1');

{
  my $uv_max = ~0;
  my @bits = bit_split_lowtohigh($uv_max);
  my $ones = 1;
  foreach my $bit (@bits) {
    $ones &&= $bit;
  }
  skip ($skip_64bit,
        $ones, 1,
        "bit_split_lowtohigh(uv_max=$uv_max) ".join(',',@bits));
}

#------------------------------------------------------------------------------
# digit_join_lowtohigh()

ok (digit_join_lowtohigh([1,2,3],10), 321);

# high zeros ok
ok (digit_join_lowtohigh([1,1,0],2), 3);
ok (digit_join_lowtohigh([1,1,0],8), 9);
ok (digit_join_lowtohigh([1,1,0],10), 11);


#------------------------------------------------------------------------------
1;
__END__
