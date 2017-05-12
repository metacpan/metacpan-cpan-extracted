#!perl

# Perl version of the PLplot C x20c.c example - Demo of plimage
#
# This version Copyright (C) 2004 Tim Jenness. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful,but WITHOUT ANY# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place,Suite 330, Boston, MA  02111-1307, USA
#

use strict;
use Test::More tests => 2;
use Math::Trig qw/ pi /;
use constant TWO_PI => 2 * pi;
use constant NPTS => 1000;
BEGIN {
  use_ok("Graphics::PLplot");
  Graphics::PLplot->import(qw/ :all /);
}

# Number of seconds to pause
my $sleep = 2;

use constant XDIM => 260;
use constant YDIM => 220;

print "# Version: ". &plgver() ."\n";

plSetUsage($0,"\n\tx20.t -dev xwin\n");
plParseOpts(\@ARGV, 0);

plsdev( "xwin" );
is(plgdev, "xwin", "Check device");

plinit();

# Assume debug until I can add Getopt processing
my $dbg = 1;
my $nosombrero = 0;
my $f_name = "blah";

if ($dbg) {
  my $z = pl_Alloc2dGrid( XDIM, YDIM );

  plenv(1,XDIM,1,YDIM,1,-2); # no plot box

  # one pixel square border
  for my $i (0..(XDIM-1)) {
    $z->[$i]->[YDIM-1] = 1;   # Right
  }
  for my $i (0..(XDIM-1)) {
    $z->[$i]->[0] = 1;        # Left
  }
  for my $i (0..(YDIM-1)) {
    $z->[0]->[$i] = 1;        # Top
  }
  for my $i (0..(YDIM-1)) {
    $z->[XDIM-1]->[$i] = 1;   # Bottom
  }

  pllab("...around a blue square."," ",
	"A red border should appear...");

  plimage($z, 1, XDIM, 1, YDIM, 0, 0,
	  1, XDIM, 1, YDIM);

  sleep($sleep);
  plspause(0);
  pladv(0);
  plspause(0);

}

if (!$nosombrero) {

  my $r = pl_Alloc2dGrid( XDIM, YDIM );
  my $z = pl_Alloc2dGrid( XDIM, YDIM );
  plcol0(2);
  plenv(0,2*pi, 0, 3*pi, 1, -1 );

  # Init x and y function
  my @x = map { $_ * TWO_PI / (XDIM-1) } (0..(XDIM-1));
  my @y = map { $_ * 3 * pi / (YDIM-1) } (0..(YDIM-1));

  for my $i (0..(XDIM-1)) {
    for my $j (0..(YDIM-1)) {
      $r->[$i]->[$j] = sqrt(($x[$i]*$x[$i]) +
			    ($y[$j]*$y[$j])) + 1E-3;
      $z->[$i]->[$j] = sin($r->[$i]->[$j]) / $r->[$i]->[$j];
    }
  }

  pllab("No, an amplitude clipped \"sombrero\"", "", "Saturn?");
  plptex(2., 2., 3., 4., 0., "Transparent image");

  plimage($z, 0, 2*pi, 0, 3*pi, 0.05, 1,
	  0, 2*pi, 0, 3*pi);

  save_plot( $f_name ) if $f_name;

  sleep($sleep);
  plspause(0);
  pladv(0);
  plspause(0);
}

plend();

# tidy up
unlink $f_name if $f_name;


exit;

sub save_plot {
  my $fname = shift;

  my $cur_strm = plgstrm();
  my $new_strm = plmkstrm();

  plsdev("psc");
  plsfnam($fname);

  plcpstrm($cur_strm, 0);
  plreplot();
  plend1();

  plsstrm( $cur_strm );

}

