#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';

use Math::Fractal::Curve;
use Imager;

unless(@ARGV) {
	die <<HERE . <<'GENERATOR';
generator9.pl - generate fractals from the following generator as PNG images.

Usage: $0 RecursionDepth

Generator: (The X's being start- and end points of the curve)
HERE

      O
    /   \
  X       X
    \   /
      O

(The height of the diamond is 1/2 of its width.)

GENERATOR
}

# Recursion depth
my $depth = shift @ARGV;

# Filename for image.
my $filename = sprintf('Generator9-Depth%02i.png', $depth);

# Image dimensions
my $max_x = 1000;
my $max_y = 700;
my $scale = 170;

# Drawing color
my ($red, $green, $blue) = (100, 255, 100);

# Starting edge
my $starting_edge = [ [-2, 0], [2, 0] ];

#      O
#    /   \
#  X       X
#    \   /
#      O
#      
#(The height of the diamond is 1/2 of its width.)
my $generator = rotate(
	[
		[0,	0,	1/2,	1/4	],
		[1/2,	1/4,	1,	0	],
		[1,	0,	1/2,	-1/4	],
		[1/2,	-1/4,	0,	0	],
	],
	0 # radians
);

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

$img->write(file=>$filename) or
        die $img->errstr;

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

sub rotate {
	my $ary = shift;
	my $angle = shift;
	my $cos = cos $angle;
	my $sin = sin $angle;
	foreach (@$ary) {
		($_->[0], $_->[1]) = (
			$_->[0]*$cos  + $_->[1]*$sin,
			-$_->[0]*$sin + $_->[1]*$cos
		);
		($_->[2], $_->[3]) = (
			$_->[2]*$cos  + $_->[3]*$sin,
			-$_->[2]*$sin + $_->[3]*$cos
		);
	}
	return $ary;
}



