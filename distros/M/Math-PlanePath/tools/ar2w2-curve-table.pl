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

my $table_total = 0;
sub print_table {
  my ($name, $aref) = @_;
  $table_total += scalar(@$aref);

  print "my \@$name\n  = (";
  my $entry_width = max (map {defined $_ ? length : 0} @$aref);

  foreach my $i (0 .. $#$aref) {
    printf "%*s", $entry_width, $aref->[$i]//'undef';
    if ($i == $#$aref) {
      print ");\n";
    } else {
      print ",";
      if (($i % 16) == 15) {
        print "\n     ";
      } elsif (($i % 4) == 3) {
        print " ";
      }
    }
  }
}

sub print_table12 {
  my ($name, $aref) = @_;
  $table_total += scalar(@$aref);

  print "my \@$name = (";
  my $entry_width = max (map {length($_//'')} @$aref);

  foreach my $i (0 .. $#$aref) {
    printf "%*s", $entry_width, $aref->[$i]//'undef';
    if ($i == $#$aref) {
      print ");\n";
    } else {
      print ",";
      if (($i % 12) == 11) {
        my $state = ($i-11)/3;
        print "   # 3* $state";
        print "\n        ".(" " x length($name));
      } elsif (($i % 3) == 2) {
        print " ";
      }
    }
  }
}

sub make_state {
  my ($part, $rot, $rev) = @_;
  $rot %= 4;
  return 4*($rot + 4*($rev + 2*$part));
}

my @part_name = ('A1','A2',
                 'B1','B2',
                 'C1','C2',
                 'D1','D2');
my @rev_name = ('','rev');
sub state_string {
  my ($state) = @_;
  my $digit = $state % 4; $state = int($state/4);
  my $rot   = $state % 4; $state = int($state/4);
  my $rev = $state % 2; $state = int($state/2);
  my $part  = $state;
  return "part=$part_name[$part]$rev_name[$rev] rot=$rot digit=$digit";
}

my @next_state;
my @digit_to_x;
my @digit_to_y;
my @yx_to_digit;
my @min_digit;
my @max_digit;

use constant A1 => 0;
use constant A2 => 1;
use constant B1 => 2;
use constant B2 => 3;
use constant C1 => 4;
use constant C2 => 5;
use constant D1 => 6;
use constant D2 => 7;

foreach my $part (A1, A2, B1, B2, C1, C2, D1, D2) {
  foreach my $rot (0, 1, 2, 3) {
    foreach my $rev (0, 1) {
      my $state = make_state ($part, $rot, $rev);

      foreach my $orig_digit (0, 1, 2, 3) {
        my $digit = $orig_digit;
        if ($rev) {
          $digit = 3-$digit;
        }

        my $xo = 0;
        my $yo = 0;
        my $new_part = $part;
        my $new_rot = $rot;
        my $new_rev = $rev;

        if ($part == A1) {
          if ($digit == 0) {
            $new_part = D2;
          } elsif ($digit == 1) {
            $xo = 1;
            $new_part = B1;
            $new_rev ^= 1;
            $new_rot = $rot - 1;
          } elsif ($digit == 2) {
            $yo = 1;
            $new_part = C1;
            $new_rot = $rot + 1;
          } elsif ($digit == 3) {
            $xo = 1;
            $yo = 1;
            $new_part = B2;
            $new_rev ^= 1;
            $new_rot = $rot + 2;
          }

        } elsif ($part == A2) {
          if ($digit == 0) {
            $new_part = B1;
            $new_rev ^= 1;
            $new_rot = $rot - 1;
          } elsif ($digit == 1) {
            $yo = 1;
            $new_part = C2;
          } elsif ($digit == 2) {
            $xo = 1;
            $new_part = B2;
            $new_rev ^= 1;
            $new_rot = $rot + 2;
          } elsif ($digit == 3) {
            $xo = 1;
            $yo = 1;
            $new_part = D1;
            $new_rot = $rot + 1;
          }

        } elsif ($part == B1) {
          if ($digit == 0) {
            $new_part = D1;
            $new_rev ^= 1;
            $new_rot = $rot - 1;
          } elsif ($digit == 1) {
            $yo = 1;
            $new_part = C2;
          } elsif ($digit == 2) {
            $xo = 1;
            $yo = 1;
            $new_part = B1;
          } elsif ($digit == 3) {
            $xo = 1;
            $new_part = B2;
            $new_rev ^= 1;
            $new_rot = $rot + 1;
          }

        } elsif ($part == B2) {
          if ($digit == 0) {
            $new_part = B1;
            $new_rev ^= 1;
            $new_rot = $rot - 1;
          } elsif ($digit == 1) {
            $yo = 1;
            $new_part = B2;
          } elsif ($digit == 2) {
            $xo = 1;
            $yo = 1;
            $new_part = C1;
          } elsif ($digit == 3) {
            $xo = 1;
            $new_part = D2;
            $new_rev ^= 1;
            $new_rot = $rot + 1;
          }

        } elsif ($part == C1) {
          if ($digit == 0) {
            $new_part = A2;
          } elsif ($digit == 1) {
            $yo = 1;
            $new_part = B1;
            $new_rot = $rot + 1;
          } elsif ($digit == 2) {
            $xo = 1;
            $yo = 1;
            $new_part = A1;
            $new_rot = $rot - 1;
          } elsif ($digit == 3) {
            $xo = 1;
            $new_part = B2;
            $new_rev ^= 1;
            $new_rot = $rot + 1;
          }

        } elsif ($part == C2) {
          if ($digit == 0) {
            $new_part = B1;
            $new_rev ^= 1;
            $new_rot = $rot - 1;
          } elsif ($digit == 1) {
            $yo = 1;
            $new_part = A2;
          } elsif ($digit == 2) {
            $xo = 1;
            $yo = 1;
            $new_part = B2;
            $new_rot = $rot - 1;
          } elsif ($digit == 3) {
            $xo = 1;
            $new_part = A1;
            $new_rot = $rot - 1;
          }

        } elsif ($part == D1) {
          if ($digit == 0) {
            $new_part = D1;
            $new_rev ^= 1;
            $new_rot = $rot - 1;
          } elsif ($digit == 1) {
            $yo = 1;
            $new_part = A2;
          } elsif ($digit == 2) {
            $xo = 1;
            $yo = 1;
            $new_part = C2;
            $new_rot = $rot - 1;
          } elsif ($digit == 3) {
            $xo = 1;
            $new_part = A2;
            $new_rot = $rot - 1;
          }

        } elsif ($part == D2) {
          if ($digit == 0) {
            $new_part = A1;
          } elsif ($digit == 1) {
            $yo = 1;
            $new_part = C1;
            $new_rot = $rot + 1;
          } elsif ($digit == 2) {
            $xo = 1;
            $yo = 1;
            $new_part = A1;
            $new_rot = $rot - 1;
          } elsif ($digit == 3) {
            $xo = 1;
            $new_part = D2;
            $new_rev ^= 1;
            $new_rot = $rot + 1;
          }

        } else {
          die;
        }

        ### base: "$xo, $yo"

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
        $yx_to_digit[$state + $yo*2 + $xo] = $orig_digit;

        my $next_state = make_state
          ($new_part, $new_rot, $new_rev);
        $next_state[$state+$orig_digit] = $next_state;
      }


      foreach my $x1pos (0 .. 1) {
        foreach my $x2pos ($x1pos .. 1) {
          my $xr = ($x1pos ? 2 : $x2pos ? 1 : 0);
          ### $xr

          foreach my $y1pos (0 .. 1) {
            foreach my $y2pos ($y1pos .. 1) {
              my $yr = ($y1pos ? 6 : $y2pos ? 3 : 0);
              ### $yr

              my $min_digit = undef;
              my $max_digit = undef;
              foreach my $digit (0 .. 3) {
                my $x = $digit_to_x[$state+$digit];
                my $y = $digit_to_y[$state+$digit];
                next unless $x >= $x1pos;
                next unless $x <= $x2pos;
                next unless $y >= $y1pos;
                next unless $y <= $y2pos;
                $min_digit = min_maybe($digit,$min_digit);
                $max_digit = max_maybe($digit,$max_digit);
              }

              my $key = 3*$state + $xr + $yr;
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
}

sub check_used {
  my @pending_state = @_;
  my $count = 0;
  my @seen_state;
  my $depth = 1;
  while (@pending_state) {
    my $state = pop @pending_state;
    $count++;
    ### consider state: $state

    foreach my $digit (0 .. 3) {
      my $next_state = $next_state[$state+$digit];
      if (! $seen_state[$next_state]) {
        $seen_state[$next_state] = $depth;
        push @pending_state, $next_state;
        ### push: "$next_state  depth $depth"
      }
    }
    $depth++;
  }
  for (my $state = 0; $state < @next_state; $state += 4) {
    if (! defined $seen_state[$state]) { $seen_state[$state] = 'none'; }
    my $str = state_string($state);
    print "# used state $state   depth $seen_state[$state]    $str\n";
  }
  print "used state count $count\n";
}

print_table ("next_state", \@next_state);
print_table ("digit_to_x", \@digit_to_x);
print_table ("digit_to_y", \@digit_to_y);
print_table ("yx_to_digit", \@yx_to_digit);
print_table12 ("min_digit", \@min_digit);
print_table12 ("max_digit", \@max_digit);
print "# state length ",scalar(@next_state)," in each of 4 tables\n";
print "# grand total $table_total\n";
print "\n";


{
  my %seen;
  my @pending;
  for (my $state = 0; $state < @next_state; $state += 4) {
    push @pending, $state;
  }
  while (@pending) {
    my $state = shift @pending;
    next if $seen{$state}++;
    next if $digit_to_x[$state] != 0 || $digit_to_y[$state] != 0;

    my $next = $next_state[$state];
    if ($next_state[$next] == $state) {
      print "# cycle $state/$next  ",state_string($state)," <-> ",state_string($next),"\n";
      unshift @pending, $next;
    }
  }
  print "#\n";
}

{
  my $a1 = make_state(A1,0,0);
  my $d2 = make_state(D2,0,0);

  my $d1rev = make_state(D1,3,1);
  my $a2rev = make_state(A2,2,1);

  my $b2 = make_state(B2,0,0);
  my $b1rev3 = make_state(B1,-1,1);

  my $b1rev = make_state(B1,0,1);
  my $b2_1 = make_state(B2,1,0);

  my $str = <<"HERE";
my %start_state = (A1    => [$a1, $d2],
                   D2    => [$d2, $a1],

                   B2    => [$b2, $b1rev3],
                   B1rev => [$b1rev3, $b2],

                   D1rev => [$d1rev, $a2rev],
                   A2rev => [$a2rev, $d1rev],
                  );
HERE
  print $str;
  
  my %start_state = eval "$str; %start_state";
  foreach my $elem (values %start_state) {
    my ($s1, $s2) = @$elem;
    $next_state[$s1]==$s2 or die;
    $next_state[$s2]==$s1 or die;
    $digit_to_x[$s1]==0 or die "$s1 not at 0,0";
    $digit_to_y[$s1]==0 or die;
    $digit_to_x[$s2]==0 or die;
    $digit_to_y[$s2]==0 or die;
  }
}

# print "# state A1=",make_state(A1,0,0),"\n";
# print "# state D2=",make_state(D2,0,0),"\n";
# print "# state D1=",make_state(D1,0,0),"\n";

# print "from A1/D2\n";
# check_used (make_state(A1,0,0), make_state(D2,0,0));
# print "from D1\n";
# check_used (make_state(D1,0,0));

{
  print "\n";
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
