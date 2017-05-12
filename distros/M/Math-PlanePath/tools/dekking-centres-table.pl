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

use 5.004;
use strict;
use List::Util 'max';

# uncomment this to run the ### lines
#use Smart::Comments;


sub print_table {
  my ($name, $aref) = @_;
  print "my \@$name = (";
  my $entry_width = max (map {length} @$aref);

  foreach my $i (0 .. $#$aref) {
    printf "%*d", $entry_width, $aref->[$i];
    if ($i == $#$aref) {
      print ");\n";
    } else {
      print ",";
      if ($entry_width >= 2 && ($i % 25) == 4) {
        print "  # ".($i-4);
      }
      if (($i % 25) == 24
          || $entry_width >= 2 && ($i % 5) == 4) {
        print "\n        ".(" " x length($name));
      } elsif (($i % 5) == 4) {
        print " ";
      }
    }
  }
}

  sub make_state {
    my ($rev, $rot) = @_;

    $rev %= 2;
    $rot %= 4;
    return 25*($rot + 4*$rev);
  }

  my @next_state;
  my @digit_to_x;
  my @digit_to_y;
  my @yx_to_digit;

  foreach my $rev (0, 1) {
    foreach my $rot (0, 1, 2, 3) {
      foreach my $orig_digit (0 .. 24) {
        my $digit = $orig_digit;

        if ($rev) {
          $digit = 24-$digit;
        }

        my $xo;
        my $yo;
        my $new_rot = $rot;
        my $new_rev = $rev;

        if ($digit == 0) {
          $xo = 0;
          $yo = 0;
        } elsif ($digit == 1) {
          $xo = 1;
          $yo = 0;
        } elsif ($digit == 2) {
          $xo = 2;
          $yo = 0;
          $new_rot = $rot - 1;
          $new_rev ^= 1;
        } elsif ($digit == 3) {
          $xo = 1;
          $yo = 1;
          $new_rev ^= 1;
        } elsif ($digit == 4) {
          $xo = 0;
          $yo = 1;
          $new_rot = $rot + 1;
        } elsif ($digit == 5) {
          $xo = 1;
          $yo = 2;
        } elsif ($digit == 6) {
          $xo = 2;
          $yo = 2;
          $new_rot = $rot - 1;
          $new_rev ^= 1;
        } elsif ($digit == 7) {
          $xo = 1;
          $yo = 3;
          $new_rev ^= 1;
        } elsif ($digit == 8) {
          $xo = 0;
          $yo = 2;
          $new_rot = $rot + 2;
        } elsif ($digit == 9) {
          $xo = 0;
          $yo = 3;
          $new_rot = $rot - 1;
          $new_rev ^= 1;
        } elsif ($digit == 10) {
          $xo = 0;
          $yo = 4;
        } elsif ($digit == 11) {
          $xo = 1;
          $yo = 4;
        } elsif ($digit == 12) {
          $xo = 2;
          $yo = 3;
          $new_rot = $rot + 2;
          $new_rev ^= 1;
        } elsif ($digit == 13) {
          $xo = 2;
          $yo = 4;
          $new_rot = $rot + 1;
        } elsif ($digit == 14) {
          $xo = 3;
          $yo = 4;
          $new_rot = $rot + 2;
          $new_rev ^= 1;
        } elsif ($digit == 15) {
          $xo = 4;
          $yo = 4;
          $new_rot = $rot - 1;
        } elsif ($digit == 16) {
          $xo = 4;
          $yo = 3;
          $new_rot = $rot - 1;
        } elsif ($digit == 17) {
          $xo = 3;
          $yo = 3;
          $new_rev ^= 1;
        } elsif ($digit == 18) {
          $xo = 3;
          $yo = 2;
          $new_rot = $rot - 1;
        } elsif ($digit == 19) {
          $xo = 2;
          $yo = 1;
          $new_rot = $rot + 1;
          $new_rev ^= 1;
        } elsif ($digit == 20) {
          $xo = 3;
          $yo = 0;
          $new_rot = $rot + 2;
          $new_rev ^= 1;
        } elsif ($digit == 21) {
          $xo = 3;
          $yo = 1;
          $new_rot = $rot + 1;
        } elsif ($digit == 22) {
          $xo = 4;
          $yo = 2;
        } elsif ($digit == 23) {
          $xo = 4;
          $yo = 1;
          $new_rot = $rot + 1;
          $new_rev ^= 1;
        } elsif ($digit == 24) {
          $xo = 4;
          $yo = 0;
          $new_rot = $rot + 1;
          $new_rev ^= 1;
        } else {
          die;
        }
        ### base: "$xo, $yo"

        if ($rot & 2) {
          $xo = 4 - $xo;
          $yo = 4 - $yo;
        }
        if ($rot & 1) {
          ($xo,$yo) = (4-$yo,$xo);
        }
        ### rot to: "$xo, $yo"

        my $state = make_state ($rev, $rot);
        $digit_to_x[$state+$orig_digit] = $xo;
        $digit_to_y[$state+$orig_digit] = $yo;
        $yx_to_digit[$state + $yo*5+$xo] = $orig_digit;

        my $next_state = make_state ($new_rev, $new_rot);
        $next_state[$state+$orig_digit] = $next_state;
      }
    }
  }

  print "# state length ",scalar(@next_state)," in each of 4 tables\n";
  print_table ("next_state", \@next_state);
  print_table ("digit_to_x", \@digit_to_x);
  print_table ("digit_to_y", \@digit_to_y);
  print_table ("yx_to_digit", \@yx_to_digit);

  ### @next_state
  ### @digit_to_x
  ### @digit_to_y
  ### @yx_to_digit
  ### next_state length: scalar(@next_state)


  {
    my @pending_state = (0);
    my $count = 0;
    my @seen_state;
    my $depth = 1;
    $seen_state[0] = $depth;
    while (@pending_state) {
      my $state = pop @pending_state;
      $count++;
      ### consider state: $state

      foreach my $digit (0 .. 24) {
        my $next_state = $next_state[$state+$digit];
        if (! $seen_state[$next_state]) {
          $seen_state[$next_state] = $depth;
          push @pending_state, $next_state;
          ### push: "$next_state  depth $depth"
        }
      }
      $depth++;
    }
    for (my $state = 0; $state < @next_state; $state += 25) {
      print "# used state $state   depth $seen_state[$state]\n";
    }
    print "used state count $count\n";
  }

  print "\n";
  exit 0;
