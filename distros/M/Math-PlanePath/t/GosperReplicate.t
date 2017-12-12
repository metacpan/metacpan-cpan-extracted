#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde

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
use Test;
plan tests => 59;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
# use Smart::Comments;

require Math::PlanePath::GosperReplicate;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::GosperReplicate::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::GosperReplicate->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::GosperReplicate->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::GosperReplicate->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::GosperReplicate->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::GosperReplicate->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}


#------------------------------------------------------------------------------
# _digits_rotate_lowtohigh()
# _digits_unrotate_lowtohigh()

sub add_to_digit {
  my ($digit, $add) = @_;
  if ($digit) {
    $digit = ((($digit-1) + $add) % 6) + 1;
  }
  return $digit;
}
sub digits_rotate_lowtohigh_by_successive {
  my ($aref) = @_;
  my @new = @$aref;
  foreach my $i (0 .. $#$aref) {
    if ($aref->[$i]) {
      foreach my $j (0 .. $i-1) {   # below $i
        $new[$j] = add_to_digit($new[$j], $aref->[$i] - 1);
      }
    }
  }
  @$aref = @new;
}

{
  foreach my $elem (
                    [ [], [] ],
                    [ [0], [0] ],
                    [ [1], [1] ],
                    [ [6], [6] ],
                    [ [0,1], [0,1] ],
                    [ [6,1], [6,1] ],
                    [ [1,2], [2,2] ],
                    [ [3,3], [5,3] ],
                    [ [6,3], [2,3] ],
                    [ [1,1,2], [2,2,2] ],
                    [ [1,1,3], [3,3,3] ],
                    [ [1,1,4], [4,4,4] ],
                    [ [2,1,4], [5,4,4] ],
                    [ [1,2,4], [5,5,4] ],
                   ) {
    my ($digits, $rotated) = @$elem;
    {
      my @got = @$digits;
      Math::PlanePath::GosperReplicate::_digits_rotate_lowtohigh(\@got);
      ok(join(',',@got),join(',',@$rotated),
         "_digits_rotate_lowtohigh of ".join(',',@$digits));
    }
    {
      my @got = @$rotated;
      Math::PlanePath::GosperReplicate::_digits_unrotate_lowtohigh(\@got);
      ok(join(',',@got),join(',',@$digits),
         "_digits_unrotate_lowtohigh of ".join(',',@$rotated));
    }
  }
}

{
  # rotate / unrotate reversible
  my $bad = 0;
  foreach my $n (0 .. 7**3) {
    my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,7);
    my $digits = join(',',reverse @digits);

    my @rot = @digits;
    Math::PlanePath::GosperReplicate::_digits_rotate_lowtohigh(\@rot);
    my $rot = join(',',reverse @rot);

    my @rot_by_successive = @digits;
    digits_rotate_lowtohigh_by_successive(\@rot_by_successive);
    my $rot_by_successive = join(',',reverse @rot_by_successive);
    unless ($rot eq $rot_by_successive) {
      MyTestHelpers::diag("n=$n digits=$digits rot=$rot rot_by_successive=$rot_by_successive");
      if (++$bad >= 5) { last; }
    }

    my @unrot_again = @rot;
    Math::PlanePath::GosperReplicate::_digits_unrotate_lowtohigh(\@unrot_again);

    my $unrot_again = join(',',reverse @unrot_again);

    unless ($digits eq $unrot_again) {
      MyTestHelpers::diag("n=$n digits=$digits rot=$rot unrot_again=$unrot_again");
      if (++$bad >= 1) { last; }
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# boundary squares when rotate

{
  my @dir6_to_dx = (2, 1,-1,-2, -1, 1);
  my @dir6_to_dy = (0, 1, 1, 0, -1,-1);

  sub to_base7 {
    my ($n,$k) = @_;
    my @digits = reverse Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,7);
    if (defined $k) {
      while (@digits < $k) { unshift @digits, 0; }
    }
    return join('',@digits);
  }

  my $path = Math::PlanePath::GosperReplicate->new
    (numbering_type => 'rotate');
  my $bad = 0;
 K: foreach my $k (0 .. 4) {
    my ($n_lo, $n_hi) = $path->level_to_n_range($k);
    ### $k
    ### $n_hi
    my $Bpred_by_path = sub {
      my ($n) = @_;
      my ($x,$y) = $path->n_to_xy($n);
      foreach my $dir6 (0 .. 5) {
        my $n2 = $path->xy_to_n ($x+$dir6_to_dx[$dir6],
                                 $y+$dir6_to_dy[$dir6]);
        ### $n2
        if ($n2 > $n_hi) { return 1; }
      }
      return 0;
    };
    my $Bpred_by_digits = sub {
      my ($n) = @_;
      my @digits = reverse    # high to low
        Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,7);
      while (@digits < $k) { unshift @digits, 0; }
      foreach my $digit (@digits) {
        if ($digit == 0) { return 0; }
      }
      shift @digits;  # skip high
      foreach my $digit (@digits) {
        if ($digit == 4 || $digit == 5) { return 0; }
      }
      @digits = grep {$_!=1} @digits;  # ignore 1s
      foreach my $i (0 .. $#digits-1) {
        if (($digits[$i] == 3 && $digits[$i+1] == 2)
            || ($digits[$i] == 3 && $digits[$i+1] == 3)
            || ($digits[$i] == 6 && $digits[$i+1] == 6)) {
          return 0;
        }
      }
      return 1;
    };
    foreach my $n ($n_lo .. $n_hi) {
      my $by_path   = $Bpred_by_path->($n);
      my $by_digits = $Bpred_by_digits->($n);
      if ($by_path != $by_digits) {
        my ($x,$y) = $path->n_to_xy($n);
        my $n7 = to_base7($n,$k);
        MyTestHelpers::diag("k=$k n=$n [$n7] $x,$y path $by_path digits $by_digits   ($n_lo to $n_hi)");
        if (++$bad >= 10) { last K; }
      }
    }
  }
  ok ($bad, 0);
}


#------------------------------------------------------------------------------
# digit rotation per the POD

foreach my $numbering_type ('fixed','rotate') {
  my $path = Math::PlanePath::GosperReplicate->new
    (numbering_type => $numbering_type);
  my $bad = 0;
  my $k = 3;
  my $pow = 7**$k;
  foreach my $turn (0,1,2,5,6) {
    foreach my $n (0 .. $pow-1) {
      my ($x,$y) = $path->n_to_xy($n);
      my ($tx,$ty) = ($x,$y);
      foreach (1 .. $turn) { ($tx,$ty) = xy_rotate_plus60($tx,$ty); }
      my $txy = "$tx,$ty";
      my $an = digits_add($n,$turn, $numbering_type);
      my ($ax,$ay) = $path->n_to_xy($an);
      my $axy = "$ax,$ay";
      if ($txy ne $axy) {
        my $n7 = join('',reverse Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,7));
        my $an7 = join('',reverse Math::PlanePath::Base::Digits::digit_split_lowtohigh($an,7));
        print "$numbering_type turn=$turn oops, n=$n [$n7] $x,$y turned $txy cf an=$an [$an7] $axy\n";
        $bad++;
      }
    }
  }
  ok ($bad, 0);
}

sub xy_rotate_plus60 {
  my ($x, $y) = @_;
  return (($x-3*$y)/2,  # rotate +60
          ($x+$y)/2);
}

sub digits_add {
  my ($n,$offset, $numbering_type) = @_;
  my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,7);
  foreach my $digit (reverse @digits) {
    if ($digit) {
      $digit = (($digit-1 + $offset)%6) + 1;  # mutate @digits
    }
    if ($numbering_type eq 'rotate') { last; }
  }
  return Math::PlanePath::Base::Digits::digit_join_lowtohigh (\@digits, 7);
}

#------------------------------------------------------------------------------
# numbering_type => 'rotate' sub-parts rotation

{
  my $path = Math::PlanePath::GosperReplicate->new (numbering_type=>'rotate');
  my $bad = 0;
  my $k = 3;
  my $pow = 7**$k;
  foreach my $n ($pow .. 2*$pow-1) {
    my ($x,$y) = $path->n_to_xy($n);
    {
      my ($rx,$ry) = $path->n_to_xy($n+$pow);
      ($rx,$ry) = xy_rotate_minus60($rx,$ry);
      my $got = "$rx,$ry";
      my $want = "$x,$y";
      if ($got ne $want) {
        print "oops, got $got want $want\n";
        $bad++;
      }
    }
    {
      my ($rx,$ry) = $path->n_to_xy($n+2*$pow);
      ($rx,$ry) = xy_rotate_minus120($rx,$ry);
      $bad += ("$rx,$ry" ne "$x,$y");
    }
  }
  ok ($bad, 0);
}

sub xy_rotate_minus60 {
  my ($x, $y) = @_;
  return (($x+3*$y)/2,  # rotate -60
          ($y-$x)/2);
}
sub xy_rotate_minus120 {
  my ($x, $y) = @_;
  return ((3*$y-$x)/2,              # rotate -120
          ($x+$y)/-2);
}

#------------------------------------------------------------------------------
# _digits_rotate_lowtohigh()
# _digits_unrotate_lowtohigh()

{
  foreach my $elem (
              [ [], [] ],
              [ [0], [0] ],
              [ [1], [1] ],
              [ [6], [6] ],
              [ [0,1], [0,1] ],
              [ [6,1], [6,1] ],
              [ [3,2], [4,2] ],
              [ [6,3], [2,3] ],
             ) {
    my ($digits, $rotated) = @$elem;
    {
      my @got = @$digits;
      Math::PlanePath::GosperReplicate::_digits_rotate_lowtohigh(\@got);
      ok(join(',',@got),join(',',@$rotated),
         "_digits_rotate_lowtohigh of ".join(',',@$digits));
    }
    {
      my @got = @$rotated;
      Math::PlanePath::GosperReplicate::_digits_unrotate_lowtohigh(\@got);
      ok(join(',',@got),join(',',@$digits),
         "_digits_unrotate_lowtohigh of ".join(',',@$rotated));
    }
  }
}


#------------------------------------------------------------------------------
# No, the replicate shape is each middle of the unit hexagons in GosperIslands.

# # Return true if $n is on the boundary of its expansion level (the level
# # which is the number of base-7 digits in $n).
# sub _rotate_Bpred {
#   my ($n) = @_;
#   my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,7)
#     or return 1;
#   my $prev = $digits[-1] || return 0;
#   foreach my $digit (reverse @digits[0 .. $#digits-1]) { # high to low
#     if ($digit == 1) {
#     } elsif ($digit == 0 || $digit == 4 || $digit == 5
#              || ($prev == 6 && $digit == 6)
#              || ($prev == 3 && ($digit == 2 || $digit == 3))) {
#       ### _rotate_Bpred(): "not prev=$prev digit=$digit"
#       return 0;
#     }
#     $prev = $digit;
#   }
#   return 1;
# }
# 
# {
#   require Math::PlanePath::GosperIslands;
#   my $islands = Math::PlanePath::GosperIslands->new;
# 
#   my $path = Math::PlanePath::GosperReplicate->new (numbering_type=>'rotate');
#   my $bad = 0;
#   foreach my $n (1 .. 7**2) {
#     my $rotate_Bpred =  _rotate_Bpred($n) ? 1 : 0;
#     my ($x,$y) = $path->n_to_xy($n);
#     my $island_pred  = $islands->xy_is_visited($x,$y) ? 1 : 0;
#     if ($rotate_Bpred ne $island_pred) {
#       print $islands->n_to_xy(7),"\n";
#       print $islands->xy_to_n(5,1),"\n";
#       print $islands->xy_is_visited(5,1),"\n";
#       my $n7 = join('',reverse Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,7));
#       print "oops, n=$n [$n7] at $x,$y rotate $rotate_Bpred islands $island_pred\n";
#       $bad++;
#     }
#   }
#   ok ($bad, 0);
# }


#------------------------------------------------------------------------------
  exit 0;
