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
use Math::BigInt try => 'GMP';

# uncomment this to run the ### lines
use Smart::Comments;

{
  # non-decreasing

  require Math::NumSeq::SqrtEngel;
  require Math::NumSeq::Squares;
  foreach my $sqrt (2 .. 10000) {
    next if (Math::NumSeq::Squares->pred($sqrt));
    print "$sqrt\n";

    my $seq = Math::NumSeq::SqrtEngel->new (sqrt => $sqrt);
    my ($prev_i, $prev_value) = $seq->next;
    my $same = 0;
    my @values = ($prev_value);
    for (;;) {
      my ($i, $value) = $seq->next or last;
      push @values, $value;
      $same ||= ($value == $prev_value && $value != 1);
      if ($value < $prev_value) {
        die "$sqrt decreasing i=$i";
      }
      last if $value > 1_000_000;
    }
    while (@values && $values[0] == 1) {
      shift @values;
    }
    if ($same) {
      my $values = join(',',@values);
      print "$sqrt same: $values\n";
    }
  }
  exit 0;
}

{
  # A028254
  # x(1)=sqrt(2), a(n) = ceil(1/x(n)), x(n+1) = x(n)a(n)-1.

  my $r = 2;
  my $x = Math::BigInt->new(0);
  my $y = Math::BigInt->new(1);
  for (1 .. 20) {
    # my $f = 1/ (sqrt($r*$y*$y) - $x);
    my $num = (sqrt($r*$y*$y) + $x);
    my $den = ($r*$y*$y - $x*$x);
    my $n = (sqrt($r*$y*$y) + $x) / ($r*$y*$y - $x*$x);
    $x = $x*$n + 1;
    $y *= $n;
    print "$n = $num/$den  new $x / $y\n";
    ### assert: $x <= sqrt($r*$y*$y)
  }
  exit 0;
}

