#!/usr/bin/perl -w

# Copyright 2019, 2020 Kevin Ryde

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
plan tests => 253;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::PeanoDiagonals;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::PeanoDiagonals::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::PeanoDiagonals->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::PeanoDiagonals->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::PeanoDiagonals->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::PeanoDiagonals->new;
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
  my $path = Math::PlanePath::PeanoDiagonals->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
  ok ($path->class_x_negative, 0, 'class_x_negative()');
  ok ($path->class_y_negative, 0, 'class_y_negative()');
}


#----------------------------------------------------------------------------
# Even Radix Offsets

# {
#   foreach my $radix (4) {
#     my $bad = 0;
#     my $diag  = Math::PlanePath::PeanoDiagonals->new (radix => $radix);
#     my $plain = Math::PlanePath::PeanoCurve->new (radix => $radix);
#     foreach my $n (0 .. $radix**6) {
#       my ($plain_x,$plain_y) = $plain->n_to_xy($n);
#       my $want_y = $plain_y + ($n % 2);
#       my $want_x = $plain_x + (int($n/$radix) % 2);
#       my ($diag_x,$diag_y) = $diag->n_to_xy($n);
#       unless ($diag_x == $want_x && $diag_y == $want_y) {
#         print "n=$n plain $plain_x,$plain_y want $want_x,$want_y got diag $diag_x,$diag_y\n";
#         last if $bad++ > 10;
#       }
#     }
#     ok ($bad, 0);
#   }
# }

# Even has various double-visited points.
# {
#   foreach my $radix (4) {
#     my $bad = 0;
#     my $path  = Math::PlanePath::PeanoDiagonals->new (radix => $radix);
#     my %seen;
#     foreach my $n (0 .. $radix**6) {
#       my ($x,$y) = $path->n_to_xy($n);
#       if (defined (my $prev = $seen{"$x,$y"})) {
#         print "n=$n at $x,$y already seen prev n=$prev\n";
#         last if $bad++ > 10;
#       } else {
#         $seen{"$x,$y"} = $n;
#       }
#     }
#     ok ($bad, 0,
#         'even radix no double-visited points');
#   }
# }


#----------------------------------------------------------------------------
# n_to_dxdy()

{
  my $path = Math::PlanePath::PeanoDiagonals->new;
  { my @dxdy = $path->n_to_dxdy(-1);
    ok (scalar(@dxdy), 0, 'no dxdy at n=-1');
  }
  { my @dxdy = $path->n_to_dxdy(0);
    ok (scalar(@dxdy), 2);
    ok ($dxdy[0], 1);
    ok ($dxdy[1], 1);
  }
}

#----------------------------------------------------------------------------
# _UNDOCUMENTED__n_to_turn_LSR()

{
  my $path = Math::PlanePath::PeanoDiagonals->new;
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(-1), undef);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(0), undef);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(1), -1);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(2), 1);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(3), 1);
}

sub n_to_turn_LSR_by_digits {
  my ($self, $n) = @_;
  require Math::PlanePath::Base::Digits;
  my @digits = Math::PlanePath::Base::Digits::digit_split_lowtohigh
    ($n, $self->{'radix'});
  my $turn = 1;
  while (@digits && $digits[0]==0) {  # low 0s
    $turn = -$turn;
    shift @digits;
  }
  foreach my $digit (@digits) {
    if ($digit % 2) {
      $turn = -$turn;
    }
  }
  return $turn;
}
sub CountLowZeros {
  my ($n, $radix) = @_;
  $n > 0 || die;
  my $ret = 0;
  until ($n % $radix) {
    $ret++;
    $n /= $radix;
  }
  return $ret;
}
sub n_to_turn_LSR_by_parity {
  my ($self, $n) = @_;
  # per POD
  return (-1)**($n + CountLowZeros($n, $self->{'radix'}));
}
{
  my $bad = 0;
  foreach my $radix (3,5,7) {
    my $path = Math::PlanePath::PeanoDiagonals->new (radix => $radix);
    foreach my $n (1 .. $radix**5) {
      my $by_path   = $path->_UNDOCUMENTED__n_to_turn_LSR($n);
      {
        my $by_digits = n_to_turn_LSR_by_digits($path,$n);
        unless ($by_path == $by_digits) {
          MyTestHelpers::diag ("radix=$radix");
          MyTestHelpers::diag ("  $by_path  _UNDOCUMENTED__n_to_turn_LSR()");
          MyTestHelpers::diag ("  $by_digits  n_to_turn_LSR_by_digits()");
          $bad++;
          last if $bad > 10;
        }
      }
      {
        my $by_parity = n_to_turn_LSR_by_parity($path,$n);
        unless ($by_path == $by_parity) {
          MyTestHelpers::diag ("radix=$radix");
          MyTestHelpers::diag ("  $by_path  _UNDOCUMENTED__n_to_turn_LSR()");
          MyTestHelpers::diag ("  $by_parity  n_to_turn_LSR_by_parity()");
          $bad++;
          last if $bad > 10;
        }
      }
    }
  }
  ok ($bad, 0,
      '_UNDOCUMENTED__n_to_turn_LSR() vs other ways');
}


#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::PeanoDiagonals->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 9); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 81); }
}


#------------------------------------------------------------------------------
# xy_to_n()

{
  my $path = Math::PlanePath::PeanoDiagonals->new;
  { my @n_list = $path->xy_to_n_list(0,0);
    ok (scalar(@n_list), 1);
    ok ($n_list[0], 0); }
  { my @n_list = $path->xy_to_n_list(1,0);
    ok (scalar(@n_list), 0);
    ok (join(',',@n_list), '',
        'xy_to_n_list(1,0)');
  }
  { my @n_list = $path->xy_to_n_list(-2,-2);
    ok (scalar(@n_list), 0); }
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              [ 0, 0,0 ],
              [ 1, 1,1 ],
              [ 2, 2,0 ],
              [ 3, 3,1 ],
              [ 4, 2,2 ],

              [ 61,  1,9 ],
              [ 425, 1,9 ],

              [  .25,   .25,  .25 ],
              [ 1.25,  1.25, 1-.25 ],
              [ 2.25,  2.25,  .25 ],
              [ 3.25,  3-.25, 1+.25 ],
              [ 4.25,  2-.25, 2-.25 ],

              # base 4
              [  .25,   .25,  .25,   4 ],
              [ 1.25,  1.25, 1-.25,  4 ],
              [ 14,  2,3,  4 ],
              [ 15,  1,4,  4 ],   # described in POD
              [ 125, 1,4,  4 ],

              # POD samples, ternary
              [  1, 1,1 ], [  5, 1,1 ],
              [  4, 2,2 ], [  8, 2,2 ],
              [  7, 1,3 ], [  9, 3,3 ],
              [ 47, 1,3 ], [ 45, 3,3 ],

              # POD samples, base 4
              [  0, 0,0,  4],      [ 0.25, 0.25,0.25,  4],
              [  1, 1,1,  4], 
              [  2, 2,0,  4], 
              [  3, 3,1,  4], 

              [  4, 4,1,  4], 
              [  5, 3,2,  4], 
              [  6, 2,1,  4], 
              [  7, 1,2,  4], 

              [  8, 0,2,  4], 
              [  9, 1,3,  4], 
              [  10, 2,2,  4], 
              [  11, 3,3,  4], 

              [  12, 4,3,  4], 
              [  13, 3,4,  4], 
              [  14, 2,3,  4], 
              [  15, 1,4,  4], 

              [  16, 4,4,  4], 
              [  17, 5,3,  4], 
              [  18, 6,4,  4], 
             );
  foreach my $elem (@data) {
    my ($n, $x,$y, $radix) = @$elem;
    $radix ||= 3;
    my $path = Math::PlanePath::PeanoDiagonals->new (radix => $radix);
    {
      # n_to_xy()
      my ($got_x, $got_y) = $path->n_to_xy ($n);
      if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
      if ($got_y == 0) { $got_y = 0 }
      ok ($got_x, $x, "n_to_xy() x at n=$n radix=$radix");
      ok ($got_y, $y, "n_to_xy() y at n=$n radix=$radix");
    }
    if ($n==int($n)) {
      # xy_to_n()
      my @got_n = $path->xy_to_n_list ($x, $y);
      my $found = ((grep {$_==$n} @got_n) ? 1 : 0);
      ok ($found, 1, "xy_to_n_list() n at x=$x,y=$y radix=$radix");
    }
    {
      $n = int($n);
      my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
      ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y radix=$radix");
      ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y radix=$radix");
    }
  }
}

#------------------------------------------------------------------------------
# rect_to_n_range

{
  # with current over-estimates
  my $path = Math::PlanePath::PeanoDiagonals->new;
  {
    # inside 9x9 block
    my ($nlo, $nhi) = $path->rect_to_n_range (0,0, 1,8);
    ok ($nhi, 9**2 - 1);
  }
  {
    # on 9x9 block boundary, up to next bigger
    my ($nlo, $nhi) = $path->rect_to_n_range (0,0, 1,9);
    ok ($nhi, 9**3 - 1);
  }
}


#------------------------------------------------------------------------------
# midpoints are PeanoCurve

{
  require Math::PlanePath::PeanoCurve;
  my $bad = 0;
  foreach my $radix (3,5,7) {
    my $path = Math::PlanePath::PeanoDiagonals->new (radix => $radix);
    my $mid = Math::PlanePath::PeanoCurve->new (radix => $radix);
    foreach my $n (0 .. $radix**5) {
      my ($x1,$y1) = $path->n_to_xy ($n);
      my ($x2,$y2) = $path->n_to_xy ($n+1);
      my $x = ($x1+$x2-1)/2;
      my $y = ($y1+$y2-1)/2;

      my ($mx,$my) = $mid->n_to_xy ($n);
      unless ($x == $mx && $y == $my) {
        $bad++;
      }
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
exit 0;
