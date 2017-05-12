#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base.
#
# Image-Base is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Image-Base.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use List::Util qw(min max);

# uncomment this to run the ### lines
use Smart::Comments;


my $a = 1000;
my $b = 1000;
my $aa = $a ** 2;
my $bb = $b ** 2;

my $x  = $a - int($a) ;  # 0 or 0.5
my $y  = $b ;
### initial: "start xy $x,$y"

my $d = ($x ? 2.25*$bb : $bb) - ( $aa * $b ) + ( $aa / 4 ) ;

my $max_d = 0;

while( $y >= 1
       && ( $aa * ( $y - 0.5 ) ) > ( $bb * ( $x + 1 ) ) ) {

  ### assert: $d == ($x+1)**2 * $bb + ($y-.5)**2 * $aa - $aa * $bb
  if( $d < 0 ) {
    $d += ( $bb * ( ( 2 * $x ) + 3 ) ) ;
    ++$x ;
  }
  else {
    $d += ( ( $bb * ( (  2 * $x ) + 3 ) ) +
            ( $aa * ( ( -2 * $y ) + 2 ) ) ) ;
    ++$x ;
    --$y ;
  }
  $max_d = max($d, $max_d);
}

# switch to d2 = E(x+1/2,y-1) by adding E(x+1/2,y-1) - E(x+1,y-1/2)
$d += $aa*(.75-$y) - $bb*($x+.75);

while( $y >= 1 ) {
  if( $d < 0 ) {
    $d += ( $bb * ( (  2 * $x ) + 2 ) ) +
      ( $aa * ( ( -2 * $y ) + 3 ) ) ;
    ++$x ;
    --$y ;
  }
  else {
    $d += ( $aa * ( ( -2 * $y ) + 3 ) ) ;
    --$y ;
  }
  ### assert: $d == $bb*($x+0.5)**2 + $aa*($y-1)**2 - $aa*$bb

  $max_d = max($d, $max_d);
}

### $max_d
