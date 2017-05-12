#!/usr/bin/env perl

use strict;
use warnings;

use Image::Magick;
use Image::Magick::PolyText;

use Time::Elapsed qw(elapsed);

# ------------------------------------------------

print "Image::Magick::PolyText V $Image::Magick::PolyText::VERSION. \n";
print "\n";

my $start_time	= time;
my $x_1			= [100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700];
my $y_1			= [100, 147, 184, 199, 190, 159, 114, 65, 25, 3, 5, 30, 73];
my $x_2			= [100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700];
my $y_2			= [250, 297, 334, 349, 340, 309, 264, 215, 175, 153, 155, 180, 223]; # $y_1[*] + 150.
my $image		= Image::Magick -> new(size => '800 x 400');
my $result		= $image -> Read('xc:white');
$result			= $image -> Set(font => 't/n019003l.pfb');

die $result if $result;

my $polytext_1 = Image::Magick::PolyText -> new
({
	debug		=> 0,
	fill		=> 'Red',
	image		=> $image,
	pointsize	=> 16,
	rotate		=> 1,
	slide		=> 0.1,
	stroke		=> 'Red',
	strokewidth	=> 1,
	text		=> 'Draw text along a polyline',
	x			=> $x_1,
	y			=> $y_1,
});
my $polytext_2 = Image::Magick::PolyText -> new
({
	debug		=> 0,
	fill		=> 'Red',
	image		=> $image,
	pointsize	=> 16,
	rotate		=> 1,
	slide		=> 0.2,
	stroke		=> 'Red',
	strokewidth	=> 1,
	text		=> 'Draw text along a polyline',
	x			=> $x_2,
	y			=> $y_2,
});

# Draw the curves
# ---------------

$polytext_1 -> draw(stroke => 'red');
$polytext_1 -> highlight_data_points(stroke => 'black');
$polytext_2 -> draw(stroke => 'green');
$polytext_2 -> highlight_data_points(stroke => 'blue');

# Draw the text
# -------------

$polytext_1 -> annotate;
$polytext_2 -> annotate;

# Write the image to disk
# -----------------------

my $output_file_name = 'pt.png';

$result = $image -> Write($output_file_name);

die $result if $result;

print "Wrote $output_file_name. \n";
print "Image depth: @{[$image -> get('depth')]} bits per pixel. \n";
print "That took @{[elapsed(time() - $start_time)]}. \n";
