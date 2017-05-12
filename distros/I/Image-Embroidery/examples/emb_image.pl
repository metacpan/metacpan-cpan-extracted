#!/usr/bin/env perl

# this is a simple example demonstrating how to use Image::Embroidery
# and GD to create a PNG image file displaying an embroidery pattern.
# Just run it with the file name of the pattern, and it will create a
# PNG with the same name. For example:
#
# $ perl emb_image.pl emb_pattern.dst
# 
# will create a new file called emb_pattern.png.
# 

use Image::Embroidery;
use GD;
use strict;
use warnings;

my $emb = Image::Embroidery->new;

# try to figure out the file type from the extension, and get the
# file name to use for the output image file
my ($filename, $type) = ($ARGV[0] =~ /^(.*)\.([^\.]+)$/);

# read in the pattern file
$emb->read_file($ARGV[0], $type) or die "Unable to read $ARGV[0]\n";

# create a new image. The call to $emb->size will return
# the dimension of the pattern.
my $im = new GD::Image( $emb->size );

# allocate some colors. The first color allocated will be the background
my @all_colors = (
	$im->colorAllocate(hex(12), hex(34), hex(56)), # medium blue
	$im->colorAllocate(hex(22), hex(22), hex(22)), # dark gray
	$im->colorAllocate(hex(00), hex(00), hex(00)), # black
	$im->colorAllocate(hex('cc'), hex('cc'), hex('cc')), # off white
	$im->colorAllocate(hex('ff'), hex(56), hex(11)), # orange
	$im->colorAllocate(255,0,0), # red
	$im->colorAllocate(80,0,0), # dark red
	$im->colorAllocate(10,150,10), # green
	$im->colorAllocate(0,80,0), # dark green
	$im->colorAllocate(255,255,0), # yellow
	$im->colorAllocate(0,0,255), # blue
	$im->colorAllocate(200, 100, 50), # tan
	$im->colorAllocate(128,128,128), # gray
);

# thicker lines make the image look nicer, thinner lines will let
# you see where the stitches run
$im->setThickness(5);
$im->interlaced('true');

my $number_of_colors = $emb->get_color_count;

# the colors in the order they appear in the pattern
my @colors;

# add as many colors as we need to the color list
foreach my $i (1..$number_of_colors) {
	push(@colors, $all_colors[ $i % $#all_colors ]);
}

# draw the image in memory
my $success = $emb->draw_logo($im, @colors);
unless($success) {
	print "Something went wrong\n";
}

# write the image out to a file
open(F, ">$filename.png");
print F $im->png;
close(F);
