#!/usr/bin/perl -w

# Copyright 2012, 2014 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use POSIX;
use List::Util 'max','min';
use Math::NumSeq::Fibonacci;
use Math::NumSeq::LucasNumbers;

{
  # cumulative
  require Math::NumSeq::Fibonacci;
  my $seq = Math::NumSeq::Fibonacci->new;
  $seq->next;
  $seq->next;
  my $total = 0;
  my @values;
  foreach (1 .. 20) {
    my ($i, $value) = $seq->next;
    $total += $value;
    print $value,"   ",$total,"\n";
    # print $seq->ith($i+2),"   ",$total+1,"\n";
    push @values, $total;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search (array => \@values);
  exit 0;
}
{
  # negatives
  my $class;
  $class = 'Math::NumSeq::LucasNumbers';
  $class = 'Math::NumSeq::Fibonacci';
  my $seq = $class->new;

  my $i = -96;
  my $f0 = $seq->ith($i);
  my $f1 = $seq->ith($i+1);
  my @values;
  for (1 .. 1) {
    my ($v0,$v1) = $seq->ith_pair($i);
    exit;
    my $value = $seq->ith($i);

    my $diff = ($value == $f0 && $v0 == $f0 && $v1 == $f1 ? '' : ' ***');

    print "$i $f0,$f1   $value  $v0,$v1$diff\n";

    ($f0,$f1) = ($f1-$f0, $f0);
    push @values, $value;
    $i--;
  }

  use lib 'xt'; require MyOEIS;
  Math::OEIS::Grep->search (array => \@values);
  exit 0;
}
{
  # value_to_i_estimate()
  # require Math::NumSeq::Fibonacci;
  # my $seq = Math::NumSeq::Fibonacci->new;

  # require Math::NumSeq::Pell;
  # my $seq = Math::NumSeq::Pell->new;

  # require Math::NumSeq::LucasNumbers;
  # my $seq = Math::NumSeq::LucasNumbers->new;

  require Math::NumSeq::SlopingExcluded;
  my $seq = Math::NumSeq::SlopingExcluded->new (radix => 10);

  my $target = 2;
  for (;;) {
    my ($i, $value) = $seq->next;
    if ($i >= $target) {
      $target *= 1.1;

      # require Math::BigRat;
      # $value = Math::BigRat->new($value);

      # require Math::BigFloat;
      # $value = Math::BigFloat->new($value);

      my $est_i = $seq->value_to_i_estimate($value);
      my $factor = $est_i / $i;
      printf "%d %d   %.10s  factor=%.3f\n",
        $i, $est_i, $value, $factor;
    }
  }
  exit 0;
}


{
  require Math::NumSeq::Tribonacci;
  my $seq = Math::NumSeq::Tribonacci->new (hi => 13);
  my @next = ( $seq->next,
               $seq->next,
               $seq->next,
               $seq->next,
               $seq->next,
               $seq->next );
  ### @next
  print $seq->pred(12),"\n";
  ### $seq
  exit 0;
}


{
  require Math::Fibonacci;
  require POSIX;
  my $phi = (1 + sqrt(5)) / 2;
  foreach my $i (1 .. 40) {
    my $f = Math::Fibonacci::term($i);
    my $theta = $f / ($phi*$phi);
    my $frac = $theta - POSIX::floor($theta);
    printf("%2d  %10.2f  %5.2f  %1.3f  %5.3f\n",
           $i, $f, sqrt($f), $frac, $theta);
  }
  exit 0;
}
{
  require Math::Fibonacci;
  my @f = Math::Fibonacci::series(90);
  local $, = ' ';
  print @f,"\n";

  foreach my $i (1 .. $#f) {
    if ($f[$i] > $f[$i]) {
      print "$i\n";
    }
  }
  my @add = (1, 1);
  for (;;) {
    my $n = $add[-1] + $add[-2];
    if ($n > 2**53) {
      last;
    }
    push @add, $n;
  }
  print "add count ",scalar(@add),"\n";
  foreach my $i (0 .. $#add) {
    if ($f[$i] != $add[$i]) {
      print "diff $i    $f[$i] != $add[$i]    log ",log($add[$i])/log(2),"\n";
    }
  }
  exit 0;
}
