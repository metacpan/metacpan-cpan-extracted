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

use 5.004;
use strict;

{
  foreach (my $n = 3; $n < 30; $n+=2) {
    my $i = $n;
    print "$n   ";
    for (;;) {
      print "$i,";
      if ($i & 1) {
        ### 1/2 odd: $i
        $i *= $i*$i;
      } else {
        ### even: $i
      }
      $i = int(sqrt($i));
      if ($i <= 1) {
        last;
      }
    }
    print "\n";
  }
  exit 0;
}

{
  require Math::NumSeq::JugglerSteps;
  my $seq = Math::NumSeq::JugglerSteps->new;
  my $i = 18446744073709551615;
#  $i = 18446744073709551614/2;
  printf "%X\n", $i;

  require Devel::Peek;
  print Devel::Peek::Dump($i);

  my $value = $seq->ith($i);
  print "$value\n";


  my $b = Math::NumSeq::_bigint()->new($i);
  print "$b\n";
  exit 0;
}


