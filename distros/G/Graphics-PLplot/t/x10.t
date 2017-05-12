#!perl

# Perl version of the PLplot C x10c.c Window positioning demo
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

# Set up viewport and window
plvpor(0, 1, 0, 1);
plwind(0, 1, 0, 1);
plbox("bc",0,0,"bc",0,0);

plsvpa(50,150,50,100);
plwind(0,1,0,1);
plbox("bc",0,0,"bc",0,0);
plptex(0.5,0.5,1,0,0.5,"BOX at (50,150,50,100)");

plspause(0);
plflush();
sleep($sleep);
plend();

print "# Ending \n";

exit;
