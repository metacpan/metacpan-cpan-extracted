#!perl
 
# Perl version of the PLplot C x17c.c example - Demo of StripChart
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
use Test::More tests => 3;
use Math::Trig qw/ pi /;
BEGIN {
  use_ok("Graphics::PLplot");
  Graphics::PLplot->import(qw/ :all /);
}

print "# Version: ". &plgver() ."\n";

# If db is used the plot is much more smooth. However, because of the
# async X behaviour, one does not have a real-time scripcharter.
plsetopt("db", "");
plsetopt("np", "");

# User sets up plot completely except for window and data
# Eventually settings in place when strip chart is created will be
# remembered so that multiple strip charts can be used simultaneously.

# Specify some reasonable defaults for ymin and ymax
# The plot will grow automatically if needed (but not shrink)

my $ymin = -0.1;
my $ymax = 0.1;

# Specify initial tmin and tmax -- this determines length of window.
# Also specify maximum jump in t
# This can accomodate adaptive timesteps

my $tmin = 0;
my $tmax = 10;
my $tjump = 0.3;  # Percentage of plot to jump

# Axes options same as plbox.
# Only automatic tick generation and label placement allowed
# Eventually I'll make this fancier

my $colbox = 1;
my $collab = 3;
my @colline = (2,3,4,5);  # pens color
my @styline = @colline;   # linestyle

# Pen legends
my @legline = (qw/ sum sin sin*noi sin+noi /);

# legend position
my $xlab = 0;
my $ylab = 0.25;

my $autoy = 1;  # autoscale y
my $acc = 1;    # don't scrip, accumulate

# Initialize plplot

my $dev = "xwin";
plsdev( $dev );
is(plgdev, $dev, "Check device");

plinit();

pladv(0);
plvsta();

my $id = plstripc( "bcnst", "bcnstv", $tmin, $tmax,
		   $tjump, $ymin, $ymax,
		   $xlab, $ylab,
		   $autoy, $acc,
		   $colbox, $collab,
		   \@colline, \@styline, \@legline,
		   "t", "", "Strip chart demo");

isa_ok( $id, "Graphics::PLplot::StripChart");

# This is to represent a loop over time
#  Let's try a random walk process
my ($y1, $y2, $y3, $y4 ) = (0,0,0,0);
my $dt = 0.1;

for my $n (0..999) {

  # Sleep a little to simulate time elapsing
  select(undef,undef,undef,0.01);

  my $t = $n * $dt;
  my $noise = rand(1) - 0.5;
  $y1 += $noise;
  $y2 = sin($t * pi / 18);
  $y3 = $y2 * $noise;
  $y4 = $y2 + ($noise/3);

  # There is no need for all pens to have the same number of
  # points or beeing equally time spaced.
  $id->plstripa( 0, $t, $y1 ) if $n%2;
  $id->plstripa( 1, $t, $y2 ) if $n%3;
  $id->plstripa( 2, $t, $y3 ) if $n%4;
  $id->plstripa( 3, $t, $y4 ) if $n%5;

  pleop(); # use double buffer

}

# destroy strip chart and its memory
undef $id; # auto destructor
plspause(0); # disappear automatically for test
plend();

