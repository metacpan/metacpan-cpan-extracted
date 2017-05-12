#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use POSIX;
use List::Util 'max','min';

# uncomment this to run the ### lines
# use Smart::Comments;





{
  # value_to_i_floor()
  require Math::NumSeq::BalancedBinary;
  my $seq = Math::NumSeq::BalancedBinary->new;
  # {
  #   my $i = $seq->value_to_i(3);
  #   print "$i\n";
  # }
  my $input = 0xFFFF_FFFF;
   $input = 0xFFFF_FFFF_FFFF_FFFF;  # 75_254_198_337_177_847
  {
    my $i = $seq->value_to_i_floor($input);
    # $i = $seq->value_to_i_ceil($input);
    my $value = $seq->ith($i);
    printf "%d -> %d %d %#b\n", $input, $i, $value, $value;
  }
  # foreach my $i (1 .. 15) {
  #   my $value = $seq->ith($i);
  #   printf "%2d %3d %12b\n", $i, $value, $value;
  # }
  exit 0;
}
{
  # value_to_i_estimate()

  # require Math::NumSeq::Catalan;
  # # my $seq = Math::NumSeq::Catalan->new;
  # my $seq = Math::NumSeq::Catalan->new (values_type => 'odd');

  require Math::NumSeq::BalancedBinary;
  my $seq = Math::NumSeq::BalancedBinary->new;

  my $target = 2;
  for (;;) {
    my ($i, $value) = $seq->next;
    if ($i >= $target) {
      $target *= 1.1;

      require Math::BigInt;
      $value = Math::BigInt->new($value);

      # require Math::BigRat;
      # $value = Math::BigRat->new($value);

      # require Math::BigFloat;
      # $value = Math::BigFloat->new($value);

      my $est_i = $seq->value_to_i_estimate($value);
      my $factor = (ref $est_i ? $est_i->numify / $i
                    : $est_i / $i);
      printf "%d i_est=%d   v=%.10s  factor=%.3f\n",
        $i, $est_i, $value, $factor;
    }
  }
  exit 0;
}
{
  # ith()
  require Math::NumSeq::BalancedBinary;
  my $seq = Math::NumSeq::BalancedBinary->new;
  $seq->ith(4);
  foreach my $i (1 .. 30) {
    my $value = $seq->ith($i);
    printf "%2d %3d %12b\n", $i, $value, $value;
  }
  exit 0;
}

{
  # odd Catalan 2s

  require Math::NumSeq::Catalan;
  my $seq = Math::NumSeq::Catalan->new;

  # require Math::NumSeq::BalancedBinary;
  # my $seq = Math::NumSeq::BalancedBinary->new;

  require Math::NumSeq::DigitCountLow;
  my $low = Math::NumSeq::DigitCountLow->new (radix => 2, digit => 0);
  foreach (1 .. 40) {
    my ($i, $value) = $seq->next;
    my $low2s = $low->ith($value);
    my $oddvalue = $value / 2**$low2s;
    printf "%6b %s  %22s  %s\n", $i+1, $low2s, $oddvalue, $value;
  }
  exit 0;
}


{
  # z,o

  my $uv_max = 0xFFFF_FFFF;
  $uv_max = ~0;
  my @num;
  $num[0][0] = 0;
  $num[1][1] = 1;
  OUTER: foreach my $z (1 .. 30) {
    my $num = $num[$z][0] = 1;  # all zeros, no ones
    foreach my $o (1 .. $z) {
      my $add = ($num[$z-1][$o] || 0);  # 0,... if $z>=1
      if ($num > $uv_max - $add) {
        delete $num[$z];
        last OUTER;
      }
      $num += $add;                     # 1,...
      $num[$z][$o] = $num;
    }
  }

  my $count = 0;
  foreach my $aref (@num) {
    next unless $aref;
    print join(' ',map {$count++; $_||'_'} @$aref),"\n";
  }
  print "count $count\n";
  exit 0;
}

{
  # table

  my @num;
  $num[0][0] = 1;
  foreach my $i (1 .. 10) {
    $num[$i][0] = 1;
    foreach my $j (1 .. $i) {
      $num[$i][$j]
        = $num[$i][$j-1]             # left
          + ($num[$i-1][$j] || 0);   # above
    }
  }

  foreach my $aref (@num) {
    next unless $aref;
    print join(' ',map {$_||'_'} @$aref),"\n";
  }
  exit 0;
}

{
  # excess

  my @num;
  $num[2][0] = 1;
  $num[1][1] = 1;

  sub num {
    my ($w, $e) = @_;
    ### num: "$w $e"
    die "$w,$e" if $e < 0;
    die "$w,$e" if $w < 1;
    die "$w,$e" if $w<$e;
    die "$w,$e" if ($w-$e) & 1;

    if (defined $num[$w][$e]) {
      return $num[$w][$e];
    }
    # 0, num(w-1,e-1)
    # 1, num(w-1,e+1)  if w-1 >= e+1, w>=e+2
    my $num = 0;
    if ($e > 0) {
      $num += num($w-1,$e-1);
    }
    if ($w >= $e+2) {
      $num += num($w-1,$e+1);
    }
    return ($num[$w][$e] = $num);
  }

  require Math::NumSeq::Catalan;
  my $seq = Math::NumSeq::Catalan->new;

  $seq->next;
  $seq->next;
  foreach (1 .. 15) {
    my ($i, $value) = $seq->next;
    my $num = num(2*$i,0);
    print "$i $value $num\n";
  }

  foreach my $aref (@num) {
    next unless $aref;
    print join(' ',map {$_||'_'} @$aref),"\n";
  }
  exit 0;
}
{
  # monotonic

  require Math::NumSeq::Catalan;
  # my $seq = Math::NumSeq::Catalan->new;
  my $seq = Math::NumSeq::Catalan->new (values_type => 'odd');

  # require Math::NumSeq::BalancedBinary;
  # my $seq = Math::NumSeq::BalancedBinary->new;

  my $prev = -1;
  foreach (1 .. 10000) {
    my ($i, $value) = $seq->next;
    if ($value < $prev) {
      die $i;
    }
    $prev = $value;
  }
  print "$prev\n";
  exit 0;
}

{
  # formula

  require Math::NumSeq::Catalan;
  my $seq = Math::NumSeq::Catalan->new;

  my $cumul = 0;
  foreach (1 .. 20) {
    my ($i, $value) = $seq->next;

    my $formula = 0;
    foreach my $k (1 .. $i-1) {
      $formula += $seq->ith($i-$k)*$k + $seq->ith($k)
    }
    print "$i value=$value formula=$formula\n";
    $cumul += $value;
  }
  exit 0;
}

{
  # cumulative

  require Math::NumSeq::Catalan;
   my $seq = Math::NumSeq::Catalan->new;

  my $prev = 0;
  my $cumul = 0;
  foreach (1 .. 20) {
    my ($i, $value) = $seq->next;
    $cumul += $value;
    my $diff = $cumul - $prev;
    print "$i value=$value cumul=$cumul diff=$diff\n";
    $prev = $cumul;
  }
  exit 0;
}

{
  # Catalan estimate

  require Math::Symbolic;
  my $tree = Math::Symbolic->parse_from_string('4^x / sqrt(3.14*x) / (x+1)');
  print "tree: $tree\n";

  require Math::Symbolic::Derivative;
  my $deriv = Math::Symbolic::Derivative::total_derivative($tree, 'x');
  print "deriv $deriv\n";
  $deriv = $deriv->simplify;
  print "deriv $deriv\n";
  exit 0;
}

{
  # by binary width
  require Math::NumSeq::BalancedBinary;
  my $seq = Math::NumSeq::BalancedBinary->new;

  my $count = 0;
  my $target = 4;
  for (;;) {
    my ($i, $value) = $seq->next;
    if ($value >= $target) {
      print "$target  $count\n";
      $count = 0;
      $target *= 4;
    }
    $count++;
  }
  exit 0;
}

{
  # value_to_i_estimate() 2^32
  # 2**32 i=36_714_788

  require Math::NumSeq::BalancedBinary;
  my $seq = Math::NumSeq::BalancedBinary->new;
  {
    my $est_i = $seq->value_to_i_estimate(2**32);
    print "2**32 i=$est_i\n";
  }
  {
    my $est_i = $seq->value_to_i_estimate(2**64);
    print "2**64 i=$est_i\n";
  }
  exit 0;
}

{
  # catalan estimate
  require Math::NumSeq::Catalan;
  my $seq = Math::NumSeq::Catalan->new;

  for (;;) {
    my ($i, $value) = $seq->next;
    my $est_value = catalan_estimate($i);
    print "$i $value $est_value\n";
  }
  exit 0;

  sub catalan_estimate {
    my ($n) = @_;
    return 4**$n / (sqrt(3.141592*($n||1)) * ($n+1));
  }
}
