#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

# uncomment this to run the ### lines
#use Devel::Comments;

use constant PHI => (1 + sqrt(5)) / 2;

# 0,1,0,0,1,0,1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,

{
  # a(n) = floor((n+2)*r)-floor((n+1)*r) where r=phi/(1+2*phi)

  my @array;
  foreach my $i (1 .. 78) {
    my $s = 5*$i*$i;
    my $step = 10*$i+5;

    my $sqrt = int(sqrt($s))+1;
    my @squares;
    for (my $j = $sqrt; $j*$j <= $s+$step; $j++) {
      push @squares, $j*$j;
    }
    my $squares = join(',', @squares);
    my $bit = 0;
    if (($squares[-1] & 1) == ($i & 1)) {
      $bit = 1;
    }
    if (@squares == 3) {
      $bit = 0;
    }
    # $s = sqrt(5*$i*$i)/2 - ($i&1)/2;
    # $t = sqrt(5*($i+1)*($i+1))/2 - ($i&1)/2 - 1/2;
    # $d = int($t)-int($s);

    my $sqstep = 4*$sqrt+4;
    # $sqstep = 6*$sqrt+9;
    # unless ($i & 1) { $sqstep = 2*$sqrt+1; }
    my $sbit = ($sqstep > $step - ($sqrt*$sqrt - $s) ? 1 : 0);

  $sqrt = int(sqrt(5*$i*$i));
    if (5*($i+1)*($i+1) > ($sqrt+3)*($sqrt+3)) {
      $bit = 0;
    } else {
      $bit = ((($i^$sqrt) & 1) ? 0 : 1);
    }

    # s + step > sqrt*sqrt + sqstep
    # s-sqrt*sqrt + step > sqstep
    # sqrtrem + step > sqstep
    # sqrtrem + 10i+5 > 6*sqrt+9
    # sqrtrem + 10i > 6*sqrt+4
    my $rem = 5*$i*$i - $sqrt*$sqrt;
    $sqstep = 6*$sqrt+9;
    $step = 10*$i+5;
    if ($rem + 10*$i > 6*$sqrt+4) {
      $bit = 0;
    } else {
      $bit = ((($i^$sqrt) & 1) ? 0 : 1);
    }
    

    push @array, $bit;
    print "$i  $s $step ($sqstep) $sbit    $sqrt->$squares    $bit\n";
  }

  @array = map{defined $_ ? $_||0 : 1} @array;
  my $array = join('',@array);
  print "$array\n";
  my $want = "010010100100101001010010010100100101001010010010100101001001010010010100101001";
  print "$want\n";
  if ($array eq $want) {
    print "same\n";
  } else {
    print "diff\n";
  }
  exit 0;
}

{
  # n = k/phi
  #   = k / (sqrt(5)+1)/2
  #   = 2k / (sqrt(5)-1)
  #   = 2k * (sqrt(5)+1) / (5-1)
  #   = k * (sqrt(5)-1)/2
  # 2n = k * (sqrt(5)-1)
  # 2n+k = k * sqrt(5)
  # 2n+k = sqrt(5*k^2)
  my @array;
  my $prev_s = 0;
  foreach my $i (1 .. 22) {
    # my $i = 2*$i;
    my $s = (sqrt(5*$i*$i) - $i) / 2;
    my $t = (sqrt(5*($i+1)*($i+1)) - ($i+1)) / 2;
    my $d = int($t)-int($s);

    $s = sqrt(5*$i*$i)/2 - ($i&1)/2;
    $t = sqrt(5*($i+1)*($i+1))/2 - ($i&1)/2 - 1/2;
    $d = int($t)-int($s);

    $array[$i] = (int($s) == int($t));
    print "$i  $s $t   $d\n";
    $prev_s = $s;
  }
  @array = map{defined $_ ? $_||0 : 1} @array;
  print join(',',@array),"\n";

  print "  0,1,0,0,1,0,1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,\n";
  exit 0;
}

{
  my @array;
  my $prev_s = 0;
  foreach my $i (1 .. 22) {
    my $s = int($i / PHI);
    $array[$i] = ($s == $prev_s ? 1 : 0);
    print "$i  $s\n";
    $prev_s = $s;
  }
  @array = map{defined $_ ? $_ : 1} @array;
  print join(',',@array),"\n";

  print "    0,1,0,0,1,0,1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,\n";
  exit 0;
}

{
  my @array;
  foreach my $i (1 .. 20) {
    my $s = int($i * PHI);
    $array[$s] = 0;
    print int ($i * PHI),"\n";
  }
  @array = map{defined $_ ? $_ : 1} @array;
  print join(',',@array),"\n";

  print "  0,1,0,0,1,0,1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,\n";
  exit 0;
}

{
  my @values = (0);
  print join('',@values),"\n";
  foreach (1 .. 8) {
    my $oldlen = scalar(@values);
    @values = map { $_ ? (0) : (0, 1) } @values;
    my $newlen = scalar(@values);

    my $old = join('', @values[0 .. $newlen-$oldlen-1]);
    my $new = join('', @values[$oldlen .. $newlen-1]);
    my $eq = ($old eq $new ? "eq" : "ne");

    my $str = join('',@values);
    substr($str,$oldlen,0) = '-';
    print "len $newlen   $eq   $str\n";
  }

  # print "ith()         ";
  # foreach my $i (0 .. $#values) {
  #   print ith($i);
  # }
  # print "\n";
      
  # require Math::NumSeq::Fibbinary;
  # my $seq = Math::NumSeq::Fibbinary->new;
  # print "             ";
  # foreach my $i (0 .. $#values) {
  #   print $seq->pred($i) ? '0' : '1';
  # }
  # print "\n";

  exit 0;
}
