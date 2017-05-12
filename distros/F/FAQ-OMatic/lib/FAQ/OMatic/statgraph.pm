##############################################################################
# The Faq-O-Matic is Copyright 1997 by Jon Howell, all rights reserved.      #
#                                                                            #
# This program is free software; you can redistribute it and/or              #
# modify it under the terms of the GNU General Public License                #
# as published by the Free Software Foundation; either version 2             #
# of the License, or (at your option) any later version.                     #
#                                                                            #
# This program is distributed in the hope that it will be useful,            #
# but WITHOUT ANY WARRANTY; without even the implied warranty of             #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
# GNU General Public License for more details.                               #
#                                                                            #
# You should have received a copy of the GNU General Public License          #
# along with this program; if not, write to the Free Software                #
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.#
#                                                                            #
# Jon Howell can be contacted at:                                            #
# 6211 Sudikoff Lab, Dartmouth College                                       #
# Hanover, NH  03755-3510                                                    #
# jonh@cs.dartmouth.edu                                                      #
#                                                                            #
# An electronic copy of the GPL is available at:                             #
# http://www.gnu.org/copyleft/gpl.html                                       #
#                                                                            #
##############################################################################

use strict;

package FAQ::OMatic::statgraph;

use CGI;
use GD;

my $image_type;
{
  my $image = new GD::Image (10, 10);
  $image_type = $image->can('gif') ? "gif" : "png";

}


use FAQ::OMatic;
use FAQ::OMatic::Item;
use FAQ::OMatic::Log;

use vars qw($width $height
	$minx $rangex $basex $sizex
	$miny $rangey $basey $sizey);	# file scope, for mod_perl

sub calcx {
	my ($arg) = shift;
	return int($basex+min((($arg-($minx))/$rangex)*$sizex,$sizex));
}
sub calcy {
	my ($arg) = shift;
	return int($basey+$sizey-min((($arg-$miny)/$rangey)*$sizey,$sizey));
}

sub max {
	my ($x, $y) = @_;
	return $x if ($x > $y);
	return $y;
}

sub min {
	my ($x, $y) = @_;
	return $x if ($x < $y);
	return $y;
}

sub emptygraph {
	my ($message) = shift;

	my $image = new GD::Image (200, 12);
	my $white = $image->colorAllocate(255, 255, 255);
	my $red = $image->colorAllocate(255, 0, 0);
	$image->filledRectangle(0, 0, $width, $height, $white);
	$image->string(gdSmallFont, 0, 0, $message, $red);
	print $image->$image_type();
	FAQ::OMatic::myExit(0);
}

#given a range value, returns a nice round interval
sub autorange {
	my ($range) = shift;
	my ($multiplier) = 1.0;
	my $interval;

	emptygraph("Range $range<=0.") if ($range <= 0);	#that's an error
	while ($range < 10) {
		$range *= 10.0;
		$multiplier *= 0.1;
	}
	while ($range >= 100) {
		$multiplier *= 10.0;
		$range *= 0.1;
	}
	if ($range <= 25.0) {
		$interval = 2.5;
	} elsif ($range <= 50.0) {
		$interval = 5.0;
	} else {
		$interval = 10.0;
	}
	return $multiplier*$interval;
}

sub autoIntervalDays {
	my ($range) = shift;
	my $interval;

	if ($range > 450) {
		return (365,'Years');
	} elsif ($range > 30*3) {
		return (30,'Months');
	} else {
		return (7,'Weeks');
	}
}

#given (min,max), return (min,max,range,interval), with a nice interval
# and rounded min and max.
sub round {
	my ($arg) = shift;
	return int($arg+0.5) if ($arg >= 0);
	return int($arg-0.5);
}

sub rerange {
	my ($min, $max) = @_;

	my $interval = autorange($max-$min);
	my $newmin = (round($min/$interval)-1)*$interval;
	my $newmax = (round($max/$interval)+1)*$interval;
	return ($newmin, $newmax, $newmax-$newmin, $interval);
}

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();

	$cgi->cache('NO');	# recommend that netscape not cache this image
	print FAQ::OMatic::header($cgi, 
							'-type' => "image/$image_type",
							 '-nph' => 1,
						 '-expires' => 0.000000001);

	my $params = FAQ::OMatic::getParams($cgi,'nolog');
	my $property = $params->{'property'};
	my $duration = $params->{'duration'} || $FAQ::OMatic::Appearance::graphHistory;
	my $resolution = int($params->{'resolution'} || '1');
	my $today = $params->{'today'} || FAQ::OMatic::Log::numericToday();

	# gotta sanity-check these things, because of stupid infinite loop
	# in timelocal()
	my ($yr,$mo,$dy) = split('-',$today);
	if ($yr<1990 or $yr>2036 or $mo<0 or $mo>11 or $dy<0 or $dy>31) {
		$today = FAQ::OMatic::Log::numericToday();
	}

	$resolution = 1 if ($resolution < 0);
	$resolution = 14 if ($resolution > 14);

	if ($duration eq 'history') {
		$duration = FAQ::OMatic::Log::subTwoDays($today,FAQ::OMatic::Log::earliestSmry());
	} else {
		$duration = int($duration);
	}

	if (($duration/$resolution) > $FAQ::OMatic::Appearance::graphWidth) {
		# no point in gathering too many data points!
		$resolution = int($duration / $FAQ::OMatic::Appearance::graphWidth);
	}
	# guarantee at least two items in @mydata
	$duration = $resolution if ($duration <= 0);

	# collect the data of interest.
	my $day;
	my $earliestday = FAQ::OMatic::Log::adddays($today, -$duration);
	my @mydata = ();	# The data point itself
	my @myindex = ();	# The day "number" (-$duration .. 0) of that data point
						# (i.e. where it goes on the graph)
	my $i;
	for ($day = $today, $i=0;
		$day ge $earliestday;
		$day = FAQ::OMatic::Log::adddays($day, -$resolution), $i-=$resolution) {

		my $item = new FAQ::OMatic::Item($day.".smry", $FAQ::OMatic::Config::metaDir);
		if (defined $item->{$property}) {
			unshift @mydata, $item->{$property};
			unshift @myindex, $i;
		} else {
			unshift @mydata, 0;
			unshift @myindex, $i;
		}
	}

	# days run from negative (history) to zero (today)
	$minx = $myindex[0];
	my $maxx = $myindex[$#myindex];
	my $maxy;
	($miny, $maxy) = (+10000000, -1000000);
	foreach my $i (@mydata) {
		$miny = min($miny, $i);
		$maxy = max($maxy, $i);
	}

	# autorange y
	$miny = 0;	#Want bottom of graph to be at 0
	$maxy = max($maxy,1);	# make sure range doesn't collapse to 0
	my $intervaly;
	($miny, $maxy, $rangey, $intervaly) = rerange($miny, $maxy);
	$miny = 0;	# autoranging may have nudged miny to -1, so fix it
	$rangey = $maxy-$miny;	# thus fix range, too.

	# get x interval automatically
	$rangex = $maxx - $minx;
	my ($intervalx,$unitsx) = autoIntervalDays($rangex);

	$width = $FAQ::OMatic::Appearance::graphWidth;
	$height = $FAQ::OMatic::Appearance::graphHeight;	# from FAQ::OMatic::FaqConfig
	my $borderx = 30;
	my $bordery = 10;

	my $image = new GD::Image ($width, $height);
	my $transparent = $image->colorAllocate(255, 255, 255);
	my $framefill = $image->colorAllocate(255, 255, 255);
	my $grid = $image->colorAllocate(192, 192, 192);
	my $datafill = $image->colorAllocate(0, 0, 132);
	my $datacolor = $image->colorAllocate(240, 0, 0);
	my $frame = $image->colorAllocate(128, 0, 0);
	my $labels = $image->colorAllocate(10, 88, 0);

	# draw the graph in this order, back-to-front:
	# transparent (whole image background)
	# framefill
	# grid
	# datafill
	# datacolor
	# ticks (grid color)
	# frame
	# labels

	# transparent
	$image->filledRectangle(0, 0, $width, $height, $transparent);

	# framefill
	# note these are globals so calc[xy] can see them
	($basex, $basey) = ($borderx, $bordery);
	($sizex, $sizey) = ($width-2*$borderx, $height-3*$bordery);
	$image->filledRectangle($basex, $basey, $basex+$sizex, $basey+$sizey,
			$framefill);

	# grid
	for ($i=$miny; $i<=$maxy; $i+=$intervaly) {
		$image->line(calcx($minx), calcy($i),
			calcx($miny), calcy($i), $grid);
	}

	# datafill - plot data region
	# I use many little polys instead of one big one because GD has
	# a bug wherein it fails to fill polygons correctly when three points
	# share the same y value.
	for ($i=0; $i<scalar(@mydata)-1; $i++) {
		my $poly = new GD::Polygon;

		$poly->addPt(calcx($myindex[$i]), calcy($miny));
		$poly->addPt(calcx($myindex[$i]), calcy($mydata[$i]));
		$poly->addPt(calcx($myindex[$i+1]), calcy($mydata[$i+1]));
		$poly->addPt(calcx($myindex[$i+1]), calcy($miny));

		#$image->filledPolygon($poly, $datafill);
	}

	# ticks - provide scale for image
	my $tickwidth = 5;
	for ($i=$maxx; $i>$minx; $i-=$intervalx) {
		$image->line(calcx($i), calcy($miny),
			calcx($i), calcy($miny)-$tickwidth, $grid);
		my $label = $i/$intervalx;
		$label = "Today" if ($label == 0);
		$image->string(gdTinyFont, calcx($i)-2, calcy($miny)+1,
			$label, $labels);
	}
	my $title=$params->{'title'} || $property;
	$image->string(gdSmallFont, calcx($minx+$rangex*0.5)-length($title)*6/2,
		calcy($maxy)-12, $title, $labels);
	for ($i=$miny; $i<=$maxy; $i+=$intervaly) {
		$image->line(calcx($minx), calcy($i),
			calcx($minx)+$tickwidth, calcy($i), $grid);
		$image->line(calcx($maxx), calcy($i),
			calcx($maxx)-$tickwidth, calcy($i), $grid);
		my $label = $i;
		$label =~ s/000$/k/;
		$image->string(gdTinyFont, $borderx-length($label)*5-2,
			calcy($i)-3, $label, $labels);
	}
	$image->string(gdTinyFont, calcx($minx+$rangex*0.5)-length($unitsx)*5/2,
		calcy($miny)+10, $unitsx, $labels);

	# datacolor - highlight top edge of data
	for ($i=0; $i<scalar(@mydata)-1; $i++) {
		$image->line(calcx($myindex[$i]), calcy($mydata[$i]),
					calcx($myindex[$i+1]), calcy($mydata[$i+1]), $datacolor);
	}

	# frame - outline the plot box
	$image->rectangle($basex, $basey, $basex+$sizex, $basey+$sizey, $frame);

	# announce final value (should show up over ticks)
	my $value = $mydata[$#mydata];
	if (not $value =~ m/\./) {
		# for big numbers
		$value =~ s/(?!^|,)(\d\d\d)$/,$1/;	# add commas for readability
		$value =~ s/(?!^|,)(\d\d\d),/,$1,/;	# of big numbers. This'll keep you
		$value =~ s/(?!^|,)(\d\d\d),/,$1,/;	# til your trillionth hit. :v)
	} else {
		# for little numbers
		$value = sprintf "%.2f", $value;
	}
	my @spots = ( [-1, 0,$framefill],
				  [-1,-1,$framefill],
				  [ 0,-1,$framefill],
				  [ 1,-1,$framefill],
				  [ 1, 0,$framefill],
				  [ 1, 1,$framefill],
				  [ 0, 1,$framefill],
				  [-1, 1,$framefill],
				  [ 0, 0,$datafill] );
	foreach my $spot (@spots) {
		$image->string(gdTinyFont, calcx($maxx)-5*length($value)+18+$spot->[0],
			max(calcy($mydata[$#mydata])-9+$spot->[1],$basey+2),
			$value, $spot->[2]);
	}

	# make image background transparent so it'll look nicer sitting
	# in the browser
	$image->transparent($transparent);

	# send image
	print $image->$image_type();
}

1;
