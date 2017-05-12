#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  chdir 't' if -d 't';
  use lib '../blib/';
  use lib '../lib/';
  plan tests => 19;
  }

use Image::Info qw(image_info dim);

## This TIFF file has 3 images, in 24-bit colour, 1-bit mono and 8-bit grey.
my @i = image_info("../img/test.tif");
ok ( @i, 'image_info ran ok');
is ( @i, 3, 'Right number of images found' );

## First image
is ( scalar @{$i[0]->{BitsPerSample}}, 3 , 'Three lots of BitsPerSample for full-colour image' );
is ( $i[0]->{SamplesPerPixel}, 3, 'SamplesPerPixel is 3 for full-colour image' );
is ( $i[0]->{width}, 60, 'width is right for full-colour image');
is ( $i[0]->{height}, 50, 'height is right for full-colour image');

my $soft_text = "ImageMagick 6.0.6 01/25/06 Q16 http://www.imagemagick.org";
if ( $i[0]->{Software} eq $soft_text ) {
  ok (1, "Software text tag read correctly" );
} else {
  ok (0, "Software text tag read correctly" );
  my @tagc = split //,$i[0]->{Software};
  my @tstc = split //,$soft_text;
  printf "Tag string is %d characters, Test string is %d characters\n", scalar(@tagc), scalar(@tstc);
  for (my $i = 0; defined $tagc[$i] or defined $tstc[$i]; $i++) {
    $tagc[$i] = '[undef]' if ! defined $tagc[$i];
    $tstc[$i] = '[undef]' if ! defined $tstc[$i];
    if ($tagc[$i] ne $tstc[$i]) {
      warn sprintf("Strings differ at offset $i (expected: %s / found: %s)\n", $tagc[$i], $tstc[$i]);
    }
  }
}

{
  my($xres,$yres) = ($i[0]->{XResolution}, $i[0]->{YResolution});
  isa_ok $xres, 'Image::TIFF::Rational';
  isa_ok $yres, 'Image::TIFF::Rational';
  is "$xres", "1207959552/16777216", 'XResolution, stringified';
  is "$yres", "1207959552/16777216", 'YResolution, stringified';
}

## Second image
is ( $i[1]->{BitsPerSample}, 1, 'BitsPerSample right for 1-bit image' );
is ( $i[1]->{SamplesPerPixel},  1, 'BitsPerSample right for 1-bit image' );
is ( $i[1]->{Compression}, 'CCITT T6', 'Compression right for 1-bit image' );
is ( $i[1]->{DocumentName}, "bb1bit.tif", "DocumentName text tag read correctly" );

## Third image
is ( $i[2]->{BitsPerSample}, 8,  'Bit depth right for greyscale image' );
is ( $i[2]->{SamplesPerPixel}, 1, 'Bit depth right for greyscale image' );
is ( dim($i[2]), '60x50' , 'dim() function is right for greyscale image' );
is ( $i[2]->{ImageDescription}, "Created with The GIMP", "ImageDescription text tag read correctly" );

1;

