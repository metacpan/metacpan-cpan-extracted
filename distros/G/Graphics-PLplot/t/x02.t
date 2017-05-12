#!perl

# Perl version of the PLplot C x02c.c example [colored text]

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
use Data::Dumper;
BEGIN {
  use_ok("Graphics::PLplot");
  Graphics::PLplot->import(qw/ :all /);
}
my $sleep = 2;
print "# Version: ". plgver() ."\n";

# 16 regions
plssub( 4, 4);

# Initialise plplot 

plsdev( "xwin" );
plinit();

plschr( 0.0, 3.5 );
plfont( 4 );

for ( my $i = 0; $i <= 15 ; $i ++ ) {
  plcol0( $i );
  my $text = $i;
  pladv( 0 );
  my $vmin = 0.1;
  my $vmax = 0.9;

  for (my $j = 0; $j <= 2; $j++ ) {
    plwid( $j + 1 );
    plvpor( $vmin, $vmax, $vmin, $vmax );
    plwind( 0.0, 1.0, 0.0, 1.0);
    plbox( "bc", 0, 0, "bc", 0, 0);
    $vmin += 0.1;
    $vmax -= 0.1;
  }
  plwid( 1 );
  plptex( 0.5, 0.5, 1.0, 0.0, 0.5, $text );
}

plflush();
sleep($sleep);
plspause(0);
plend();

print "# Ending \n";

exit;
