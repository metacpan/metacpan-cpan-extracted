#!perl

# Perl version of the PLplot C x13c.c Pie Chart demo
#
# This version Copyright (C) 2004 Tim Jenness. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful,but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place,Suite 330, Boston, MA  02111-1307, USA
#

use strict;
use Test::More tests => 2;
use Math::Trig qw/ pi /;
BEGIN {
  use_ok("Graphics::PLplot");
  Graphics::PLplot->import(qw/ :all /);
}
my $sleep = 2;
print "# Version: ". &plgver() ."\n";

my @text = qw/ Maurice Geoffrey Alan Rafael Vince /;
my @per  = ( 10, 32, 12, 30, 16 );

my $dev = "xwin";
plsdev( $dev );
is(plgdev, $dev, "Check device");
plinit();

plenv(0., 10., 0., 10., 1, -2);
plcol0(2);

# all theta quantities scaled by 2*pi/500 to be integers to avoid
# floating point logic problems.
my $maxpts = 750; # Number of points around the circumference
my $dthet = 1;    # increment for each angle step

my $theta0 = 0;

for my $i ( 0..4 ) {
  my $j = 0;
  my (@x, @y);

  # Origin
  $x[$j] = 5;
  $y[$j++] = 5;

  my $theta1 = $theta0 + ($maxpts/100) * $per[$i];
  $theta1 = $maxpts if $i == 4;

  for (my $theta = $theta0; $theta <= $theta1; $theta += $dthet) {
    $x[$j]   = 5 + (3 * cos( 2 * pi  * $theta / $maxpts ));
    $y[$j++] = 5 + (3 * sin( 2 * pi  * $theta / $maxpts ));
  }

  plcol0($i+1);
  plpsty(($i+3) % 8 + 1);
  plfill( \@x, \@y );
  plcol0(1);
  plline(\@x, \@y);
  my $just = (2 * pi / $maxpts)  * ($theta0 + $theta1) / 2;
  my $dx = 0.25 * cos($just);
  my $dy = 0.25 * sin($just);
  if (($theta0+$theta1) < ($maxpts/2) || 
      ($theta0 + $theta1) > ($maxpts * 1.5)) {
    $just = 0;
  } else {
    $just =1;
  }

  plptex(( $x[$j/2]+$dx), ($y[$j/2]+$dy),1,0,$just,$text[$i]);
  $theta0 = $theta1 - $dthet;

}

plfont(2);
plschr(0., 1.3);
plptex(5.0, 9.0, 1.0, 0.0, 0.5, "Percentage of Sales");

plspause(0);
plflush();
sleep($sleep);
plend();

print "# Ending \n";

exit;
