#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';

use Math::Fractal::Curve;
use Imager;

unless(@ARGV) {
	die <<HERE . <<'GENERATOR';
generator8.pl - generate fractals from the following generator as PNG images.

Usage: $0 RecursionDepth

Generator: (The X's being start- and end points of the curve)
HERE

      O
      |
  X---O---X
      |
      O

(but slightly rotated counterclockwise)

GENERATOR
}

# Recursion depth
my $depth = shift @ARGV;

# Filename for image.
my $filename = sprintf('Generator8-Depth%02i.png', $depth);

# Image dimensions
my $max_x = 1000;
my $max_y = 700;
my $scale = 170;

# Drawing color
my ($red, $green, $blue) = (0, 255, 100);

# Starting edge
my $starting_edge = [ [-2, 0], [2, 0] ];

#      O
#      |
#  X---O---X
#      |
#      O
# (but slightly rotated counterclockwise)
my $generator;
{
	my $d = 0.05;
	$generator =
	[
		[0,	0-$d,	1/2,	0	],
		[1/2,	0,	1,	0+$d	],
		[1/2,	0,	1/2-$d,	1/2	],
		[1/2,	0,	1/2+$d,	-1/2	],
	]
}

# ====================
# End of Configuration
# ====================

# New curve generator
my $curve_gen = Math::Fractal::Curve->new(generator => $generator);

# New curve
my $curve = $curve_gen->line(
	start => $starting_edge->[0],
	end   => $starting_edge->[1],
);

my $img = Imager->new(xsize => $max_x, ysize => $max_y);
my $color = Imager::Color->new( $red, $green, $blue );

recur_draw($curve, $depth);

# All this magic just to keep the memory footprint low!
sub recur_draw {
	my $curve = shift;
	my $depth = shift;

	if ($depth <= 1) {
		my $edges = $depth==1 ? $curve->edges() : 
			[ [@{$curve->{start}}, @{$curve->{end}}] ];

		foreach (@$edges) {
			$img->line(
				color => $color,
				x1 => $max_x/2 + $_->[0] * $scale,
				y1 => $max_y/2 - $_->[1] * $scale,
				x2 => $max_x/2 + $_->[2] * $scale,
				y2 => $max_y/2 - $_->[3] * $scale,
			);
		}
	}
	else {
		my $curves = $curve->recurse();
		foreach (@$curves) {
			recur_draw($_, $depth-1);
		}
	}
}


$img->write(file=>$filename) or
        die $img->errstr;

