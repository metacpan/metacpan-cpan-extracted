#!/usr/bin/perl -w

# Copyright 2011, 2012, 2016 Kevin Ryde

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


# Usage: perl flowsnake-table.pl
#
# Print the state tables used for Math:PlanePath::Flowsnake n_to_xy().

use 5.010;
use strict;
use List::Util 'max';

# uncomment this to run the ### lines
#use Smart::Comments;


sub print_table14 {
  my ($name, $aref) = @_;
  print "my \@$name = (";
  my $entry_width = max (map {length($_//'')} @$aref);

  foreach my $i (0 .. $#$aref) {
    my $entry_str = $aref->[$i]//'undef';
    if ($i == $#$aref) {
      $entry_str .= ");";
    } else {
      $entry_str .= ",";
    }
    if ($i % 14 == 0 && $#$aref > 14) {
      printf "%-*s", $entry_width+1, $entry_str;
    } else {
      printf "%*s", $entry_width+1, $entry_str;
    }
    if ($i % 14 == 13) {
      print "  # ",$i-13,",",$i-6,"\n";
      if ($i != $#$aref) {
        print "        ".(" " x length($name));
      }
    } elsif ($i % 7 == 6) {
      print " ";
    }
  }
}
sub print_table12 {
  my ($name, $aref) = @_;
  print "my \@$name = (";
  my $entry_width = max (map {length($_//'')} @$aref);

  foreach my $i (0 .. $#$aref) {
    my $entry_str = $aref->[$i]//'undef';
    if ($i == $#$aref) {
      $entry_str .= ");";
    } else {
      $entry_str .= ",";
    }
    if ($i % 12 == 0 && $#$aref > 12) {
      printf "%-*s", $entry_width+1, $entry_str;
    } else {
      printf "%*s", $entry_width+1, $entry_str;
    }
    if ($i % 12 == 11) {
      print "\n";
      if ($i != $#$aref) {
        print "        ".(" " x length($name));
      }
    } elsif ($i % 6 == 5) {
      print "  ";
    }
  }
}

my @next_state;
my @digit_to_i;
my @digit_to_j;
my @state_to_di;
my @state_to_dj;

sub make_state {
  my %param = @_;
  my $state = 0;
  $state *= 6;  $state += delete $param{'rot'};   # high
  $state *= 2;  $state += delete $param{'rev'};
  $state *= 7;  $state += delete $param{'digit'}; # low
  if (%param) { die; }
  return $state;
}
sub state_string {
  my ($state) = @_;
  my $digit = $state % 7; $state = int($state/7); # low
  my $rev   = $state % 2; $state = int($state/2);
  my $rot   = $state % 6; $state = int($state/6); # high
  return "rot=$rot  rev=$rev (digit=$digit)";
}

foreach my $rev (0, 1) {
  foreach my $rot (0 .. 5) {
    foreach my $digit (0 .. 6) {
      my $state = make_state (rot   => $rot,
                              rev   => $rev,
                              digit => $digit);

      my $new_rev = $rev;
      my $new_rot = $rot;
      my ($i, $j);

      if ($rev == 0) {
        #       4-->5-->6
        #       ^       ^
        #        \       \
        #         3-->2   7
        #            /
        #           v
        #       0-->1        

        if ($digit == 0) {
          $i = 0;
          $j = 0;
          $new_rev = 0;
        } elsif ($digit == 1) {
          $i = 1;
          $j = 0;
          $new_rev = 1;
          $new_rot++;
        } elsif ($digit == 2) {
          $i = 1;
          $j = 1;
          $new_rev = 1;
          $new_rot += 3;
        } elsif ($digit == 3) {
          $i = 0;
          $j = 1;
          $new_rev = 0;
          $new_rot += 2;
        } elsif ($digit == 4) {
          $i = -1;
          $j = 2;
          $new_rev = 0;
        } elsif ($digit == 5) {
          $i = 0;
          $j = 2;
          $new_rev = 0;
        } elsif ($digit == 6) {
          $i = 1;
          $j = 2;
          $new_rev = 1;
          $new_rot += 5;
        }
      } else {
        #             6<---7
        #             ^
        #            /
        #       0   5<--4
        #        \       \
        #         v       v
        #         1<--2<--3  

        if ($digit == 0) {
          $i = 0;
          $j = 0;
          $new_rev = 0;
          $new_rot -= 1;
        } elsif ($digit == 1) {
          $i = 1;
          $j = -1;
          $new_rev = 1;
        } elsif ($digit == 2) {
          $i = 2;
          $j = -1;
          $new_rev = 1;
        } elsif ($digit == 3) {
          $i = 3;
          $j = -1;
          $new_rev = 1;
          $new_rot += 2;
        } elsif ($digit == 4) {
          $i = 2;
          $j = 0;
          $new_rev = 0;
          $new_rot += 3;
        } elsif ($digit == 5) {
          $i = 1;
          $j = 0;
          $new_rev = 0;
          $new_rot += 1;
        } elsif ($digit == 6) {
          $i = 1;
          $j = 1;
          $new_rev = 1;
        }
      }

      foreach (1 .. $rot) {
        ($i,$j) = (-$j, $i+$j);  # rotate +60
      }
      $new_rot %= 6;

      my $next_state = make_state
        (rot   => $new_rot,
         rev   => $new_rev,
         digit => 0);
      $next_state[$state] = $next_state;
      $digit_to_i[$state] = $i;
      $digit_to_j[$state] = $j;
    }

    my $state = make_state (rot   => $rot,
                            rev   => $rev,
                            digit => 0);
    my $di = 1;
    my $dj = 0;
    foreach (1 .. $rot) {
      ($di,$dj) = (-$dj, $di+$dj);  # rotate +60
    }
    $state_to_di[$state/7] = $di;
    $state_to_dj[$state/7] = $dj;
  }
}

my @digit_to_next_di;
my @digit_to_next_dj;
my $end_i = 2;
my $end_j = 1;
my $state = 0;
foreach my $rot (0 .. 5) {
  foreach my $rev (0, 1) {
    foreach my $digit (0 .. 5) {
      my $di;
      if ($digit < 5) {
        $di = $digit_to_i[$state + $digit + 2]
      } else {
        $di = $end_i;
      }
      $di -= $digit_to_i[$state + $digit + 1];
      $digit_to_next_di[$state + $digit] = $di;

      my $dj;
      if ($digit < 5) {
        $dj = $digit_to_j[$state + $digit + 2];
      } else {
        $dj = $end_j;
      }
      $dj -= $digit_to_j[$state + $digit + 1];
      $digit_to_next_dj[$state + $digit] = $dj;

      if ($di == 0 && $dj == 0) {
        die "no delta at state=$state digit=$digit";
      }

      if ($rev) {
        if ($digit == 0) {
           ($di,$dj) = ($di+$dj, -$di); # rotate -60
        } elsif ($digit == 1) {
          ($di,$dj) = ($di+$dj, -$di); # rotate -60
        } elsif ($digit == 2) {
          ($di,$dj) = ($di+$dj, -$di); # rotate -60
        } elsif ($digit == 5) {
          ($di,$dj) = ($di+$dj, -$di); # rotate -60
        }
      } else {
        if ($digit == 0) {
          ($di,$dj) = ($di+$dj, -$di); # rotate -60
        } elsif ($digit == 1) {
          ($di,$dj) = ($di+$dj, -$di); # rotate -60
        } elsif ($digit == 5) {
          ($di,$dj) = ($di+$dj, -$di); # rotate -60
        }
      }
      $digit_to_next_di[$state + $digit + 84] = $di;
      $digit_to_next_dj[$state + $digit + 84] = $dj;
    }
    $state += 7;
  }
  ($end_i,$end_j) = (-$end_j, $end_i+$end_j); # rotate +60
}

### @next_state
### @digit_to_dxdy
### next_state length: 4*(4*2*2 + 4*2)

print "# next_state length ", scalar(@next_state), "\n";
print_table14 ("next_state", \@next_state);
print_table14 ("digit_to_i", \@digit_to_i);
print_table14 ("digit_to_j", \@digit_to_j);
print_table12 ("state_to_di", \@state_to_di);
print_table12 ("state_to_dj", \@state_to_dj);

print "\n";
print_table14 ("digit_to_next_di", \@digit_to_next_di);
print "\n";
print_table14 ("digit_to_next_dj", \@digit_to_next_dj);

print "\n";

exit 0;
