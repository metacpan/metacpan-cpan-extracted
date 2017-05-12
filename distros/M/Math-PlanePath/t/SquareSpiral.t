#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
plan tests => 482;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::SquareSpiral;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::SquareSpiral::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::SquareSpiral->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::SquareSpiral->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::SquareSpiral->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::SquareSpiral->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# cf formula in Graham, Knuth and Patashnik "Concrete Mathematics" page 99

sub Graham_Knuth_patashnik_x {
  my ($n) = @_;
  my $m = int(sqrt($n));
  return (-1)**$m * ( ($n - $m*($m+1)) * is_even(int(2*sqrt($n)))
                      + ceil(1/2*$m) );
}
sub is_even {
  my ($n) = @_;
  return ($n % 2 == 0 ? 1 : 0);
}
sub ceil {
  my ($n) = @_;
  return ($n == int($n) ? $n : int($n)+1);
}

{
  my $path = Math::PlanePath::SquareSpiral->new (n_start => 0);
  foreach my $n (0 .. 100) {
    my $gkp_x = Graham_Knuth_patashnik_x($n);
    my ($x,$y) = $path->n_to_xy($n);
    ok (-$y == $gkp_x, 1);
  }
}

#----------------------------------------------------------------------------
# _UNDOCUMENTED__n_to_turn_LSR()

{
  my $path = Math::PlanePath::SquareSpiral->new (n_start => 0);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(-1), undef);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(0), undef);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(1), 1);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(2), 1);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(3), 0);
}

#------------------------------------------------------------------------------
# formulas in pod

{
  my $path = Math::PlanePath::SquareSpiral->new;

  my $d = 3;
  my $Nbase = 4*$d**2 - 4*$d + 2;
  ok ($Nbase, 26);

  { my $N = $Nbase;
    my $dd = int (1/2 + sqrt($N/4 - 1/4));
    ok ($dd, $d, 'd');
    $dd = int ((1+sqrt($N-1)) / 2);
    ok ($dd, $d, 'd');
  }
  { my $N = $Nbase + 8*$d-1;
    my $dd = int (1/2 + sqrt($N/4 - 1/4));
    ok ($dd, $d, 'd');
    $dd = int ((1+sqrt($N-1)) / 2);
    ok ($dd, $d, 'd');
  }
  { my $N = $Nbase + 8*$d-1 + 1;
    my $dd = int (1/2 + sqrt($N/4 - 1/4));
    ok ($dd, $d+1, 'd');
    $dd = int ((1+sqrt($N-1)) / 2);
    ok ($dd, $d+1, 'd');
  }

  # right upwards
  { my $Nrem = 0;
    my ($want_x,$want_y) = $path->n_to_xy($Nbase+$Nrem);
    ok ($d,          $want_x, 'X');
    ok (-$d+1+$Nrem, $want_y, 'Y');
  }
  { my $Nrem = 2*$d-1;
    my ($want_x,$want_y) = $path->n_to_xy($Nbase+$Nrem);
    ok ($d,          $want_x, 'X');
    ok (-$d+1+$Nrem, $want_y, 'Y');
  }

  # top
  { my $Nrem = 2*$d-1;
    my ($want_x,$want_y) = $path->n_to_xy($Nbase+$Nrem);
    ok (3*$d-1-$Nrem, $want_x, 'X');
    ok ($d,           $want_y, 'Y');
  }
  { my $Nrem = 4*$d-1;
    my ($want_x,$want_y) = $path->n_to_xy($Nbase+$Nrem);
    ok (3*$d-1-$Nrem, $want_x, 'X');
    ok ($d,           $want_y, 'Y');
  }

  # left downwards
  { my $Nrem = 4*$d-1;
    my ($want_x,$want_y) = $path->n_to_xy($Nbase+$Nrem);
    ok (-$d,          $want_x, 'X');
    ok (5*$d-1-$Nrem, $want_y, 'Y');
  }
  { my $Nrem = 6*$d-1;
    my ($want_x,$want_y) = $path->n_to_xy($Nbase+$Nrem);
    ok (-$d,          $want_x, 'X');
    ok (5*$d-1-$Nrem, $want_y, 'Y');
  }

  # bottom
  { my $Nrem = 6*$d-1;
    my ($want_x,$want_y) = $path->n_to_xy($Nbase+$Nrem);
    ok (-7*$d+1+$Nrem, $want_x, 'X');
    ok (-$d,           $want_y, 'Y');
  }
  { my $Nrem = 8*$d;
    my ($want_x,$want_y) = $path->n_to_xy($Nbase+$Nrem);
    ok (-7*$d+1+$Nrem, $want_x, 'X');
    ok (-$d,           $want_y, 'Y');
  }


  # right upwards
  my $Nzero = $Nbase + 4*$d-1;
  { my $Nsig = -(4*$d-1);
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok ($d,         $want_x, 'X');
    ok (3*$d+$Nsig, $want_y, 'Y');
  }
  { my $Nsig = -2*$d;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok ($d,         $want_x, 'X');
    ok (3*$d+$Nsig, $want_y, 'Y');
  }

  # top
  { my $Nsig = -2*$d;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok (-$d-$Nsig, $want_x, 'X');
    ok ($d,        $want_y, 'Y');
  }
  { my $Nsig = 0;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok (-$d-$Nsig, $want_x, 'X');
    ok ($d,           $want_y, 'Y');
  }

  # left downwards
  { my $Nsig = 0;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok (-$d,      $want_x, 'X');
    ok ($d-$Nsig, $want_y, 'Y');
  }
  { my $Nsig = 2*$d;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok (-$d,      $want_x, 'X');
    ok ($d-$Nsig, $want_y, 'Y');
  }

  # bottom
  { my $Nsig = 2*$d;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok ($Nsig-3*$d, $want_x, 'X');
    ok (-$d,        $want_y, 'Y');
  }
  { my $Nsig = 4*$d+1;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok ($Nsig-3*$d, $want_x, 'X');
    ok (-$d,        $want_y, 'Y');
  }
}

#------------------------------------------------------------------------------
# formulas in pod -- wider

{
  my $path = Math::PlanePath::SquareSpiral->new (wider => 7);

  my $d = 3;
  my $w = 7;
  my $Nbase = 4*$d**2 + (-4+2*$w)*$d + 2-$w;
  ok ($Nbase, 61);
  my $wl = int(($w+1)/2); # ceil
  my $wr = int($w/2);     # floor
  ok ($wl, 4);
  ok ($wr, 3);

  { my $N = $Nbase;
    my $dd = int ((2-$w + sqrt(4*$N + $w**2 - 4)) / 4);
    ok ($dd, $d, 'd');
  }
  { my $N = $Nbase + 8*$d+2*$w-1;
    my $dd = int ((2-$w + sqrt(4*$N + $w**2 - 4)) / 4);
    ok ($dd, $d, 'd');
  }
  { my $N = $Nbase + 8*$d+2*$w-1 + 1;
    my $dd = int ((2-$w + sqrt(4*$N + $w**2 - 4)) / 4);
    ok ($dd, $d+1, 'd');
  }

  # right upwards
  my $Nzero = $Nbase + 4*$d-1+$w;
  { my $Nsig = -(4*$d-1+$w);
    ok ($Nzero+$Nsig, $Nbase);
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok ($d+$wr,        $want_x, 'X');
    ok (3*$d+$w+$Nsig, $want_y, 'Y');
  }
  { my $Nsig = -(2*$d+$w);
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok ($d+$wr,        $want_x, 'X');
    ok (3*$d+$w+$Nsig, $want_y, 'Y');
  }
  
  # top
  { my $Nsig = -(2*$d+$w);
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok (-$d-$wl-$Nsig, $want_x, 'X');
    ok ($d,            $want_y, 'Y');
  }
  { my $Nsig = 0;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok (-$d-$wl-$Nsig, $want_x, 'X');
    ok ($d,            $want_y, 'Y');
  }
  
  # left downwards
  { my $Nsig = 0;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok (-$d-$wl,  $want_x, 'X');
    ok ($d-$Nsig, $want_y, 'Y');
  }
  { my $Nsig = 2*$d;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok (-$d-$wl,  $want_x, 'X');
    ok ($d-$Nsig, $want_y, 'Y');
  }
  
  # bottom
  { my $Nsig = 2*$d;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok ($Nsig-$wl-3*$d, $want_x, 'X');
    ok (-$d,            $want_y, 'Y');
  }
  { my $Nsig = 4*$d+1+$w;
    my ($want_x,$want_y) = $path->n_to_xy($Nzero+$Nsig);
    ok ($Nsig-$wl-3*$d, $want_x, 'X');
    ok (-$d,            $want_y, 'Y');
  }
}


#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::SquareSpiral->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative() instance method');
  ok ($path->y_negative, 1, 'y_negative() instance method');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::SquareSpiral->parameter_info_list;
  ok (join(',',@pnames), 'wider,n_start');
}

#------------------------------------------------------------------------------
# n_to_xy

#   17 16 15 14 13
#   18  5  4  3 12
#   19  6  1  2 11
#   20  7  8  9 10
#   21 22 23 24 25 26
{
  my @data = ([ 1, 0,0 ],
              [ 2, 1,0 ],

              [ 3, 1,1 ], # top
              [ 4, 0,1 ],

              [ 5, -1,1 ],  # left
              [ 6, -1,0 ],

              [ 7, -1,-1 ], # bottom
              [ 8,  0,-1 ],
              [ 9,  1,-1 ],

              [ 10,  2,-1 ], # right
              [ 11,  2, 0 ],
              [ 12,  2, 1 ],

              [ 13,   2,2 ], # top
              [ 14,   1,2 ],
              [ 15,   0,2 ],
              [ 16,  -1,2 ],

              [ 17,  -2, 2 ], # left
              [ 18,  -2, 1 ],
              [ 19,  -2, 0 ],
              [ 20,  -2,-1 ],

              [ 21,  -2,-2 ], # bottom
              [ 22,  -1,-2 ],
              [ 23,   0,-2 ],
              [ 24,   1,-2 ],
              [ 25,   2,-2 ],

              [ 26,   3,-2 ], # right
              [ 27,   3,-1 ],
             );
  my $path = Math::PlanePath::SquareSpiral->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }
}

#------------------------------------------------------------------------------
# random n_to_dxdy()

{
  foreach my $wider (0 .. 10) {
    my $path = Math::PlanePath::SquareSpiral->new (wider => $wider);
    # for (my $n = 1.25; $n < 40; $n++) {
    foreach (1 .. 10) {
      my $bits = int(rand(25));     # 0 to 25, inclusive
      my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

      my ($x,$y) = $path->n_to_xy ($n);
      my ($next_x,$next_y) = $path->n_to_xy ($n+1);
      my $delta_dx = $next_x - $x;
      my $delta_dy = $next_y - $y;

      my ($func_dx,$func_dy) = $path->n_to_dxdy($n);
      if ($func_dx == 0) { $func_dx = '0'; } # avoid -0 in perl 5.6
      if ($func_dy == 0) { $func_dy = '0'; } # avoid -0 in perl 5.6

      ok ($func_dx, $delta_dx, "n_to_dxdy($n) wider=$wider dx at xy=$x,$y");
      ok ($func_dy, $delta_dy, "n_to_dxdy($n) wider=$wider dy at xy=$x,$y");
    }
  }
}


exit 0;
