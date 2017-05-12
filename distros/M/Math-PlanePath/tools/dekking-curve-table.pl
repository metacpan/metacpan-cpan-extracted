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
use List::Util 'max';
use Math::PlanePath::DekkingCentres;

# uncomment this to run the ### lines
#use Smart::Comments;


sub print_table {
  my ($name, $aref) = @_;
  print "my \@$name = (";
  my $entry_width = max (map {defined $_ ? length : 5} @$aref);

  foreach my $i (0 .. $#$aref) {
    printf "%*s", $entry_width, $aref->[$i]//'undef';
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
    my @edge_dx;
    my @edge_dy;
    my @yx_to_digit;

    foreach my $rev (0, 1) {
      foreach my $rot (0, 1, 2, 3) {
        foreach my $orig_digit (0 .. 24) {
          my $digit = $orig_digit;

          if ($rev) {
            $digit = 25-$digit;
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
            $xo = 2;
            $yo = 1;
            $new_rev ^= 1;
          } elsif ($digit == 4) {
            $xo = 1;
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
            $xo = 2;
            $yo = 3;
            $new_rev ^= 1;
          } elsif ($digit == 8) {
            $xo = 1;
            $yo = 3;
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
            $yo = 4;
            $new_rot = $rot + 2;
            $new_rev ^= 1;
          } elsif ($digit == 13) {
            $xo = 3;
            $yo = 4;
            $new_rot = $rot + 1;
          } elsif ($digit == 14) {
            $xo = 3;
            $yo = 5;
            $new_rot = $rot + 2;
            $new_rev ^= 1;
          } elsif ($digit == 15) {
            $xo = 4;
            $yo = 5;
            $new_rot = $rot - 1;
          } elsif ($digit == 16) {
            $xo = 4;
            $yo = 4;
            $new_rot = $rot - 1;
          } elsif ($digit == 17) {
            $xo = 4;
            $yo = 3;
            $new_rev ^= 1;
          } elsif ($digit == 18) {
            $xo = 3;
            $yo = 3;
            $new_rot = $rot - 1;
          } elsif ($digit == 19) {
            $xo = 3;
            $yo = 2;
            $new_rot = $rot + 1;
            $new_rev ^= 1;
          } elsif ($digit == 20) {
            $xo = 3;
            $yo = 1;
            $new_rot = $rot + 2;
            $new_rev ^= 1;
          } elsif ($digit == 21) {
            $xo = 4;
            $yo = 1;
            $new_rot = $rot + 1;
          } elsif ($digit == 22) {
            $xo = 4;
            $yo = 2;
          } elsif ($digit == 23) {
            $xo = 5;
            $yo = 2;
            $new_rot = $rot + 1;
            $new_rev ^= 1;
          } elsif ($digit == 24) {
            $xo = 5;
            $yo = 1;
            $new_rot = $rot + 1;
            $new_rev ^= 1;
          } elsif ($digit == 25) {
            $xo = 5;
            $yo = 0;
            $new_rot = $rot + 1;
          } else {
            die;
          }
          ### base: "$xo, $yo"

          my $state = make_state ($rev, $rot);

          my $shift_xo = $xo;
          my $shift_yo = $yo;
          if ($rot & 2) {
            $shift_xo = 5 - $shift_xo;
            $shift_yo = 5 - $shift_yo;
          }
          if ($rot & 1) {
            ($shift_xo,$shift_yo) = (5-$shift_yo,$shift_xo);
          }
          $yx_to_digit[$state + $shift_yo*5 + $shift_xo] = $orig_digit;


          # if ($rev) {
          #   if (($rot % 4) == 0) {
          #   } elsif (($rot % 4) == 1) {
          #     $yo -= 1;
          #   } elsif (($rot % 4) == 2) {
          #     $yo -= 1;
          #     $xo -= 1;
          #   } elsif (($rot % 4) == 3) {
          #     $xo -= 1;
          #   }
          # } else {
          #   if (($rot % 4) == 0) {
          #   } elsif (($rot % 4) == 1) {
          #     $yo -= 1;
          #   } elsif (($rot % 4) == 2) {
          #     $yo -= 1;
          #     $xo -= 1;
          #   } elsif (($rot % 4) == 3) {
          #     $xo -= 1;
          #   }
          #   # $xo -= 1;
          # }

          if ($rot & 2) {
            $xo = 5 - $xo;
            $yo = 5 - $yo;
          }
          if ($rot & 1) {
            ($xo,$yo) = (5-$yo,$xo);
          }
          ### rot to: "$xo, $yo"

          $edge_dx[$state+$orig_digit] = $xo - $Math::PlanePath::DekkingCentres::_digit_to_x[$state+$orig_digit];
          $edge_dy[$state+$orig_digit] = $yo - $Math::PlanePath::DekkingCentres::_digit_to_y[$state+$orig_digit];

          my $next_state = make_state ($new_rev, $new_rot);
          $next_state[$state+$orig_digit] = $next_state;
        }
      }
    }

    print "# state length ",scalar(@next_state)," in each of 4 tables\n";
#    print_table ("next_state", \@next_state);
    print_table ("edge_dx", \@edge_dx);
    print_table ("edge_dy", \@edge_dy);
    # print_table ("last_yx_to_digit", \@yx_to_digit);

    ### @next_state
    ### @edge_dx
    ### @edge_dy
    ### @yx_to_digit
    ### next_state length: scalar(@next_state)


     print "\n";
    exit 0;
