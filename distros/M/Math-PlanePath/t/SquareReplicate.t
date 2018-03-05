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
plan tests => 73;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::SquareReplicate;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::SquareReplicate::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::SquareReplicate->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::SquareReplicate->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::SquareReplicate->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::SquareReplicate->new;
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
  my $path = Math::PlanePath::SquareReplicate->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}


#------------------------------------------------------------------------------
# _digits_rotate_lowtohigh()

sub add_to_digit {
  my ($digit, $add) = @_;
  if ($digit) {
    $digit = ((($digit-1) + $add) % 8) + 1;
  }
  return $digit;
}
sub digits_rotate_lowtohigh_by_successive {
  my ($aref, $numbering_type) = @_;
  my @new = @$aref;
  foreach my $i (0 .. $#$aref) {
    if ($aref->[$i]) {
      my $add = $aref->[$i] - 1;
      if ($numbering_type eq 'rotate-4') { $add -= ($add & 1); }
      foreach my $j (0 .. $i-1) {   # below $i
        $new[$j] = add_to_digit($new[$j], $add);
      }
    }
  }
  @$aref = @new;
}

{
  foreach my $elem (
                    [ 'rotate-8',  [], [] ],
                    [ 'rotate-8',  [0], [0] ],
                    [ 'rotate-8',  [8], [8] ],

                    [ 'rotate-8',  [0,1], [0,1] ],  # low to high
                    [ 'rotate-8',  [1,1], [1,1] ],
                    [ 'rotate-8',  [8,1], [8,1] ],
                    [ 'rotate-8',  [1,2], [2,2] ],
                    [ 'rotate-8',  [3,2], [4,2] ],
                    [ 'rotate-8',  [8,2], [1,2] ],
                    [ 'rotate-8',  [1,3], [3,3] ],
                    [ 'rotate-8',  [3,3], [5,3] ],
                    [ 'rotate-8',  [8,3], [2,3] ],

                    [ 'rotate-4',  [], [] ],
                    [ 'rotate-4',  [0], [0] ],
                    [ 'rotate-4',  [1], [1] ],

                    [ 'rotate-4',  [0,1], [0,1] ],
                    [ 'rotate-4',  [1,1], [1,1] ],
                    [ 'rotate-4',  [8,1], [8,1] ],
                    [ 'rotate-4',  [1,2], [1,2] ],
                    [ 'rotate-4',  [3,2], [3,2] ],
                    [ 'rotate-4',  [8,2], [8,2] ],
                    [ 'rotate-4',  [1,3], [3,3] ],
                    [ 'rotate-4',  [3,3], [5,3] ],
                    [ 'rotate-4',  [8,3], [2,3] ],
                    [ 'rotate-4',  [1,4], [3,4] ],
                    [ 'rotate-4',  [3,4], [5,4] ],
                    [ 'rotate-4',  [8,4], [2,4] ],
                    [ 'rotate-4',  [1,5], [5,5] ],
                    [ 'rotate-4',  [3,5], [7,5] ],
                    [ 'rotate-4',  [8,5], [4,5] ],
                   ) {
    my ($numbering_type, $digits, $rotated) = @$elem;
    my $self = Math::PlanePath::SquareReplicate->new
      (numbering_type => $numbering_type);
    {
      my @got = @$digits;
      Math::PlanePath::SquareReplicate::_digits_rotate_lowtohigh($self, \@got);
      ok(join(',',@got),join(',',@$rotated),
         "_digits_rotate_lowtohigh $numbering_type of ".join(',',@$digits));
    }
    ($digits,$rotated) = ($rotated,$digits);
    {
      my @got = @$digits;
      Math::PlanePath::SquareReplicate::_digits_unrotate_lowtohigh($self,\@got);
      ok(join(',',@got),join(',',@$rotated),
         "_digits_unrotate_lowtohigh $numbering_type of ".join(',',@$digits));
    }
  }
}

{
  # rotate reversible
  foreach my $numbering_type ('rotate-4','rotate-8') {
    my $self = Math::PlanePath::SquareReplicate->new
      (numbering_type => $numbering_type);
    my $bad = 0;
    foreach my $n (0 .. 9**4) {
      my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,9);
      my $digits = join(',',reverse @digits);

      my @rot = @digits;
      Math::PlanePath::SquareReplicate::_digits_rotate_lowtohigh($self,\@rot);
      my $rot    = join(',',reverse @rot);

      my @rot_by_successive = @digits;
      digits_rotate_lowtohigh_by_successive(\@rot_by_successive,
                                            $numbering_type);
      my $rot_by_successive = join(',',reverse @rot_by_successive);
      unless ($rot eq $rot_by_successive) {
        MyTestHelpers::diag("$numbering_type n=$n digits=$digits rot=$rot rot_by_successive=$rot_by_successive");
        if (++$bad >= 5) { last; }
      }

      my @unrot_again = @rot;
      Math::PlanePath::SquareReplicate::_digits_unrotate_lowtohigh($self,\@unrot_again);
      my $unrot_again = join(',',reverse @unrot_again);

      if ($digits ne $unrot_again) {
        MyTestHelpers::diag("n=$n digits=$digits rot=$rot unrot_again=$unrot_again");
        if (++$bad >= 1) { last; }
      }
    }
    ok($bad,0);
  }
}

#------------------------------------------------------------------------------
# Boundary

{
  # 40 39 38 31 30 29 22 21 20
  # 41 36 37 32 27 28 23 18 19
  # 42 43 44 33 34 35 24 25 26
  # 49 48 47  4  3  2 13 12 11
  # 50 45 46  5  0  1 14  9 10
  # 51 52 53  6  7  8 15 16 17
  # 58 57 56 67 66 65 76 75 74
  # 59 54 55 68 63 64 77 72 73
  # 60 61 62 69 70 71 78 79 80

  sub Bpred_by_path {
    my ($path, $n, $k) = @_;
    my ($x,$y) = $path->n_to_xy($n);
    my $m = (3**$k-1)/2;
    return (abs($x) == $m || abs($y) == $m);
  }
  #                                 0  1 2 3 4  5 6 7  8
  my @Bpred_rotate4_state_table = ([4, 1,2,1,2, 1,2,1, 2],  # 0=all
                                   [4, 1,1,4,4, 4,4,4, 3],  # 1=A
                                   [4, 1,2,1,1, 4,4,4, 3],  # 2=AB
                                   [4, 4,3,1,1, 4,4,4, 4],  # 3=B
                                   [4, 4,4,4,4, 4,4,4, 4]); # 4=non
  sub Bpred_rotate4_by_states {
    my ($path, $n, $k) = @_;
    my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,9);
    while (@digits < $k) { push @digits, 0; }
    my $state = 0;
    foreach my $digit (reverse @digits) {  # high to low
      $state = $Bpred_rotate4_state_table[$state]->[$digit];
    }
    return $state != 4;
  }

  # non-boundary per POD docs
  # ignore 2s in 2nd or later
  # 0      anywhere
  # 5,6,7  2nd or later
  # pair 13,33,53,73 or 14,34,54,74 anywhere
  # pair 43,44 or 81,88 in 2nd or later
  sub Bpred_rotate4_by_digits {
    my ($path, $n, $k) = @_;
    my @digits = reverse       # high to low
      Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,9);
    while (@digits < $k) { unshift @digits, 0; }  # pad to $k
    {
      my $i = 1;     # delete all 2s in 2nd or later
      while ($i <= $#digits) {
        if ($digits[$i] == 2) {
          splice @digits, $i, 1;
        } else {
          $i++;
        }
      }
    }
    foreach my $i (0 .. $#digits) {       # 0 anywhere
      if ($digits[$i] == 0) { return 0; }
    }
    foreach my $i (1 .. $#digits) {       # 5,6,7 in 2nd or later
      if ($digits[$i]==5 || $digits[$i]==6 || $digits[$i]==7) { return 0; }
    }
    foreach my $i (0 .. $#digits-1) {  # pair 13,33,53,73, 14,34,54,74 anywhere
      if (($digits[$i]==1 || $digits[$i]==3 || $digits[$i]==5 || $digits[$i]==7)
          && ($digits[$i+1]==3 || $digits[$i+1]==4)) {
        return 0;
      }
    }
    foreach my $i (1 .. $#digits-1) {  # pair 43,44, 81,88 in 2nd or later digit
      if (($digits[$i]==4  && ($digits[$i+1]==3 || $digits[$i+1]==4))
          ||
          ($digits[$i]==8  && ($digits[$i+1]==1 || $digits[$i+1]==8))
         ) { return 0; }
    }
    return 1;
  }
  my $path = Math::PlanePath::SquareReplicate->new
    (numbering_type => 'rotate-4');
  my $bad = 0;
  foreach my $k (0 .. 4) {
    my ($n_lo, $n_hi) = $path->level_to_n_range($k);
    foreach my $n ($n_lo .. $n_hi) {
      my $by_states = Bpred_rotate4_by_states($path,$n,$k) ? 1 : 0;
      my $by_path   = Bpred_by_path($path,$n,$k) ? 1 : 0;
      my $by_digits = Bpred_rotate4_by_digits($path,$n,$k) ? 1 : 0;
      if ($by_states != $by_path || $by_states != $by_digits) {
        my @n = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,9);
        my $n9 = join(',',reverse @n);
        MyTestHelpers::diag ("wrong Bpred k=$k n=$n [$n9] by_path $by_path by_states $by_states by_digits $by_digits");
        last if ++$bad > 10;
      }
    }
  }
  ok($bad,0);
}


#------------------------------------------------------------------------------
exit 0;
