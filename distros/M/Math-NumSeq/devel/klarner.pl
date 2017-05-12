#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

{
  my @a = (1);

  my %dup;
  foreach my $i (1 .. 10) {
    print "$i   ";
    foreach my $a (@a) {
      print " $a";
      if ($dup{$a}++) {
        print "*";
      }
    }
    print "\n";
    @a = map {2*$_,3*$_+2,6*$_+3} @a;
  }
  exit 0;
}

{
  my @count = (1);
  my @digit = (1);
  my @at = (1);

  sub knext {
    my ($i) = @_;
    if ($i > $#count) {
      print "extend $i\n";
      push @count, 1;
      push @digit, 2;
    }
    if ($count[$i] == 0) {
      $digit[$i] ^= 3;
      $count[$i] = knext($i+1);
    }
    $count[$i]--;
    $at[$i]++;
    return $digit[$i];
  }

  foreach my $i (1 .. 20) {
    my $value = knext(0);
    print "$i  $value      ",join('-',@at),"\n";
  }
  exit 0;
}

{
  my @count = (1);
  my @digit = (1);

  sub pnext {
    my $ret = $digit[0];
    my $pos = 0;
    my $digit;
    for (;;) {
      if ($pos > $#count) {
        print "extend $pos\n";
        push @count, 0;
        push @digit, ($digit = 2);
        last;
      }
      if ($count[$pos]) {
        $count[$pos]--;
        $digit = $digit[$pos];
        last;
      }
      $pos++;
    }
    while (--$pos > 0) {
      $count[$pos] = $digit ^ 3;
      $digit = ($digit[$pos] ^= 3);
    }
    return $digit;
  }

  foreach my $i (1 .. 20) {
    my $value = pnext(0);
    print "$i  $value\n";
  }
  exit 0;
}
