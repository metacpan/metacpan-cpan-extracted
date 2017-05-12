#!perl

# Perl version of the PLplot C x12c.c Bar Chart demo
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
use Test::More tests => 1;
use Math::Trig qw/ pi /;
BEGIN {
  use_ok("Graphics::PLplot");
  Graphics::PLplot->import(qw/ :all /);
}
my $sleep = 2;
print "# Version: ". &plgver() ."\n";

plsdev( "xwin" );
plinit();
pladv(0);


plvsta();
plwind(1980.0, 1990.0, 0.0, 35.0);
plbox("bc", 1.0, 0, "bcnv", 10.0, 0);
plcol0(2);
pllab("Year", "Widget Sales (millions)", "#frPLplot Example 12");

my @y0 = ( 5, 15, 22, 24, 28, 30, 20, 8, 12, 3);

for my $i (0..9) {
  plcol0( $i + 1 );
  plpsty(0);
  plfbox( ( 1980 + $i ), $y0[$i]);
  plptex( ( 1980 + $i + 0.5), ($y0[$i]+1),1,0.0,.5,$y0[$i]);
  plmtex("b",1,(($i+1) * 0.1 - 0.05), 0.5, (1980+$i));

}
plspause(0);
plflush();
sleep($sleep);
plend();

print "# Ending \n";

exit;

sub plfbox {
  my ($x0, $y0) = @_;
  my @x = ( $x0, $x0, $x0+1, $x0+1);
  my @y = ( 0, $y0, $y0, 0);

  plfill(\@x, \@y);
  plcol0(1);
  pllsty(1);
  plline(\@x, \@y);
}
