#!/usr/bin/perl -w

# Copyright 2011, 2013 Kevin Ryde

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


# Usage: perl beta-omega-table.pl
#
# Print the state tables used in BetaOmega.pm.
#
# This isn't a thing of beauty.  A state incorporates the beta vs omega
# shape and the orientation of that shape as 4 rotations by 90-degrees, a
# transpose swapping X,Y, and a reversal for numbering points the opposite
# way around.
#
# The reversal is only needed for the beta, as noted in the
# Math::PlanePath::BetaOmega POD.  For an omega the reverse is the same as
# the forward.  make_state() collapses a reverse omega down to corresponding
# plain forward omega.
#
# State values are 0, 4, 8, etc.  Having them 4 apart means a base 4 digit
# from N in n_to_xy() can be added state+digit to make an index into the
# tables.
#
# For @max_digit and @min_digit the input is instead 3*3=9 values, and in
# those tables the index is "state*3 + input".  3*state puts states 12
# apart, which is more than the 9 input values needs, but 3*state is a
# little less work in the code than say (state/4)*9 to change from 4-stride
# to exactly 9-stride.
#


use 5.010;
use strict;
use List::Util 'max';

# uncomment this to run the ### lines
#use Smart::Comments;


sub print_table {
  my ($name, $aref) = @_;
  print "my \@$name = (";
  my $entry_width = max (map {length($_//'')} @$aref);

  foreach my $i (0 .. $#$aref) {
    printf "%*s", $entry_width, $aref->[$i]//'undef';
    if ($i == $#$aref) {
      print ");\n";
    } else {
      print ",";
      if (($i % 16) == 15
          || ($entry_width >= 3 && ($i % 4) == 3)) {
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

    my @next_state;
  my @digit_to_x;
  my @digit_to_y;
  my @xy_to_digit;
  my @min_digit;
  my @max_digit;

  sub state_string {
    my ($state) = @_;
    my $digit = $state % 4; $state = int($state/4);
    my $transpose = $state % 2; $state = int($state/2);
    my $rot = $state % 4; $state = int($state/4);
    my $rev = $state % 2; $state = int($state/2);
    my $omega = $state % 2; $state = int($state/2);
    my $omega_str = ($omega ? 'omega' : 'beta');
    return "$omega_str transpose=$transpose rot=$rot rev=$rev";
  }
  sub make_state {
    my ($omega, $rev, $rot, $transpose, $digit) = @_;

    if ($omega && $rev) {
      $rev = 0;
      if ($transpose) {
        $rot--;
      } else {
        $rot++;
      }
      $transpose ^= 1;
    }

    $transpose %= 2;
    $rev %= 2;
    $rot %= 4;
    return $digit + 4*($transpose + 2*($rot + 4*($rev + 2*$omega)));
  }

  foreach my $omega (0, 1) {
    foreach my $rev (0, ($omega ? () : (1))) {
      foreach my $rot (0, 1, 2, 3) {
        foreach my $transpose (0, 1) {
          my $state = make_state ($omega, $rev, $rot, $transpose, 0);
          ### $state

          # range 0 [X,_]
          # range 1 [X,X]
          # range 2 [_,X]
          foreach my $xrange (0,1,2) {
            foreach my $yrange (0,1,2) {
              my $xr = $xrange;
              my $yr = $yrange;

              my $bits = $xr + 3*$yr; # before transpose etc

              if ($rot & 1) {
                ($xr,$yr) = ($yr,2-$xr);
              }
              if ($rot & 2) {
                $xr = 2-$xr;
                $yr = 2-$yr;
              }

              if ($transpose) {
                ($xr,$yr) = ($yr,$xr);
              }

              if ($rev) {
                # 2--1
                # |  |
                # 3  0
                $xr = 2-$xr;
              }


              my ($min_digit, $max_digit);

              # 1--2
              # |  |
              # 0  3
              if ($xr == 0) {
                # 0 or 1 only
                if ($yr == 0) {
                  # x,y both low, 0 only
                  $min_digit = 0;
                  $max_digit = 0;
                } elsif ($yr == 1) {
                  # y either, 0 or 1
                  $min_digit = 0;
                  $max_digit = 1;
                } elsif ($yr == 2) {
                  # y high, 1 only
                  $min_digit = 1;
                  $max_digit = 1;
                }
              } elsif ($xr == 1) {
                # x either, any 0,1,2,3
                if ($yr == 0) {
                  # y low, 0 or 3
                  $min_digit = 0;
                  $max_digit = 3;
                } elsif ($yr == 1) {
                  # y either, 0,1,2,3
                  $min_digit = 0;
                  $max_digit = 3;
                } elsif ($yr == 2) {
                  # y high, 1,2 only
                  $min_digit = 1;
                  $max_digit = 2;
                }
              } else {
                # x high, 2 or 3
                if ($yr == 0) {
                  # y low, 3 only
                  $min_digit = 3;
                  $max_digit = 3;
                } elsif ($yr == 1) {
                  # y either, 2 or 3
                  $min_digit = 2;
                  $max_digit = 3;
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

            if ($rev) {
              $digit = 3-$digit;
            }

            my $xo = 0;
            my $yo = 0;
            my $new_transpose = $transpose;
            my $new_rot = $rot;
            my $new_omega = 0;
            my $new_rev = $rev;

            if ($omega) {
              #   1---2
              #   |   |
              # --0   3--
              $new_omega = 0;
              if ($digit == 0) {
                $new_transpose = $transpose ^ 1;
                if ($transpose) {
                  $new_rot = $rot + 1;
                } else {
                  $new_rot = $rot - 1;
                }
              } elsif ($digit == 1) {
                $yo = 1;
                if ($transpose) {
                  $new_rot = $rot - 1;
                } else {
                  $new_rot = $rot + 1;
                }
              } elsif ($digit == 2) {
                $xo = 1;
                $yo = 1;
                $new_transpose = $transpose ^ 1;
                $new_rev ^= 1;
              } elsif ($digit == 3) {
                $xo = 1;
                $new_rot = $rot + 2;
                $new_rev ^= 1;
              }

            } else {
              #   1---2
              #   |   |
              # --0   3
              #       |
              if ($digit == 0) {
                $new_transpose = $transpose ^ 1;
                if ($transpose) {
                  $new_rot = $rot + 1;
                } else {
                  $new_rot = $rot - 1;
                }
              } elsif ($digit == 1) {
                $yo = 1;
                if ($transpose) {
                  $new_rot = $rot - 1;
                } else {
                  $new_rot = $rot + 1;
                }
              } elsif ($digit == 2) {
                $xo = 1;
                $yo = 1;
                $new_transpose = $transpose ^ 1;
                $new_rev ^= 1;
              } elsif ($digit == 3) {
                $xo = 1;
                if ($transpose) {
                  $new_rot = $rot + 1;
                } else {
                  $new_rot = $rot - 1;
                }
                $new_omega = 1;
              }
            }
            ### base: "$xo, $yo"

            if ($transpose) {
              ($xo,$yo) = ($yo,$xo);
            }
            ### transp to: "$xo, $yo"

            if ($rot & 2) {
              $xo ^= 1;
              $yo ^= 1;
            }
            if ($rot & 1) {
              ($xo,$yo) = ($yo^1,$xo);
            }
            ### rot to: "$xo, $yo"

            $digit_to_x[$state+$orig_digit] = $xo;
            $digit_to_y[$state+$orig_digit] = $yo;
            $xy_to_digit[$state + $xo*2+$yo] = $orig_digit;

            my $next_state = make_state
              ($new_omega, $new_rev, $new_rot, $new_transpose, 0);
            $next_state[$state+$orig_digit] = $next_state;
          }
        }
      }
    }
  }



  ### @next_state
  ### @digit_to_x
  ### @digit_to_y
  ### next_state length: 4*(4*2*2 + 4*2)
  ### next_state length: scalar(@next_state)

  my $next_state_size = scalar(@next_state);
  my $state_count = $next_state_size/4;
  print "# next_state table has $next_state_size entries, is $state_count states\n";
  print_table ("next_state", \@next_state);
  print_table ("digit_to_x", \@digit_to_x);
  print_table ("digit_to_y", \@digit_to_y);
  print_table ("xy_to_digit", \@xy_to_digit);
  print_table12 ("min_digit", \@min_digit);
  print_table12 ("max_digit", \@max_digit);

  my $invert_state = make_state (0,  # omega
                                 0,  # rev
                                 3,  # rot
                                 1,  # transpose
                                 0); # digit
  ### $invert_state

  print "\n";

  {
    my @pending_state = (0);
    my $count = 0;
    my @seen_state;
    my $depth = 0;
    $seen_state[0] = $depth;
    while (@pending_state) {
      $depth++;
      my @new_pending_state;
      foreach my $state (@pending_state) {
        $count++;
        ### consider state: $state

        foreach my $digit (0 .. 3) {
          my $next_state = $next_state[$state+$digit];
          if (! defined $seen_state[$next_state]) {
            $seen_state[$next_state] = $depth;
            push @new_pending_state, $next_state;
            ### push: "$next_state  depth $depth"
          }
        }
      }
      @pending_state = @new_pending_state;
    }
    for (my $state = 0; $state < @next_state; $state += 4) {
      print "# used state $state   depth $seen_state[$state]\n";
    }
    print "used state count $count\n";
  }

  {
    print "\n";
    print "initial 0:  ",state_string(0),"\n";
    print "initial 28: ",state_string(28),"\n";
    require Graph::Easy;
    my $g = Graph::Easy->new;
    for (my $state = 0; $state < scalar(@next_state); $state += 4) {
      my $next = $next_state[$state];
      $g->add_edge("$state: ".state_string($state),
                   "$next: ".state_string($next));
    }
    print $g->as_ascii();
  }

  exit 0;
