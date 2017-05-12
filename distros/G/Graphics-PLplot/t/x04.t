#!perl

# Perl version of the PLplot C x04c.c example [log plot]

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
use POSIX qw/ log10 /;
BEGIN {
  use_ok("Graphics::PLplot");
  Graphics::PLplot->import(qw/ :all /);
}
my $sleep = 2;
print "# Version: ". &plgver() ."\n";

plsdev( "xwin" );
plinit();
plfont(2);

plspause(0);
&plot1( 0 );
plflush();
sleep($sleep);
&plot1( 1 );
plflush();
sleep($sleep);
plend();

print "# Ending \n";

exit;

sub plot1 {
  my $type = shift;

  pladv( 0 );

  # Set up data for log plot
  my $f0 = 1.0;
  my (@freql,@ampl,@phase);
  for my $i (0..100) {
    $freql[$i] = -2.0 + $i / 20.0;
    my $freq = 10 ** $freql[$i];
    $ampl[$i] = 20 * log10( 1/ sqrt(1 + ($freq/$f0)**2 ));
    $phase[$i] = -(180/pi) * atan2($freq,$f0);
  }

  plvpor(0.15,0.85,0.1,0.9);
  plwind(-2,3,-80,0);

  # Try different axis and labelling styles
  plcol0(1);
  if ($type == 0) {
    plbox("bclnst",0,0,"bnstv",0,0);
  } else {
    plbox("bcfghlnst",0,0,"bcghnstv",0,0);
  }

  # Plot ampl vs freq
  plcol0(2);
  plline(\@freql, \@ampl);
  plcol0(1);
  plptex(1.6,-30,1,-20,0.5,"-20 dB/decade");

  # Put labels on
  plcol0(1);
  plmtex("b",3.2,0.5,0.5,"Frequency");
  plmtex("t",2,0.5,0.5,"Single Pole Low-Pass Filter");
  plcol0(2);
  plmtex("l",5,0.5,0.5,"Amplitude (dB)");

  # For the gridless case, put phase vs freq on same plot
  if ($type == 0) {
    plcol0(1);
    plwind(-2,3,-100,0);
    plbox("",0,0,"cmstv",30,3);
    plcol0(3);
    plline(\@freql,\@phase);
    plcol0(3);
    plmtex("r",5,0.5,0.5,"Phase shift (degrees)");
  }

}
