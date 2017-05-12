#!/usr/bin/perl -w

# Copyright 2011, 2012, 2014 Kevin Ryde

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
use Math::NumSeq::SlopingExcluded;
use Math::BigInt;

# uncomment this to run the ### lines
#use Smart::Comments;



{
  # which values
  # binary: 1,10,111,1100,11101,111110,1111011,11111000,111111001,1111111010,
  # decimal: 9, 98, 997, 9996

  require Math::BaseCnv;
  my @seen;
  my @table;
  my $exp = 7;
  my $radix = 3;
  my $limit = $radix**$exp;
  foreach my $i (0 .. $limit) {
    $table[$i] = digit_split($i,$radix);
  }
  ### @table
 JOIN: foreach my $i (0 .. $#table) {
    my $this = $table[$i];
    my $next = $table[$i+1];
    if (! $next || @$next > @$this) {
      # print "skip i=$i smaller\n";
      next;
    }
    my @digits;
    foreach my $j (reverse 0 .. $#$this) { # high to low
      my $pos = $i - ($#$this-$j);
      next JOIN if $pos < 0;
      next JOIN if $pos > $#table;
      my $digit = $table[$pos]->[$j];
      die "i=$i pos=$pos j=$j" if ! defined $digit;
      push @digits, $digit;  # digits[0] high
    }

    ### $i
    ### @digits

    my $sloping = digit_join(\@digits,$radix);
    # my $sb = Math::BaseCnv::cnv($sloping,10,$radix);
    # print "sloping i=$i   $sloping $sb\n";
    $seen[$sloping] .= " $i";
  }
  my @values;
  foreach my $i (0 .. $limit/$radix) {
    my $unseen = ($seen[$i] ? '' : '   ***');
    my $ib = Math::BaseCnv::cnv($i,10,$radix);
    if ($unseen) {
      push @values, $i;
      printf "%5d %20s%s\n", $i, $ib, $unseen;
    }
  }
  use lib 'xt';
  Math::OEIS::Grep->search (name => "radix=$radix",
                            array => \@values);
  exit 0;
}

{
  # by radix
  require Math::BaseCnv;
  foreach my $radix (2 .. 16) {
    print "radix $radix\n";
    my @seen;
    my @table;
    my $exp = int(log(500000)/log($radix));
    my $limit = $radix**$exp;
    foreach my $i (0 .. $limit) {
      $table[$i] = digit_split($i,$radix);
    }
    ### @table
  JOIN: foreach my $i (0 .. $#table) {
      my $this = $table[$i];
      my $next = $table[$i+1];
      if (! $next || @$next > @$this) {
        # print "skip i=$i smaller\n";
        next;
      }
      my @digits;
      foreach my $j (reverse 0 .. $#$this) { # high to low
        my $pos = $i - ($#$this-$j);
        next JOIN if $pos < 0;
        next JOIN if $pos > $#table;
        my $digit = $table[$pos]->[$j];
        die "i=$i pos=$pos j=$j" if ! defined $digit;
        push @digits, $digit;  # digits[0] high
      }

      ### $i
      ### @digits

      my $sloping = digit_join(\@digits,$radix);
      # my $sb = Math::BaseCnv::cnv($sloping,10,$radix);
      # print "sloping i=$i   $sloping $sb\n";
      $seen[$sloping]++;
    }
    foreach my $i (0 .. $limit/$radix) {
      if (! $seen[$i]) {
        my $ib = Math::BaseCnv::cnv($i,10,$radix);
        print "  $i  $ib\n";
      }
    }
  }
  exit 0;

  sub digit_split {
    my ($n, $radix) = @_;
    ### _digit_split(): $n

    if ($n == 0) {
      return [0];
    }
    my @ret;
    while ($n) {
      push @ret, $n % $radix;  # ret[0] high digit
      $n = int($n/$radix);
    }
    return \@ret;
  }

  sub digit_join {
    my ($aref, $radix) = @_;
    ### digit_join(): $aref

    my $n = 0;
    foreach my $digit (@$aref) {  # high to low
      $n *= $radix;
      $n += $digit;
    }
    return $n;
  }
}

{
  # delta from 2^i

  my $seq = Math::NumSeq::SlopingExcluded->new;
  foreach (1 .. 50) {
    my ($i, $value) = $seq->next;
    $value = Math::BigInt->new(2)**$i - $value;
    print "$value\n";
  }
  exit 0;
}


{
  my $seq = Math::NumSeq::SlopingExcluded->new (radix => 2);
  foreach (1 .. 30) {
    my ($i, $value) = $seq->next;
    # printf "%60s\n", $value;
    my $vb = $value->as_bin;
    $vb =~ s/^0b//;
    printf "%60s\n", $vb;
  }
  exit 0;
}

