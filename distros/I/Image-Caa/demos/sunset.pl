#!/usr/bin/perl -w

use lib '../lib';
use strict;
use Image::Caa;
use Image::Magick;
use Term::ReadKey;


#
# load the image
#

my $image = Image::Magick->new;

my $x = $image->Read('sunset.jpg');

warn "$x" if "$x";


#
# get screen size
#

my ($sw, $sh) = GetTerminalSize;


#
# create the caa
#

my $caa = new Image::Caa();
$caa->draw_bitmap(0, 0, $sw-2, $sh-5, $image);


print "Photo by Patrick Guyennon\n";
print "http://flickr.com/photos/indeepdark/117165513/\n";
