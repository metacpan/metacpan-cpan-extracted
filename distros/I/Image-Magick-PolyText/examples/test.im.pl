#!/usr/bin/env perl

use strict;
use warnings;

use Image::Magick;

use List::Maker;

use Math::Derivative 'Derivative1';

use Readonly;

use Time::Elapsed qw(elapsed);

# ------------------------------------------------

Readonly::Scalar my $pi			=> 3.14159;
Readonly::Scalar my $start_time => time;
my($image)						= Image::Magick -> new(size => '800 x 400');
my($result)						= $image -> Read('xc:white');

die $result if $result;

# Generate the (x, y) pairs
# -------------------------
my(@x, $x);
my($y, @y);

# List::Maker can't handle <0 .. 2 * $pi x 0.1>.

my($gap)	= 150; # Vertical gap between curves.
my($s1)		= '';
my($s2)		= '';
my($step)	= $pi;

# Note: The syntax @{[expression]} enables Perl to interpolate
# the result of an expression evaluation into a string.

for $step (<0 .. $step x 0.5>)
{
	$x	= 100 + int(100 * $step);
	$y	=  50 + int(100 * sin($step) );
	$s1	.= "$x $y ";
	$s2	.= "$x @{[$y + $gap]} ";

	push @x, $x;
	push @y, $y;
}

print "X: ", join(', ', @x), ". \n";
print "Y: ", join(', ', @y), ". \n";

# Draw the 2 curves
# -----------------
$result	= $image -> Draw
(
	fill		=> 'None',
	points		=> $s1,
	primitive	=> 'polyline',
	stroke		=> 'Green',
	strokewidth	=> 1,
);

die $result if $result;

$result	= $image -> Draw
(
	fill		=> 'None',
	points		=> $s2,
	primitive	=> 'polyline',
	stroke		=> 'Green',
	strokewidth	=> 1,
);

die $result if $result;

# Draw little rectangles at the (x, y) points
# -------------------------------------------
my($i);
my($left_x, $left_y);
my($right_x, $right_y);

for ($i = 0; $i <= $#x; $i++)
{
	$left_x		= $x[$i] - 2;
	$left_y		= $y[$i] - 2;
	$right_x	= $x[$i] + 2;
	$right_y	= $y[$i] + 2;
	$result		= $image -> Draw
	(
		fill		=> 'None',
		points		=> "$left_x,$left_y $right_x,$right_y",
		primitive	=> 'rectangle',
		stroke		=> 'Red',
		strokewidth	=> 1,
	);

	die $result if $result;

	$left_y		= $y[$i] - 2 + $gap;
	$right_y	= $y[$i] + 2 + $gap;
	$result		= $image -> Draw
	(
		fill		=> 'None',
		points		=> "$left_x,$left_y $right_x,$right_y",
		primitive	=> 'rectangle',
		stroke		=> 'Red',
		strokewidth	=> 1,
	);

	die $result if $result;
}

# Determine the tangent of the curve at each (x, y) point
# -------------------------------------------------------
my(@derivative) = Derivative1(\@x, \@y);

for ($i = 0; $i <= $#x; $i++)
{
	$derivative[$i] = 180 * $derivative[$i] / $pi;
}

# Determine the unrotated size of the letter E
# --------------------------------------------
my(@metric) = $image -> QueryFontMetrics
(
	text		=> 'E',
	pointsize	=> 16,
	strokewidth	=> 1,
);
my($advance)		= $metric[6];
my($text_height)	= $metric[5];
my(%metric_name)	=
(
 0	=> 'character width',
 1	=> 'character height',
 2	=> 'ascender',
 3	=> 'descender',
 4	=> 'text width',
 5	=> 'text height',
 6	=> 'maximum horizontal advance',
 7	=> 'bounds.x1',
 8	=> 'bounds.y1',
 9	=> 'bounds.x2',
10	=> 'bounds.y2',
11	=> 'origin.x',
12	=> 'origin.y',
);

print map{"$metric_name{$_}: $metric[$_]. \n"} 0 .. $#metric;
print "\n";

# Plot a boxed E at each (x, y) point
# -----------------------------------
for ($i = 0; $i <= $#x; $i++)
{
	$result = $image -> Annotate
	(
		fill		=> 'Red',
	 	gravity     => 'None',
		pointsize	=> 16,
		rotate		=> 0,
		stroke		=> 'Red',
		strokewidth	=> 1,
		text		=> 'E',
		x			=> $x[$i],	# - $advance,
		'y'			=> $y[$i],
	);

	die $result if $result;

	$left_x		= $x[$i] - $metric[7];
	$left_y		= $y[$i] - $metric[8];
	$right_x	= $x[$i] + $metric[9];
	$right_y	= $y[$i] + $metric[10];
	$result		= $image -> Draw
	(
		fill		=> 'None',
		points		=> "$left_x,$left_y $right_x,$right_y",
		primitive	=> 'rectangle',
		stroke		=> 'Blue',
		strokewidth	=> 1,
	);

	die $result if $result;
}

# Plot a rotated E at each (x, y) point
# -------------------------------------
my(@rotated_metric);

for ($i = 0; $i <= $#x; $i++)
{
	@rotated_metric = $image -> QueryFontMetrics
	(
		pointsize	=> 16,
		rotate		=> $derivative[$i],
		strokewidth	=> 1,
		text		=> 'E',
	);

	print "Character: $i. \n";
	print "Tangent: $derivative[$i] degrees. \n";
	print map{"$metric_name{$_}: $rotated_metric[$_]. \n"} 0 .. $#metric;
	print "\n";

	$result = $image -> Annotate
	(
		fill		=> 'Red',
	 	gravity     => 'None',
		pointsize	=> 16,
		stroke		=> 'Red',
		strokewidth	=> 1,
		text		=> 'E',
		x			=> $x[$i],			# - $advance,
		y			=> $y[$i] + $gap,	# - int($text_height / 2)
		rotate		=> $derivative[$i],
	);

	die $result if $result;

	$left_x		= $x[$i] - $metric[7];
	$left_y		= $y[$i] - $metric[8] + $gap;
	$right_x	= $x[$i] + $metric[9];
	$right_y	= $y[$i] + $metric[10] + $gap;
	$result		= $image -> Draw
	(
		fill		=> 'None',
		points		=> "$left_x,$left_y $right_x,$right_y",
		primitive	=> 'rectangle',
		stroke		=> 'Blue',
		strokewidth	=> 1,
	);

	die $result if $result;
}

# Write the graph to disk
# -----------------------
Readonly::Scalar my $output_file_name	=> 'test.im.png';

$result = $image -> Write($output_file_name);

die $result if $result;

print "Wrote $output_file_name. \n";
print "Image depth: @{[$image -> get('depth')]} bits per pixel. \n";
print "That took @{[elapsed(time() - $start_time)]} seconds. \n";

