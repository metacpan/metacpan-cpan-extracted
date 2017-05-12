#!/usr/bin/perl
#
# Display an image on the LCD screen
# 
# Not a very clever or efficient way of doing it, but it works!
#

use strict;
use warnings;
use Image::Magick;
use Device::MatrixOrbital::GLK;


# Check for filename paramter
my ($filename) = @ARGV;
die "Usage: drawimg.pl <filename>\n" unless (defined $filename);


# Connect to the LCD and clear the screen
my $lcd = new Device::MatrixOrbital::GLK();
$lcd->clear_screen();



# Load the image file
my $image = new Image::Magick();
print "Reading from file: $filename\n";
$image->Read( $filename );
print "Image size: ".$image->Get('columns')."x".$image->Get('rows')."\n";

# Crop the image
my ($width, $height) = $lcd->get_lcd_dimensions();
print "Screen size: ${width}x${height}\n";
$image->Chop( 
	'x'=>0, 'y'=>0,
	'width'=>$width, 'height'=>$height
);

# Convert it to black and white
$image->Set(monochrome=>'True');

# Get the pixels
for(my $y=0; $y<$height; $y++) {
	for(my $x=0; $x<$width; $x++) {
		my $pixel = $image->Get("pixel[$x,$y]");
		if ($pixel eq '0,0,0,0') { $lcd->draw_pixel( $x, $y ) }
	}
}

