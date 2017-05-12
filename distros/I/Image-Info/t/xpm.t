#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
BEGIN
   {
   plan tests => 9;
   chdir 't' if -d 't';
   use lib '../lib';
   use lib '../blib';
   use_ok ("Image::Info") or die $@;
   };

use Image::Info qw(image_info dim);

SKIP: {
skip 'Image::Xpm needed for the test', 8 unless eval { require Image::Xpm };

my $i = image_info("../img/test.xpm")
 || die ("Couldn't read test.xpm: $!");

# use Data::Dumper; print Dumper($i), "\n";

is ($i->{ColorResolution}, 8, 'ColorResoltuion');
is ($i->{BitsPerSample}, 8, 'BitsPerSample');
is ($i->{SamplesPerPixel}, 1, 'SamplesPerPixel');
is ($i->{file_media_type}, 'image/x-xpixmap', 'media type');
is ($i->{ColorTableSize}, 2, '2 colors');
is ($i->{color_type}, 'Indexed-RGB', 'color_type');
is ($i->{file_ext}, 'xpm', 'file_ext');

is (dim($i), '127x13', 'dim()');
}
