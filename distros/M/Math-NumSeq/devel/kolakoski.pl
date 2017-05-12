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

# uncomment this to run the ### lines
#use Devel::Comments;

# 1, 2,2, 1,1, 2, 1, 2,2, 1, 2,2,

{
  my @count = (1);
  my @digit = (1);

  sub pnext {
    my $pos = 0;
    my $digit;
    for (;;) {
      if ($pos > $#count) {
        ### all zeros to pos: $pos
        if ($pos == 1) {
          if ($digit[0] == 1) {
            ### special case i=2 digit 2 count 1 ...
            $count[0] = 1;
            return ($digit[0] = 2);
          }
        }
        ### extend for i=4 state ...
        push @count, 0;
        push @digit, ($digit = 2);
        last;
      }
      if ($count[$pos]--) {
        ### non-zero count at: "pos=$pos digit=$digit[$pos], remaining count=$count[$pos]"
        $digit = $digit[$pos];
        last;
      }
      $pos++;
    }

    while (--$pos >= 0) {
      $count[$pos] = $digit - 1;
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

{
  my @count = ();
  my @digit = ();
  my @at = (1);

  sub knext {
    my ($i) = @_;
    if ($i > $#count) {
      print "extend $i\n";
      push @count, 2;
      push @digit, 2;
      print "level $i ret 1\n";
      return 1;
    }
    if ($count[$i] == 0) {
      $digit[$i] ^= 3;
      print "level $i empty, flip to $digit[$i]\n";
      $count[$i] = knext($i+1);
      print "level $i count from lower level is $count[$i]\n";
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
  my @a = (0);
  my @p = (0);

  my $digit = 1;
  my $pos = 1;
  for (my $i = 1; $i < 500; $i++) {
    $a[$pos] = $digit;
    my $count = $a[$i];
    while ($count--) {
      $p[$pos] = $i;
      $a[$pos] = $digit;
      $pos++;
    }
    $digit ^= 3;
  }
  foreach my $i (1 .. $#a) {
    print "$i   $a[$i]  $p[$i]";
    my $p = $p[$i];
    my $level = 0;
    for (;;) {
      $p = $p[$p];
      print "-$p";
      $level++;
      last if $p == $p[$p];
    }
    # i = x^level
    # log(i) = level*log(x)
    # log(x) = log(i)/level
    # x = e^(log(i)/level)
    print "   level $level ".sprintf("%.4f",exp(log($i)/$level));
    print "\n";
  }
  exit 0;
}


