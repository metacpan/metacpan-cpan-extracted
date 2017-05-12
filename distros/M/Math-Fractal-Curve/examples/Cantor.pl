#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';

use Math::Fractal::Curve;
use Imager;

unless(@ARGV) {
	die <<HERE . <<'GENERATOR';
cantor.pl - generate a Cantor fractal as a PNG image.

Usage: $0 RecursionDepth

Generator: (The X's being start- and end points of the curve)
HERE

  X---O   O---X

GENERATOR
}

my $depth = shift @ARGV;

# Filename for image.
my $filename = sprintf('Cantor-Depth%02i.png', $depth);

#      O---O
#      |   |
#  X---O   O   O---X
#          |   |
#          O---O
my $generator = [
	[0,	0,	1/3,	0	],
	[2/3,	0,	1,	0	],
];

# New curve generator
my $curve_gen = Math::Fractal::Curve->new(generator => $generator);

# New curve
my $curve = $curve_gen->line(
	start => [-2, 0],
	end   => [2, 0],
);


# Image dimensions
my $max_x = 2500;
my $max_y = 20;

my $img = Imager->new(xsize => $max_x, ysize => $max_y);

my $edges = $curve->fractal($depth);

my $color = Imager::Color->new( 255, 0, 0);

# Scale dimensions by 200.
@$_ = map $_*600, @$_ foreach @$edges;

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

