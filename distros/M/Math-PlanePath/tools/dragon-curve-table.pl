#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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


# Usage: perl dragon-curve-table.pl
#
# Print the state tables used for DragonCurve n_to_xy().


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

  my @next_state;
my @digit_to_x;
my @digit_to_y;
my @digit_to_dxdy;

sub make_state {
  my %param = @_;
  my $state = 0;
  $state <<= 1; $state |= delete $param{'rev'};
  $state <<= 2; $state |= delete $param{'rot'};
  $state <<= 2; $state |= delete $param{'digit'};
  return $state;
}
sub state_string {
  my ($state) = @_;
  my $digit = $state & 3;  $state >>= 2;
  my $rot = $state & 3;  $state >>= 2;
  my $rev = $state & 1;  $state >>= 1;
  return "rot=$rot  rev=$rev (digit=$digit)";
}

foreach my $rot (0 .. 3) {
  foreach my $rev (0, 1) {
    foreach my $digit (0, 1, 2, 3) {
      my $state = make_state (rot => $rot, rev => $rev, digit => $digit);

      my $new_rev;
      my $new_rot = $rot;

      my $x;
      my $y;
      if ($rev) {
        #
        #      2<--3
        #      ^   |
        #      |   v
        #  0<--1   *
        #
        if ($digit == 0) {
          $x = 0;
          $y = 0;
          $new_rev = 0;
        } elsif ($digit == 1) {
          $x = 1;
          $y = 0;
          $new_rev = 1;
          $new_rot++;
        } elsif ($digit == 2) {
          $x = 1;
          $y = 1;
          $new_rev = 0;
        } elsif ($digit == 3) {
          $x = 2;
          $y = 1;
          $new_rev = 1;
          $new_rot--;
        }
      } else {
        #
        #  0   3<--*
        #  |   ^
        #  v   |
        #  1<--2
        #
        if ($digit == 0) {
          $x = 0;
          $y = 0;
          $new_rev = 0;
          $new_rot--;
        } elsif ($digit == 1) {
          $x = 0;
          $y = -1;
          $new_rev = 1;
        } elsif ($digit == 2) {
          $x = 1;
          $y = -1;
          $new_rev = 0;
          $new_rot++;
        } elsif ($digit == 3) {
          $x = 1;
          $y = 0;
          $new_rev = 1;
        }
      }
      $new_rot &= 3;

      my $dx = 1;
      my $dy = 0;

      if ($rot & 2) {
        $x = -$x;
        $y = -$y;
        $dx = -$dx;
        $dy = -$dy;
      }
      if ($rot & 1) {
        ($x,$y) = (-$y,$x); # rotate +90
        ($dx,$dy) = (-$dy,$dx); # rotate +90
      }
      ### rot to: "$x, $y"

      my $next_dx = $x;
      my $next_dy = $y;
      $digit_to_x[$state] = $x;
      $digit_to_y[$state] = $y;

      if ($digit == 0) {
        $digit_to_dxdy[$state] = $dx;
        $digit_to_dxdy[$state+1] = $dy;
      }

      my $next_state = make_state
        (rot   => $new_rot,
         rev   => $new_rev,
         digit => 0);
      $next_state[$state] = $next_state;
    }
  }
}


### @next_state
### next_state length: 4*(4*2*2 + 4*2)

print "# next_state length ", scalar(@next_state), "\n";
print_table ("next_state", \@next_state);
print_table ("digit_to_x", \@digit_to_x);
print_table ("digit_to_y", \@digit_to_y);
print_table ("digit_to_dxdy", \@digit_to_dxdy);
print "\n";

# {
#  DIGIT: foreach my $digit (0 .. 3) {
#     foreach my $rot (0 .. 3) {
#       foreach my $rev (0 .. 1) {
#         if ($digit_to_x[make_state(rot => $rot,
#                                    rev => $rev,
#                                    digit => $digit)]
#             != $digit_to_dxdy[make_state(rot => $rot,
#                                          rev => $rev,
#                                          digit => 0)]) {
#           print "digit=$digit dx different at rot=$rot rev=$rev\n";
#           next DIGIT;
#         }
#       }
#     }
#     print "digit=$digit digit_to_x[] is dx\n";
#   }
# }

{
  my @pending_state = (0, 4, 8, 12);  # in 4 arm directions
  my $count = 0;
  my @seen_state;
  my $depth = 1;
  foreach my $state (@pending_state) {
    $seen_state[$state] = $depth;
  }
  while (@pending_state) {
    my @new_pending_state;
    foreach my $state (@pending_state) {
      $count++;
      ### consider state: $state

      foreach my $digit (0 .. 1) {
        my $next_state = $next_state[$state+$digit];
        if (! $seen_state[$next_state]) {
          $seen_state[$next_state] = $depth;
          push @new_pending_state, $next_state;
          ### push: "$next_state  depth $depth"
        }
      }
      $depth++;
    }
    @pending_state = @new_pending_state;
  }
  for (my $state = 0; $state < @next_state; $state += 2) {
    $seen_state[$state] ||= '-';
    my $state_string = state_string($state);
    print "# used state $state   depth $seen_state[$state]  $state_string\n";
  }
  print "used state count $count\n";
}


use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

foreach my $int (0 .. 16) {
  ### $int

  my @digits = digit_split_lowtohigh($int,4);
  my $len = 2 ** $#digits;
  my $state = (scalar(@digits) & 3) << 2;
  ### @digits
  ### $len
  ### initial state: $state.' '.state_string($state)

  my $x = 0;
  my $y = 0;
  foreach my $i (reverse 0 .. $#digits) {
    ### at: "i=$i len=$len digit=$digits[$i] state=$state ".state_string($state)
    $state += $digits[$i];
    ### digit x: $digit_to_x[$state]
    ### digit y: $digit_to_y[$state]
    $x += $len * $digit_to_x[$state];
    $y += $len * $digit_to_y[$state];
    $state = $next_state[$state];
    $len /= 2;
  }

  ### $x
  ### $y
  print "$int  $x $y\n";
}

exit 0;

__END__
