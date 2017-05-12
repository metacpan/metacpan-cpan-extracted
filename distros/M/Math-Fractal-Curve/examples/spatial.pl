#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';

use Math::Fractal::Curve;
use Imager;

unless(@ARGV) {
	die <<HERE;
spatial.pl - generate spacially-dependent "fractal" curves.
(That means the generator functions depends on the distance it
is applied to. In this case, it only depends on its orientation.)

This example is a von Koch-curve whose excavation-direction depends
on the orientation of the distance the generator is applied to.

Usage: $0 RecursionDepth

HERE
}

my $depth = shift @ARGV;

# Filename for image.
my $filename = sprintf('Spatial-Depth%02i.png', $depth);

my $generator = sub {
	my $dist = shift;
	my $start = $dist->{start};
	my $end = $dist->{end};
	my $vec = [$end->[0]-$start->[0], $end->[1]-$start->[1]];
	my $len = sqrt($vec->[0]**2 + $vec->[1]**2);
	my $sin = $vec->[1]/$len;
	my $cos = $vec->[0]/$len;

	my $sign = 1;
	$sign = -1 if $cos*$sin < 0;
	[
		[0,   0,               1/3, 0              ],
		[1/3, 0,               1/2, $sign*sqrt(5)/6],
		[1/2, $sign*sqrt(5)/6, 2/3, 0              ],
		[2/3, 0,               1,   0              ],
	]
};
	
# New curve generator
my $curve_gen = Math::Fractal::Curve->new(generator => $generator);

# New curve
my $curve = $curve_gen->line(
	start => [-2, 0],
	end   => [2, 0],
);


# Image dimensions
my $max_x = 1000;
my $max_y = 700;

my $img = Imager->new(xsize => $max_x, ysize => $max_y);

my $edges = $curve->fractal($depth);

my $color = Imager::Color->new( 0, 0, 255 );

# Scale dimensions by 200.
@$_ = map $_*170, @$_ foreach @$edges;

foreach (@$edges) {
	$img->line(
		color => $color,
		x1 => $max_x/2 + $_->[0],
		y1 => $max_y/2 - $_->[1],
		x2 => $max_x/2 + $_->[2],
		y2 => $max_y/2 - $_->[3],
	);
}

$img->write(file=>$filename) or
        die $img->errstr;

