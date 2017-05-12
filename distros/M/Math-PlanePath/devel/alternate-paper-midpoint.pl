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


# Usage: perl alternate-paper-midpoint.pl
#
# Print state tables used by Math::PlanePath::AlternatePaperMidpoint.
#

use 5.010;
use strict;

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
my @state_to_dxdy;

sub make_state {
  my %param = @_;
  my $state = 0;
  $state <<= 1; $state |= delete $param{'nextturn'};   # high
  $state <<= 2; $state |= delete $param{'rot'};
  $state <<= 1; $state |= delete $param{'prevbit'};
  $state <<= 2; $state |= delete $param{'digit'};      # low
  if (%param) { die; }
  return $state;
}
sub state_string {
  my ($state) = @_;
  my $digit    = $state & 3;  $state >>= 2;
  my $prevbit  = $state & 1;  $state >>= 1;
  my $rot      = $state & 3;  $state >>= 2;
  my $nextturn = $state & 1;  $state >>= 1;
  return "rot=$rot  prevbit=$prevbit (digit=$digit)";
}

foreach my $nextturn (0, 1) {
  foreach my $rot (0, 1, 2, 3) {
    foreach my $prevbit (0, 1) {
      my $state = make_state (nextturn => $nextturn,
                              rot      => $rot,
                              prevbit  => $prevbit,
                              digit    => 0);
      ### $state

      foreach my $digit (0 .. 3) {
        my $new_nextturn = $nextturn;
        my $new_prevbit = $digit;
        my $new_rot = $rot;

        if ($digit != $prevbit) {   # count 0<->1 transitions
          $new_rot++;
          $new_rot &= 3;
        }

        # nextturn from bit above lowest 0
        if ($digit == 0) {
          $new_nextturn = $prevbit ^ 1;
        } elsif ($digit == 1) {
          $new_nextturn = $prevbit;
        } elsif ($digit == 2) {
          $new_nextturn = 0;  # 1-bit at odd position
        }

        my $dx = 1;
        my $dy = 0;
        if ($rot & 2) {
          $dx = -$dx;
          $dy = -$dy;
        }
        if ($rot & 1) {
          ($dx,$dy) = (-$dy,$dx); # rotate +90
        }
        ### rot to: "$dx, $dy"

        my $next_dx = $dx;
        my $next_dy = $dy;
        if ($nextturn) {
          ($next_dx,$next_dy) = ($next_dy,-$next_dx); # right, rotate -90
        } else {
          ($next_dx,$next_dy) = (-$next_dy,$next_dx); # left, rotate +90
        }
        my $frac_dx = $next_dx - $dx;
        my $frac_dy = $next_dy - $dy;

        my $masked_state = $state & 0x1C;
        $state_to_dxdy[$masked_state]     = $dx;
        $state_to_dxdy[$masked_state + 1] = $dy;
        $state_to_dxdy[$masked_state + 2] = $frac_dx;
        $state_to_dxdy[$masked_state + 3] = $frac_dy;

        my $next_state = make_state
          (nextturn => $new_nextturn,
           rot      => $new_rot,
           prevbit  => $new_prevbit,
           digit    => 0);
        $next_state[$state+$digit] = $next_state;
      }
    }
  }
}


### @next_state
### @state_to_dxdy
### next_state length: 4*(4*2*2 + 4*2)

print "# next_state length ", scalar(@next_state), "\n";
print_table ("next_state", \@next_state);
print_table ("state_to_dxdy", \@state_to_dxdy);
print "\n";

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

      foreach my $digit (0 .. 3) {
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

exit 0;








# # lowdigit
# # my @state_to_dx = (1,1,0,0,
# #                    -1,-1,0,1,
# #                    -1,0,0,0,
# #                    1,0,0,1,
# #                   );
# # my @state_to_dy = (0,0,1,1,
# #                    0,0,-1,0,
# #                    0,1,1,1,
# #                    0,-1,-1,0,
# #                   );
# 
# my @state_to_dx = (1,1,0,0,
#                    -1,-1,0,1,
#                    -1,0,0,0,
#                    1,0,0,1,
#                   );
# my @state_to_dy = (0,0,1,1,
#                    0,0,-1,0,
#                    0,1,1,1,
#                    0,-1,-1,0,
#                   );
# 
# #use Smart::Comments;
# 
# sub n_to_dxdy {
#   my ($self, $n) = @_;
#   ### AlternatePaperMidpoint n_to_dxdy(): $n
# 
#   if ($n < 0) { return; }
#   if (is_infinite($n)) { return ($n, $n); }
# 
#   my $arm = _divrem_mutate ($n, $self->{'arms'});
#   ### $arm
#   ### $n
# 
#   my @digits = digit_split_lowtohigh($n,4);
#   while (@digits >= 2 && $digits[0] == 3) {  # strip low 3s
#     shift @digits;
#   }
#   my $state = 0;
#   my $lowdigit = (shift @digits || 0);
#   foreach my $digit (reverse @digits) { # high to low
#     $state = $next_state[$state+$digit];
#   }
#   ### $state
#   # ### $lowdigit
#   $state += $lowdigit;
#   my $dx = $state_to_dx[$state];
#   my $dy = $state_to_dy[$state];
# 
#   if ($arm & 1) {
#     ($dx,$dy) = ($dy,$dx);  # transpose
#   }
#   if ($arm & 2) {
#     ($dx,$dy) = (-$dy,$dx);   # rotate +90
#   }
#   if ($arm & 4) {
#     $dx = - $dx;           # rotate 180
#     $dy = - $dy;
#   }
# 
#   # ### rotated return: "$dx,$dy"
#   return ($dx,$dy);
# }
# 
# 
# no Smart::Comments;

