#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Carp 'croak';
use Math::PlanePath::KochCurve;

{
  require Language::Logo;
  my $lo = Logo->new(update => 2, port => 8200 + (time % 100));
  my $draw;
  # $lo->command("seth 135; backward 200; seth 90");
  $lo->command("pendown; hideturtle; seth 90");
  my $angle = 0;
  foreach my $n (1 .. 4096) {
    my $a = A309873($n);
    my $angle = $a*165;
    $lo->command("forward 13; left $angle");
  }
  $lo->disconnect("Finished...");
  exit 0;
}

sub A309873 {
  my ($n) = @_;
  $n >= 0 || croak;
  my $ret = 1;
  until ($n & 1) {
    $n >>= 1;
    $ret = -$ret;
  }
  return $ret;
}
{
  # A056832 All a(n) = 1 or 2; a(1) = 1; get next 2^k terms by repeating
  # first 2^k terms and changing last element so sum of first 2^(k+1) terms
  # is odd.
  # 
  # Is lowest non-zero base4 digit(n) 1,3->a(n)=1 2->a(n)=2.
  # a(2^k) flips 1<->2 each time for low non-zero flipping 1<->2.
  # a(2^k) always flips because odd sum becomes even on duplicating.
  #
  my @a = (1);
  for my $i (1 .. 6) {
    push @a, @a;
    unless (sum(@a) & 1) {
      $a[-1] = 3-$a[-1];  # 2<->1
      print "i=$i flip last\n";
    }
    print @a,"\n";
  }

  foreach my $i (1 .. 64) {
    my $d = base4_lowest_nonzero_digit($i);
    if ($d != 2) { $d = 1; }
    print $d;
  }
  print "\n";

  exit 0;
}
