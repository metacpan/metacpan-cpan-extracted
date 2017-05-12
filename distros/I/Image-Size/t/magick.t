#!/usr/bin/perl -w

# Tests related to Image::Magick and Graphics::Magick

use Test::More;

use Image::Size;

plan tests => 1;

# This test should work whether or not Image::Magick is installed. 
ok(!(exists $INC{'Image/Magick.pm'}),
   'Image::Magick should not be loaded until it is needed if it available')
    || diag "Image::Magick loaded at:  $INC{'Image/Magick.pm'}";
