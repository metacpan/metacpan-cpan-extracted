#!/usr/bin/perl -w

# Test the same TIFF file in little and big endian

use Test::More;
use strict;

BEGIN
  {
  chdir 't' if -d 't';
  use lib '../blib/';
  use lib '../lib/';
  plan tests => 10;
  }

use Image::Info qw(image_info);

##
## TIFF Little Endian file
##

my @le = image_info("../img/le.tif");
ok ( @le, 'TIFF Little Endian: image_info ran ok');
is ( @le, 1, 'One image found' );

is ( $le[0]->{SamplesPerPixel}, 4, 'SamplesPerPixel is 4' );
is ( $le[0]->{width}, 260, 'Width is right for the image');
is ( $le[0]->{height}, 6, 'Height is right for the image');

##
## TIFF Big Endian file
##

my @be = image_info("../img/be.tif");
ok ( @be, 'TIFF Big Endian: image_info ran ok');
is ( @be, 1, 'One image found' );

is ( $be[0]->{SamplesPerPixel}, 4, 'SamplesPerPixel is 4' );
is ( $be[0]->{width}, 260, 'Width is right for the image');
is ( $be[0]->{height}, 6, 'Height is right for the image');

1;

