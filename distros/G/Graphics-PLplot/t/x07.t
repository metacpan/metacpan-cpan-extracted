#!perl

# Perl version of the PLplot C x07c.c plsym Font demo
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
my $sleep = 0.2;
print "# Version: ". &plgver() ."\n";

# Starting points for symbol lookup
my @base = ( 0, 200, 500, 600, 700, 800, 900,
	     2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900 );


plsdev( "xwin" );
plinit();
plfontld(1);
plspause(0);

for my $base (@base) {

  pladv(0);

  # Set up viewport and window
  plcol0(2);
  plvpor(0.15, 0.95, 0.1, 0.9);
  plwind(0,1,0,1);

  # Draw the grid
  plbox("bcgt",0.1,0,"bcgt",0.1,0);

  # Write digits below the frame
  plcol0(15);
  for my $i (0..9) {
    plmtex("b",1.5,(0.1*$i + 0.05), 0.5,$i);
  }

  my $k = 0;
 OUTER: for my $i ( 0..9) {

    # Write the digits to the left of the frame
    plmtex("lv",1,(0.95- 0.1*$i),1,($base + 10 * $i));

    my $y = 0.95 - 0.1 * $i;
    for my $j ( 0..9 ) {

      my $x = 0.1 * $j + 0.05;

      # Need to use ref to array even with one element
      plsym([$x], [$y], ($k + $base));
      last OUTER if $k >= 127;
      $k++;
    }
  }

  plmtex("t",1.5,0.5,0.5, "PLplot Example 7 - PLSYM symbols");
  plflush();
  select undef,undef,undef,$sleep;
}
plend();

print "# Ending \n";

exit;
