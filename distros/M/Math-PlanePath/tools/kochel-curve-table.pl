#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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
use List::Util 'min','max';

# uncomment this to run the ### lines
#use Smart::Comments;


sub print_table {
  my ($name, $aref) = @_;
  print "my \@$name = (";
  my $entry_width = max (map {defined && length} @$aref);

  foreach my $i (0 .. $#$aref) {
    printf "%*s", $entry_width, $aref->[$i]//'undef';
    if ($i == $#$aref) {
      print ");   # ",$i-8,"\n";
    } else {
      print ",";
      if (($i % 9) == 8) {
        print "    # ".($i-8);
      }
      if (($i % 9) == 8) {
        print "\n        ".(" " x length($name));
      } elsif (($i % 3) == 2) {
        print " ";
      }
    }
  }
}

sub print_table36 {
  my ($name, $aref) = @_;
  print "my \@$name = (";
  my $entry_width = max (map {defined && length} @$aref);

  foreach my $i (0 .. $#$aref) {
    printf "%*d", $entry_width, $aref->[$i];
    if ($i == $#$aref) {
      print ");\n";
    } else {
      print ",";
      if (($i % 36) == 5) {
        print "    # ".($i-5);
      }
      if (($i % 6) == 5) {
        print "\n        ".(" " x length($name));
      } elsif (($i % 6) == 5) {
        print " ";
      }
    }
  }
}

  sub make_state {
    my ($f, $rev, $rot) = @_;
    $rev %= 2;
    if ($f && $rev) {
      $rot += 2;
      $rev = 0;
    }
    $rot %= 4;
    return 9*($rot + 4*($rev + 2*$f));
  }

  # x__  0
  # xx_  1
  # xxx  2
  # _xx  3
  # __x  4
  # _x_  5
  my @r_to_cover = ([1,0,0],
                    [1,1,0],
                    [1,1,1],
                    [0,1,1],
                    [0,0,1],
                    [0,1,0]);
  my @reverse_range = (4,3,2,1,0,5);
  my @min_digit;
  my @max_digit;

  my @next_state;
  my @digit_to_x;
  my @digit_to_y;
  my @xy_to_digit;

  foreach my $f (0, 1) {
    foreach my $rot (0, 1, 2, 3) {
      foreach my $rev (0, ($f ? () : (1))) {
        my $state = make_state ($f, $rev, $rot);

        foreach my $orig_digit (0 .. 8) {
          my $digit = $orig_digit;

          if ($rev) {
            $digit = 8-$digit;
          }

          my $xo;
          my $yo;
          my $new_rot = $rot;
          my $new_rev = $rev;
          my $new_f;

          if ($f) {
            if ($digit == 0) {
              $xo = 0;
              $yo = 0;
              $new_f = 0;
              $new_rev ^= 1;
              $new_rot = $rot - 1;
            } elsif ($digit == 1) {
              $xo = 0;
              $yo = 1;
              $new_f = 1;
            } elsif ($digit == 2) {
              $xo = 0;
              $yo = 2;
              $new_f = 0;
              $new_rot = $rot + 1;
            } elsif ($digit == 3) {
              $xo = 1;
              $yo = 2;
              $new_rot = $rot - 1;
              $new_f = 1;
            } elsif ($digit == 4) {
              $xo = 1;
              $yo = 1;
              $new_f = 1;
              $new_rot = $rot + 2;
            } elsif ($digit == 5) {
              $xo = 1;
              $yo = 0;
              $new_f = 1;
              $new_rot = $rot - 1;
            } elsif ($digit == 6) {
              $xo = 2;
              $yo = 0;
              $new_f = 0;
              $new_rot = $rot - 1;
              $new_rev ^= 1;
            } elsif ($digit == 7) {
              $xo = 2;
              $yo = 1;
              $new_f = 1;
            } elsif ($digit == 8) {
              $xo = 2;
              $yo = 2;
              $new_f = 0;
              $new_rot = $rot + 1;
            } else {
              die;
            }
          } else {
            if ($digit == 0) {
              $xo = 0;
              $yo = 0;
              $new_rev ^= 1;
              $new_f = 0;
              $new_rot = $rot - 1;
            } elsif ($digit == 1) {
              $xo = 0;
              $yo = 1;
              $new_f = 1;
            } elsif ($digit == 2) {
              $xo = 0;
              $yo = 2;
              $new_f = 0;
              $new_rot = $rot + 1;
            } elsif ($digit == 3) {
              $xo = 1;
              $yo = 2;
              $new_rot = $rot - 1;
              $new_f = 1;
            } elsif ($digit == 4) {
              $xo = 2;
              $yo = 2;
              $new_f = 0;
            } elsif ($digit == 5) {
              $xo = 2;
              $yo = 1;
              $new_f = 1;
              $new_rot = $rot + 2;
            } elsif ($digit == 6) {
              $xo = 1;
              $yo = 1;
              $new_f = 0;
              $new_rev ^= 1;
            } elsif ($digit == 7) {
              $xo = 1;
              $yo = 0;
              $new_f = 1;
              $new_rot = $rot - 1;
            } elsif ($digit == 8) {
              $xo = 2;
              $yo = 0;
              $new_f = 0;
            } else {
              die;
            }
          }
          ### base: "$xo, $yo"

          if ($rot & 2) {
            $xo = 2 - $xo;
            $yo = 2 - $yo;
          }
          if ($rot & 1) {
            ($xo,$yo) = (2-$yo,$xo);
          }
          ### rot to: "$xo, $yo"

          $digit_to_x[$state+$orig_digit] = $xo;
          $digit_to_y[$state+$orig_digit] = $yo;
          $xy_to_digit[$state + 3*$xo + $yo] = $orig_digit;

          my $next_state = make_state ($new_f, $new_rev, $new_rot);
          $next_state[$state+$orig_digit] = $next_state;
        }


        foreach my $xrange (0 .. 5) {
          foreach my $yrange (0 .. 5) {
            my $xr = $xrange;
            my $yr = $yrange;
            my $bits = $xr + 6*$yr; # before transpose etc
            my $key = 4*$state + $bits;
            ### assert: (4*$state % 36) == 0

            my $min_digit = 8;
            my $max_digit = 0;
            foreach my $digit (0 .. 8) {
              my $x = $digit_to_x[$state + $digit];
              my $y = $digit_to_y[$state + $digit];
              next unless $r_to_cover[$xr]->[$x];
              next unless $r_to_cover[$yr]->[$y];
              $min_digit = min($digit,$min_digit);
              $max_digit = max($digit,$max_digit);
            }

            ### min/max: "state=$state 4*state=".(4*$state)." bits=$bits key=$key"
            if (defined $min_digit[$key]) {
              # die "oops min_digit[] already: state=$state bits=$bits value=$min_digit[$state+$bits], new=$min_digit";
            }
            $min_digit[$key] = $min_digit;
            $max_digit[$key] = $max_digit;
          }
        }
        ### @min_digit
      }
    }
  }

  print_table ("next_state", \@next_state);
  print_table ("digit_to_x", \@digit_to_x);
  print_table ("digit_to_y", \@digit_to_y);
  print_table ("xy_to_digit", \@xy_to_digit);
  print_table36 ("min_digit", \@min_digit);
  print_table36 ("max_digit", \@max_digit);
  print "# state length ",scalar(@next_state)," in each of 4 tables\n\n";
  print "# R reverse state ",make_state(0,1,-1),"\n";

  ### @next_state
  ### @digit_to_x
  ### @digit_to_y
  ### @xy_to_digit
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

      foreach my $digit (0 .. 8) {
        my $next_state = $next_state[$state+$digit];
        if (! $seen_state[$next_state]) {
          $seen_state[$next_state] = $depth;
          push @pending_state, $next_state;
          ### push: "$next_state  depth $depth"
        }
      }
      $depth++;
    }
    for (my $state = 0; $state < @next_state; $state += 9) {
      print "# used state $state   depth $seen_state[$state]\n";
    }
    print "used state count $count\n";
  }

  print "\n";
  exit 0;
