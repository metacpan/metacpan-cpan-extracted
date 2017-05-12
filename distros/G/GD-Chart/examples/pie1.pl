#!/usr/bin/perl

use strict;
use GD::Chart;

# Example of 2D Pie Chart
# Data from June 2001 Netcraft Survey at http://www.netcraft.com/survey/ 

my(@labels) = ("Apache", "Zeus", "IIS", "Netscape");
my(@data) = (18466153, 810108, 5972321, 1768673);
my(@cols) = (hex '0000ff', hex 'ff00ff', hex '00ffff', hex 'ffff00');

my $pie = new GD::Chart(250, 250);

my(%opts) = (
	title		=> "Web Server Usage for June 2001",
	data		=> \@data,
	labels		=> \@labels,
	colours		=> \@cols,
	pie_type	=> $GD::Chart::GDC_2DPIE,
	image_type	=> $GD::Chart::GDC_PNG,
	edge_colour	=> hex '000000',
	percent_labels   => $GD::Chart::GDCPIE_PCT_ABOVE,
	bgcolour	=> hex 'ffffff',
#	label_dist	=> 20,
#	label_line	=> $GD::Chart::TRUE

);

$pie->options(\%opts);

$pie->filename("pie1.png");

$pie->draw();

exit;
