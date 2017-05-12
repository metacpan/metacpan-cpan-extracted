#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use List::Util 'max','min';

use Smart::Comments;


{
  require Math::NumSeq::SternDiatomic;
  my $seq = Math::NumSeq::SternDiatomic->new;
  foreach my $i (0 .. 40) {
    my ($v0,$v1) = $seq->ith_pair($i);
    my $w0 = $seq->ith($i);
    my $w1 = $seq->ith($i+1);
    my $diff = ($w0==$v0 && $w1==$v1 ? '' : ' ***');
    print "$i  $w0 $w1  $v0 $v1$diff\n";
  }
  exit 0;
}
{
  require Math::NumSeq::FibonacciRepresentations;
  my $seq = Math::NumSeq::FibonacciRepresentations->new;
  { my $value = $seq->ith(3);
    print "$value\n";
  }
  { my $value = $seq->ith(4);
    print "$value\n";
  }
  { my $value = $seq->ith(5);
    print "$value\n";
  }
  exit 0;
}

{
  foreach my $y (reverse -5 .. 5) {
    foreach my $x (-5 .. 5) {
      my $v = max(abs($x+$y),abs($x-$y),2*abs($y));
      # my $v = max($x,$y);
      if ($v & 1) {
        print "  ";
      } else {
        printf '%2d', $v;
      }
    }
    print "\n";
  }
  exit 0;
}
{
  my @m = max();
  ### max empty: @m
  exit 0;
}

{
  unlink '/tmp/tie-file.txt';
  system 'echo one >/tmp/tie-file.txt';
  system 'echo two >>/tmp/tie-file.txt';
  system 'echo three >>/tmp/tie-file.txt';
  system 'cat /tmp/tie-file.txt';
  my @array; # = (1,2,3);
  require Tie::File;
  tie @array, 'Tie::File', '/tmp/tie-file.txt' or die;
  foreach my $i (-7 .. 5) {
    my $e = (exists $array[$i] ? "E" : "n");
    print "$i $e\n";
  }
  exit 0;
}
