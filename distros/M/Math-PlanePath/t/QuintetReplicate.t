#!/usr/bin/perl -w

# Copyright 2017, 2018 Kevin Ryde

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
plan tests => 35;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::QuintetReplicate;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 127;
  ok ($Math::PlanePath::QuintetReplicate::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::QuintetReplicate->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::QuintetReplicate->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::QuintetReplicate->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::QuintetReplicate->new;
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
  my $path = Math::PlanePath::QuintetReplicate->new;
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
    $digit = ((($digit-1) + $add) % 4) + 1;
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
                    [ [4], [4] ],
                    [ [0,1], [0,1] ],
                    [ [4,1], [4,1] ],
                    [ [1,2], [2,2] ],
                    [ [3,3], [1,3] ],
                    [ [1,1,2], [2,2,2] ],
                    [ [1,1,3], [3,3,3] ],
                    [ [2,1,3], [4,3,3] ],
                   ) {
    my ($digits, $rotated) = @$elem;
    {
      my @got = @$digits;
      Math::PlanePath::QuintetReplicate::_digits_rotate_lowtohigh(\@got);
      ok(join(',',@got),join(',',@$rotated),
         "_digits_rotate_lowtohigh of ".join(',',@$digits));
    }
    {
      my @got = @$rotated;
      Math::PlanePath::QuintetReplicate::_digits_unrotate_lowtohigh(\@got);
      ok(join(',',@got),join(',',@$digits),
         "_digits_unrotate_lowtohigh of ".join(',',@$rotated));
    }
  }
}

{
  # rotate / unrotate reversible
  my $bad = 0;
  foreach my $n (0 .. 125) {
    my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,5);
    my $digits = join(',',reverse @digits);

    my @rot = @digits;
    Math::PlanePath::QuintetReplicate::_digits_rotate_lowtohigh(\@rot);
    my $rot    = join(',',reverse @rot);

    my @rot_by_successive = @digits;
    digits_rotate_lowtohigh_by_successive(\@rot_by_successive);
    my $rot_by_successive = join(',',reverse @rot_by_successive);
    unless ($rot eq $rot_by_successive) {
      MyTestHelpers::diag("n=$n digits=$digits rot=$rot rot_by_successive=$rot_by_successive");
      if (++$bad >= 5) { last; }
    }

    my @unrot_again = @rot;
    Math::PlanePath::QuintetReplicate::_digits_unrotate_lowtohigh(\@unrot_again);
    my $unrot_again = join(',',reverse @unrot_again);

    if ($digits ne $unrot_again) {
      MyTestHelpers::diag("n=$n digits=$digits rot=$rot unrot_again=$unrot_again");
      if (++$bad >= 1) { last; }
    }
  }
  ok ($bad, 0);
}


#------------------------------------------------------------------------------
# Boundary Squares when Rotate

sub to_base5 {
  my ($n,$k) = @_;
  my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,5);
  if (defined $k) {
    while (@digits < $k) { unshift @digits, 0; }
  }
  return join('',@digits);
}

my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);

foreach my $numbering_type ('fixed','rotate') {
  my $path = Math::PlanePath::QuintetReplicate->new
    (numbering_type => $numbering_type);
  my $bad = 0;
 LEVEL: foreach my $level (3,
                          # 0 .. 5
                          ) {
    my ($n_lo, $n_hi) = $path->level_to_n_range($level);
    my $Bpred_by_path = sub {
      my ($n) = @_;
      my ($x,$y) = $path->n_to_xy($n);
      foreach my $dir4 (0 .. 3) {
        my $n2 = $path->xy_to_n ($x+$dir4_to_dx[$dir4],
                                 $y+$dir4_to_dy[$dir4]);
        if ($n2 > $n_hi) { return 1; }
      }
      return 0;
    };
    foreach my $n ($n_lo .. $n_hi) {
      my $by_path   = $Bpred_by_path->($n) ? 1 : 0;
      my $by_undoc  = $path->_UNDOCUMENTED__n_is_boundary_level($n,$level)
        ? 1 : 0;

      if ($by_path != $by_undoc) {
        my ($x,$y) = $path->n_to_xy($n);
        my $n5 = to_base5($n,$level);
        MyTestHelpers::diag("$numbering_type level=$level n=$n [$n5] $x,$y path $by_path undoc $by_undoc   ($n_lo to $n_hi)");
        if (++$bad >= 1) { last LEVEL; }
      }
    }
  }
  ok ($bad, 0);
}
exit;


      # if ($by_path != $by_digits || $by_path != $by_undoc) {
      #   my ($x,$y) = $path->n_to_xy($n);
      #   my $n5 = to_base5($n,$level);
      #   MyTestHelpers::diag("level=$level n=$n [$n5] $x,$y path $by_path digits $by_digits undoc $by_undoc   ($n_lo to $n_hi)");
      #   if (++$bad >= 10) { last K; }
      # }
      # my $by_digits = $Bpred_by_digits->($n) ? 1 : 0;
    # my $Bpred_by_digits = sub {
    #   my ($n) = @_;
    #   my @digits = reverse    # high to low
    #     Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,5);
    #   while (@digits < $level) { unshift @digits, 0; }
    #   foreach my $digit (@digits) {
    #     if ($digit == 0) { return 0; }
    #   }
    #   shift @digits;  # skip high
    #   @digits = grep {$_!=1} @digits;  # ignore 1s
    #   foreach my $i (0 .. $#digits-1) {
    #     if (($digits[$i] == 3 && $digits[$i+1] == 2)
    #         || ($digits[$i] == 3 && $digits[$i+1] == 3)
    #         || ($digits[$i] == 4 && $digits[$i+1] == 4)) {
    #       return 0;
    #     }
    #   }
    #   return 1;
    # };

#------------------------------------------------------------------------------
# digit rotation per the POD

foreach my $numbering_type ('fixed','rotate') {
  my $path = Math::PlanePath::QuintetReplicate->new
    (numbering_type => $numbering_type);
  my $bad = 0;
  my $k = 3;
  my $pow = 5**$k;
  foreach my $turn (0 .. 3) {
    foreach my $n (0 .. $pow-1) {
      my ($x,$y) = $path->n_to_xy($n);
      my ($tx,$ty) = ($x,$y);
      foreach (1 .. $turn) { ($tx,$ty) = xy_rotate_plus90($tx,$ty); }
      my $txy = "$tx,$ty";
      my $an = digits_add($n,$turn, $numbering_type);
      my ($ax,$ay) = $path->n_to_xy($an);
      my $axy = "$ax,$ay";
      if ($txy ne $axy) {
        my $n5 = join('',reverse Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,5));
        my $an5 = join('',reverse Math::PlanePath::Base::Digits::digit_split_lowtohigh($an,5));
        print "$numbering_type turn=$turn oops, n=$n [$n5] $x,$y turned $txy cf an=$an [$an5] $axy\n";
        $bad++;
      }
    }
  }
  ok ($bad, 0);
}

sub xy_rotate_plus90 {
  my ($x,$y) = @_;
  return (-$y,$x);  # rotate +90
}

sub digits_add {
  my ($n,$offset, $numbering_type) = @_;
  my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,5);
  foreach my $digit (reverse @digits) {
    if ($digit) {
      $digit = (($digit-1 + $offset)%4) + 1;  # mutate @digits
    }
    if ($numbering_type eq 'rotate') { last; }
  }
  return Math::PlanePath::Base::Digits::digit_join_lowtohigh (\@digits, 5);
}

#------------------------------------------------------------------------------
# numbering_type => 'rotate' sub-parts rotation

{
  my $path = Math::PlanePath::QuintetReplicate->new (numbering_type=>'rotate');
  my $bad = 0;
  my $k = 3;
  my $pow = 5**$k;
  foreach my $n ($pow .. 2*$pow-1) {
    my ($x,$y) = $path->n_to_xy($n);
    {
      my ($rx,$ry) = $path->n_to_xy($n+$pow);
      ($rx,$ry) = xy_rotate_minus90($rx,$ry);
      my $got = "$rx,$ry";
      my $want = "$x,$y";
      if ($got ne $want) {
        print "oops, got $got want $want\n";
        $bad++;
      }
    }
    {
      my ($rx,$ry) = $path->n_to_xy($n+2*$pow);
      ($rx,$ry) = (-$rx,-$ry);    # rotate 180
      $bad += ("$rx,$ry" ne "$x,$y");
    }
  }
  ok ($bad, 0);
}

sub xy_rotate_minus90 {
  my ($x,$y) = @_;
  return ($y,-$x);  # rotate -90
}

#------------------------------------------------------------------------------
exit 0;
