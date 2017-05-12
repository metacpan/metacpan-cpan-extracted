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
      my ($rot, $transpose) = @_;

      $transpose %= 2;
      $rot %= 2;
      return 4*($transpose + 2*$rot);
    }

    my @next_state;
    my @digit_to_x;
    my @digit_to_y;
    my @yx_to_digit;
    my @min_digit;
    my @max_digit;

    foreach my $rot (0, 1) {
      foreach my $transpose (0, 1) {
        my $state = make_state ($rot, $transpose);

        # range 0 [X,_]
        # range 1 [X,X]
        # range 2 [_,X]
        foreach my $xrange (0,1,2) {
          foreach my $yrange (0,1,2) {
            my $xr = $xrange;
            my $yr = $yrange;

            my $bits = $xr + 3*$yr; # before rot+transpose

            if ($rot) {
              $xr = 2-$xr;
              $yr = 2-$yr;
            }
            if ($transpose) {
              ($xr,$yr) = ($yr,$xr);
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

            ### range store: $state+$bits
            my $key = 3*$state + $bits;
            if (defined $min_digit[$key]) {
              die "oops min_digit[] already: state=$state bits=$bits value=$min_digit[$state+$bits], new=$min_digit";
            }
            $min_digit[$key] = $min_digit;
            $max_digit[$key] = $max_digit;
          }
        }
        ### @min_digit


        foreach my $orig_digit (0, 1, 2, 3) {
          my $digit = $orig_digit;

          my $xo = 0;
          my $yo = 0;
          my $new_transpose = $transpose;
          my $new_rot = $rot;

          # 3--2
          #    |
          # 0--1

          if ($digit == 0) {
            $new_transpose ^= 1;
          } elsif ($digit == 1) {
            $xo = 1;
          } elsif ($digit == 2) {
            $xo = 1;
            $yo = 1;
          } elsif ($digit == 3) {
            $yo = 1;
            $new_transpose ^= 1;
            $new_rot ^= 1;
          }
          ### base: "$xo, $yo"

          if ($transpose) {
            ($xo,$yo) = ($yo,$xo);
          }
          ### transp to: "$xo, $yo"

          if ($rot) {
            $xo ^= 1;
            $yo ^= 1;
          }
          ### rot to: "$xo, $yo"

          $digit_to_x[$state+$orig_digit] = $xo;
          $digit_to_y[$state+$orig_digit] = $yo;
          $yx_to_digit[$state + 2*$yo + $xo] = $orig_digit;

          my $next_state = make_state ($new_rot, $new_transpose);
          $next_state[$state+$orig_digit] = $next_state;
        }
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

    my $invert_state = make_state (1,  # rot
                                   1); # transpose
    ### $invert_state

    print "\n";
    exit 0;


    __END__

      my $x_cmp = $x_max + $len;
    my $y_cmp = $y_max + $len;
    my $digit = $min_digit[4*$min_state + ($x1 >= $x_cmp) + 2*($x2 >= $x_cmp)
                           + ($y1 >= $y_cmp) + 2*($y2 >= $y_cmp)];
    $min_state += $digit;
    $n_lo += $digit * $power;
    if ($digit_to_x[$min_state]) { $x_min += $len; }
    if ($digit_to_y[$min_state]) { $x_min += $len; }
    $min_state = $next_state[$min_state + $min_digit];


