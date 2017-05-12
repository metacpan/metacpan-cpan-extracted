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

sub min_maybe {
  return min(grep {defined} @_);
}
sub max_maybe {
  return max(grep {defined} @_);
}

sub print_table {
  my ($name, $aref) = @_;
  print "my \@$name = (";
  my $entry_width = max (map {length($_//'undef')} @$aref);

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
    my ($transpose, $rot) = @_;

    $transpose %= 2;
    $rot %= 4;
    unless ($rot == 0 || $rot == 2) {
      die "bad rotation $rot";
    }
    return 25*($rot/2 + 2*$transpose);
  }

  my @next_state;
  my @digit_to_x;
  my @digit_to_y;
  my @yx_to_digit;
  my @min_digit;
  my @max_digit;

  foreach my $transpose (0, 1) {
    foreach my $rot (0, 2) {
      my $state = make_state ($transpose, $rot);
      ### $state

      foreach my $orig_digit (0 .. 24) {
        my $digit = $orig_digit;

        # if ($rev) {
        #   $digit = 24-$digit;
        # }

        my $xo;
        my $yo;
        my $new_rot = $rot;
        my $new_transpose = $transpose;
        my $inc_rot = 0;

        if ($digit == 0) {
          $xo = 0;
          $yo = 0;
        } elsif ($digit == 1) {
          $xo = 1;
          $yo = 0;
        } elsif ($digit == 2) {
          $xo = 2;
          $yo = 0;
          $new_transpose ^= 1;
        } elsif ($digit == 3) {
          $xo = 2;
          $yo = 1;
          $new_transpose ^= 1;
        } elsif ($digit == 4) {
          $xo = 2;
          $yo = 2;
          $new_transpose ^= 1;
        } elsif ($digit == 5) {
          $xo = 1;
          $yo = 2;
          $inc_rot = 2;
          $new_transpose ^= 1;
        } elsif ($digit == 6) {
          $xo = 1;
          $yo = 1;
          $inc_rot = 2;
        } elsif ($digit == 7) {
          $xo = 0;
          $yo = 1;
          $inc_rot = 2;
        } elsif ($digit == 8) {
          $xo = 0;
          $yo = 2;
          $new_transpose ^= 1;
        } elsif ($digit == 9) {
          $xo = 0;
          $yo = 3;
          $new_transpose ^= 1;
        } elsif ($digit == 10) {
          $xo = 0;
          $yo = 4;
        } elsif ($digit == 11) {
          $xo = 1;
          $yo = 4;
        } elsif ($digit == 12) {
          $xo = 1;
          $yo = 3;
          $inc_rot = 2;
          $new_transpose ^= 1;
        } elsif ($digit == 13) {
          $xo = 2;
          $yo = 3;
          $new_transpose ^= 1;
        } elsif ($digit == 14) {
          $xo = 2;
          $yo = 4;
        } elsif ($digit == 15) {
          $xo = 3;
          $yo = 4;
        } elsif ($digit == 16) {
          $xo = 4;
          $yo = 4;
        } elsif ($digit == 17) {
          $xo = 4;
          $yo = 3;
          $inc_rot = 2;
        } elsif ($digit == 18) {
          $xo = 3;
          $yo = 3;
          $inc_rot = 2;
          $new_transpose ^= 1;
        } elsif ($digit == 19) {
          $xo = 3;
          $yo = 2;
          $inc_rot = 2;
          $new_transpose ^= 1;
        } elsif ($digit == 20) {
          $xo = 4;
          $yo = 2;
        } elsif ($digit == 21) {
          $xo = 4;
          $yo = 1;
          $inc_rot = 2;
        } elsif ($digit == 22) {
          $xo = 3;
          $yo = 1;
          $inc_rot = 2;
          $new_transpose ^= 1;
        } elsif ($digit == 23) {
          $xo = 3;
          $yo = 0;
          $inc_rot = 2;
          $new_transpose ^= 1;
        } elsif ($digit == 24) {
          $xo = 4;
          $yo = 0;
        } else {
          die;
        }
        ### base: "$xo, $yo"

        if ($transpose) {
          ($xo,$yo) = ($yo,$xo);
          $inc_rot = - $inc_rot;
        }

        $new_rot = $rot + $inc_rot;

        if ($rot & 2) {
          $xo = 4 - $xo;
          $yo = 4 - $yo;
        }
        if ($rot & 1) {
          ($xo,$yo) = (4-$yo,$xo);
        }
        ### rot to: "$xo, $yo"

        $digit_to_x[$state+$orig_digit] = $xo;
        $digit_to_y[$state+$orig_digit] = $yo;
        $yx_to_digit[$state + $yo*5+$xo] = $orig_digit;

        my $next_state = make_state ($new_transpose, $new_rot);
        $next_state[$state+$orig_digit] = $next_state;
      }

      # N = (- 1/2 d^2 + 9/2 d)
      #   = (- 1/2*$d**2 + 9/2*$d)
      #   = ((9 - d)d/2

      # (9-d)*d/2
      # d=0 (9-0)*0/2 = 0
      # d=1 (9-1)*1/2 - 1 = 8/2-1 = 3
      # d=2 (9-2)*2/2 - 2 = 7-1 = 6
      # d=4 (9-4)*4/2 = 5*4/2 = 10
      #
      foreach my $x1pos (0 .. 4) {
        foreach my $x2pos ($x1pos .. 4) {
          my $xkey = (9-$x1pos)*$x1pos/2 + $x2pos;
          ### $xkey
          ### assert: $xkey >= 0
          ### assert: $xkey < 15

          foreach my $y1pos (0 .. 4) {
            foreach my $y2pos ($y1pos .. 4) {
              my $ykey = (9-$y1pos)*$y1pos/2 + $y2pos;
              ### $ykey
              ### assert: $ykey >= 0
              ### assert: $ykey < 15

              my $min_digit = undef;
              my $max_digit = undef;
              foreach my $digit (0 .. 24) {
                my $x = $digit_to_x[$digit];
                my $y = $digit_to_y[$digit];
                if ($rot & 2) {
                  $x = 4 - $x;
                  $y = 4 - $y;
                }
                if ($transpose) {
                  ($x,$y) = ($y,$x);
                }
                next unless $x >= $x1pos;
                next unless $x <= $x2pos;
                next unless $y >= $y1pos;
                next unless $y <= $y2pos;
                $min_digit = min_maybe($digit,$min_digit);
                $max_digit = max_maybe($digit,$max_digit);
              }

              my $key = $state*9 + $xkey*15 + $ykey;
              ### $key

              if (defined $min_digit[$key]) {
                die "oops min_digit[] already: state=$state key=$key y1p=$y1pos y2p=$y2pos value=$min_digit[$key], new=$min_digit";
              }
              $min_digit[$key] = $min_digit;
              $max_digit[$key] = $max_digit;
            }
          }
          ### @min_digit
        }
      }
    }
  }

  print_table ("next_state", \@next_state);
  print_table ("digit_to_x", \@digit_to_x);
  print_table ("digit_to_y", \@digit_to_y);
  print_table ("yx_to_digit", \@yx_to_digit);
  print_table ("min_digit", \@min_digit);
  print_table ("max_digit", \@max_digit);
  print "# state length ",scalar(@next_state)," in each of 4 tables\n\n";

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
      print "# used state $state   depth ",$seen_state[$state]//'undef',"\n";
    }
    print "used state count $count\n";
  }

  print "\n";
  exit 0;
