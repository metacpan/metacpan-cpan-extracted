#!/usr/bin/perl -w

use Test::More;
use strict;

# test PNG files

BEGIN
   {
   plan tests => 19;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Image::Info") or die($@);
   };

use Image::Info qw(image_info dim);

my $i = image_info("../img/test.png") ||
  die ("Couldn't read test.png: $!");

is ($i->{color_type}, 'Indexed-RGB', 'color_type');
is ($i->{LastModificationTime}, "2006-07-16 12:28:31", 'LastModificationTime');
is ($i->{file_ext}, 'png', 'png');
is ($i->{file_media_type}, 'image/png', 'media_type');
is ($i->{SampleFormat}, 'U4', 'SampleFormat');

is (dim($i), '150x113', 'dim()');

is_deeply ( $i->{ColorPalette}, 
  [ '#171617', '#c8ced6', '#8d929b', '#75787f', '#565961', '#2f3033', '#fefefd',
    '#613e2f', '#a6acb6', '#e6ecf2', '#40464d', '#805d4b' ], 'ColorPalette' );

#############################################################################
# interlace test

$i = image_info("../img/interlace.png") ||
  die ("Couldn't read interlace.png: $!");

is ($i->{color_type}, 'RGB', 'color_type');
is ($i->{LastModificationTime}, "2006-07-16 12:32:43", 'LastModificationTime');
is ($i->{SampleFormat}, 'U8', 'SampleFormat');
is ($i->{Interlace}, 'Adam7', 'Interlace');
is ($i->{Compression}, 'Deflate', 'Compression');
is ($i->{PNG_Filter}, 'Adaptive', 'PNG_Filter');
is ($i->{file_ext}, 'png', 'png');
is ($i->{file_media_type}, 'image/png', 'media_type');
is ($i->{Comment}, 'Created with The GIMP', 'Comment');

is (dim($i), '200x100', 'dim()');

#############################################################################
# ztxt test
SKIP:
    {
       skip 'Need Compress::Zlib for this ztxt test', 1
	   if !eval { require Compress::Zlib; 1 };

       # Used to emit warnings (https://rt.cpan.org/Ticket/Display.html?id=28054)
       $i = image_info("../img/ztxt.png") ||
	   die ("Couldn't read ztxt.png: $!");
       is ($i->{comment}, "some image comment\n", 'ztxt comment');
    }
