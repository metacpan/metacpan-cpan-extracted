#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

# uncomment this to run the ### lines
#use Smart::Comments;


sub make_state {
  my ($rev, $rot) = @_;
  $rev %= 2;
  $rot %= 4;
  return 10*($rot + 4*$rev);
}
sub state_string {
  my ($state) = @_;
  my $digit = $state % 10; $state = int($state/10);
  my $rot = $state % 4; $state = int($state/4);
  my $rev = $state % 2; $state = int($state/2);
  return "rot=$rot rev=$rev" . ($digit ? " digit=$digit" : "");
}

my @min_digit;
my @max_digit;

my @next_state;
my @digit_to_x;
my @digit_to_y;
my @xy_to_digit;

my @unrot_digit_to_x = (0,1,1, 0,-1,-2, -2,-2,-3, -3);
my @unrot_digit_to_y = (0,0,1, 1, 1, 1,  0,-1,-1,  0);
my @segment_to_rev = (0,0,0, 1,0,0, 1,1,1, 0);
my @segment_to_dir = (0,1,2, 2,2,3, 3,2,1, 0);

foreach my $rot (0, 1, 2, 3) {
  foreach my $rev (0, 1) {
    my $state = make_state ($rev, $rot);

    foreach my $digit (0 .. 9) {
      my $xo = $unrot_digit_to_x[$rev ? 9-$digit : $digit];
      my $yo = $unrot_digit_to_y[$rev ? 9-$digit : $digit];
      if ($rev) { $xo += 3 }

      my $new_rev = $rev ^ $segment_to_rev[$rev ? 8-$digit : $digit];
      my $new_rot = $rot + $segment_to_dir[$rev ? 8-$digit : $digit];
      if ($new_rev) {
        $new_rot += 0;
      } else {
        $new_rot += 2;
      }
      if ($rev) {
        $new_rot += 2;
      } else {
        $new_rot += 0;
      }

      if ($rot & 2) {
        $xo = - $xo;
        $yo = - $yo;
      }
      if ($rot & 1) {
        ($xo,$yo) = (-$yo,$xo);
      }
      ### rot to: "$xo, $yo"

      $digit_to_x[$state+$digit] = $xo;
      $digit_to_y[$state+$digit] = $yo;

      # $xy_to_digit[$state + 3*$xo + $yo] = $orig_digit;

      my $next_state = make_state ($new_rev, $new_rot);
      if ($digit == 9) { $next_state = undef; }
      $next_state[$state+$digit] = $next_state;
    }
  }
}


use List::Util 'min','max';

sub print_table {
  my ($name, $aref) = @_;
  print "my \@$name = (";
  my $entry_width = max (map {defined && length} @$aref);

  foreach my $i (0 .. $#$aref) {
    printf "%*s", $entry_width, $aref->[$i]//'undef';
    if ($i == $#$aref) {
      print ");   # ",$i-9,"\n";
    } else {
      print ",";
      if (($i % 10) == 9) {
        print "    # ".($i-9);
      }
      if (($i % 10) == 9) {
        print "\n        ".(" " x length($name));
      } elsif (($i % 3) == 2) {
        print " ";
      }
    }
  }
}

    print_table ("next_state", \@next_state);
  print_table ("digit_to_x", \@digit_to_x);
  print_table ("digit_to_y", \@digit_to_y);
  # print_table ("xy_to_digit", \@xy_to_digit);
  # print_table36 ("min_digit", \@min_digit);
  # print_table36 ("max_digit", \@max_digit);
  print "# state length ",scalar(@next_state)," in each of 4 tables\n";
  print "# rot2 state ",make_state(0,2),"\n";
  exit 0;

