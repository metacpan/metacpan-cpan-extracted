#!/usr/bin/perl -w

use Image::Magick::Brand;
my $b = new Image::Magick::Brand;

$b->debug(1);

$b->brand( source => "logo.png",
           target => "photo.jpg",
           output => "branded.jpg" );

print "\nOpen branded.jpg. If the logo is located on the lower left hand corner of the photo then everything should be 
working.\n";
