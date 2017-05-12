#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


# Generate state tables for Math::PlanePath::LCornerReplicate.
#

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
    printf "%d", $aref->[$i];
    if ($i == $#$aref) {
      print ");\n";
    } else {
      print ",";
      if (($i % 16) == 15) {
        print "\n        ".(" " x length($name));
      } elsif (($i % 4) == 3) {
        print " ";
      }
    }
  }
}

sub print_table12 {
    my ($name, $aref) = @_;
    print "my \@$name = (";
    my $entry_width = max (map {length($_//'')} @$aref);

    foreach my $i (0 .. $#$aref) {
      printf "%*s", $entry_width, $aref->[$i]//'undef';
      if ($i == $#$aref) {
        print ");\n";
      } else {
        print ",";
        if (($i % 12) == 11) {
          print "\n        ".(" " x length($name));
        } elsif (($i % 4) == 3) {
          print " ";
        }
      }
    }
  }
  
  sub make_state {
    my %param = @_;
    my $state = 0;
    $state <<= 2; $state |= (delete $param{'rot'}) & 3;
    $state <<= 2; $state |= delete $param{'digit'};      # low
    if (%param) { die; }
    return $state;
  }

  my @next_state;
  my @digit_to_x;
  my @digit_to_y;
  my @yx_to_digit;
  my @min_digit;
  my @max_digit;

  foreach my $rot (0, 1, 2, 3) {
    my $state = make_state (rot => $rot, digit => 0);

    # range 0 [X,_]
    # range 1 [X,X]
    # range 2 [_,X]
    foreach my $xrange (0,1,2) {
      foreach my $yrange (0,1,2) {
        my $xr = $xrange;
        my $yr = $yrange;

        my $rval = $xr + 3*$yr; # before rot

        if ($rot & 1) {
          ($xr,$yr) = ($yr,2-$xr);   # rotate -90
        }
        if ($rot & 2) {
          $xr = 2-$xr;  # rotate 180
          $yr = 2-$yr;
        }

        my ($min_digit, $max_digit);

        # 3--2
        #    |
        # 0--1
        if ($xr == 0) {
          # 0 or 3
          if ($yr == 0) {
            # x,y both low, 0 only
            $min_digit = 0;
            $max_digit = 0;
          } elsif ($yr == 1) {
            # y either, 0 or 3
            $min_digit = 0;
            $max_digit = 3;
          } elsif ($yr == 2) {
            # y high, 3 only
            $min_digit = 3;
            $max_digit = 3;
          }
        } elsif ($xr == 1) {
          # x either, any 0,1,2,3
          if ($yr == 0) {
            # y low, 0 or 1
            $min_digit = 0;
            $max_digit = 1;
          } elsif ($yr == 1) {
            # y either, 0,1,2,3
            $min_digit = 0;
            $max_digit = 3;
          } elsif ($yr == 2) {
            # y high, 2,3 only
            $min_digit = 2;
            $max_digit = 3;
          }
        } else {
          # x high, 1 or 2
          if ($yr == 0) {
            # y low, 1 only
            $min_digit = 1;
            $max_digit = 1;
          } elsif ($yr == 1) {
            # y either, 1 or 2
            $min_digit = 1;
            $max_digit = 2;
          } elsif ($yr == 2) {
            # y high, 2 only
            $min_digit = 2;
            $max_digit = 2;
          }
        }

        ### range store: $state+$rval
        my $key = 3*$state + $rval;
        if (defined $min_digit[$key]) {
          die "oops min_digit[] already: state=$state rval=$rval value=$min_digit[$state+$rval], new=$min_digit";
        }
        $min_digit[$key] = $min_digit;
        $max_digit[$key] = $max_digit;
      }
    }
    ### @min_digit


    foreach my $digit (0, 1, 2, 3) {
      my $xo = 0;
      my $yo = 0;
      my $new_rot = $rot;

      # 3--2
      #    |
      # 0--1

      if ($digit == 0) {

      } elsif ($digit == 1) {
        $xo = 1;
        $new_rot--;
      } elsif ($digit == 2) {
        $xo = 1;
        $yo = 1;
      } elsif ($digit == 3) {
        $yo = 1;
        $new_rot++;
      }
      ### base: "$xo, $yo"

      if ($rot & 1) {
        ($xo,$yo) = ($yo^1,$xo);   # rotate +90
      }
      if ($rot & 2) {
        $xo ^= 1;   # rotate 180
        $yo ^= 1;
      }
      ### rot to: "$xo, $yo"

      $digit_to_x[$state+$digit] = $xo;
      $digit_to_y[$state+$digit] = $yo;
      $yx_to_digit[$state + 2*$yo+$xo] = $digit;

      my $next_state = make_state (rot => $new_rot, digit => 0);
      $next_state[$state+$digit] = $next_state;
    }
  }

  ### @next_state
  ### @digit_to_x
  ### @digit_to_y
  ### next_state length: 4*(4*2*2 + 4*2)
  ### next_state length: scalar(@next_state)

  print_table ("next_state", \@next_state);
  print_table ("digit_to_x", \@digit_to_x);
  print_table ("digit_to_y", \@digit_to_y);
  print_table ("yx_to_digit", \@yx_to_digit);
  print_table12 ("min_digit", \@min_digit);
  print_table12 ("max_digit", \@max_digit);

  print "\n";
  exit 0;
