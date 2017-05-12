#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';

use Math::Fractal::Curve;
use Imager;

unless(@ARGV) {
	die <<HERE;
generator1.pl - generate fractals from the following generator as PNG images.

Usage: $0 RecursionDepth

Generator: (The X's being start- and end points of the curve)

    O
    |
 X--O--O--X
       |
       O

HERE
}

my $depth = shift @ARGV;

# Filename for image.
my $filename = sprintf('Generator1-Depth%02i.png', $depth);

#    O
#    |
# O--O--O--O
#       |
#       O
my $generator = [
	[0,	0,	1/3,	0	],
	[1/3,	0,	2/3,	0	],
	[2/3,	0,	1,	0	],

	[1/3,	0,	1/3,	1/3	],
	[2/3,	0,	2/3,	-1/3	],
];

# New curve generator
my $curve_gen = Math::Fractal::Curve->new(generator => $generator);

# New curve
my $curve = $curve_gen->line(
	start => [-2, 0],
	end   => [2, 0],
);


# Image dimensions
my $max_x = 1000;
my $max_y = 600;

my $img = Imager->new(xsize => $max_x, ysize => $max_y);

my $edges = $curve->fractal($depth);

my $color = Imager::Color->new( 255, 255, 0 );

# Scale dimensions by 200.
@$_ = map $_*200, @$_ foreach @$edges;

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

