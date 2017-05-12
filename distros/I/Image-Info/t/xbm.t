#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
BEGIN
   {
   plan tests => 8;
   chdir 't' if -d 't';
   use lib '../lib';
   use lib '../blib';
   use_ok ("Image::Info") or die $@;
   };

use Image::Info qw(image_info dim);

SKIP: {
skip 'Image::Xbm needed for the test', 7 unless eval { require Image::Xbm };

my $i = image_info("../img/test.xbm")
 || die ("Couldn't read test.xbm: $!");

# use Data::Dumper; diag Dumper($i), "\n";

is ($i->{BitsPerSample}, 1, 'BitsPerSample');
is ($i->{SamplesPerPixel}, 1, 'SamplesPerPixel');
is ($i->{file_media_type}, 'image/x-xbitmap', 'media type');
is ($i->{ColorTableSize}, 2, '2 colors');
is ($i->{color_type}, 'Grey', 'color_type');
is ($i->{file_ext}, 'xbm', 'file_ext');

is (dim($i), '6x6', 'dim()');
}
