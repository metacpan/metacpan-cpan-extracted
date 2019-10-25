#!/usr/bin/perl -w

use strict;
use FindBin;
use Test::More;

use Image::Info qw(image_info);

plan tests => 21;

my $img_dir = "$FindBin::RealBin/../img";

my $i = image_info("$img_dir/test.webp") ||
  die ("Couldn't read test.webp: $!");

is ($i->{file_ext}, 'webp', 'WebP');
is ($i->{file_media_type}, 'image/webp', 'media_type');
is ($i->{Compression}, 'VP8', 'lossy compression');
is ($i->{width}, 320, 'width');
is ($i->{height}, 240, 'height');

$i = image_info("$img_dir/test-lossless.webp") ||
  die ("Couldn't read test-lossless.webp: $!");

is ($i->{file_ext}, 'webp', 'WebP');
is ($i->{file_media_type}, 'image/webp', 'media_type');
is ($i->{Compression}, 'Lossless', 'lossless compression');
is ($i->{width}, 150, 'width');
is ($i->{height}, 113, 'height');

$i = image_info("$img_dir/test-exif.webp") ||
  die ("Couldn't read test-exif.webp: $!");

is ($i->{file_ext}, 'webp', 'WebP');
is ($i->{file_media_type}, 'image/webp', 'media_type');
is ($i->{Compression}, 'VP8', 'lossy compression');
is ($i->{width}, 320, 'width');
is ($i->{height}, 240, 'height');

# Note that this file has a length header where one octet is 0x0A, meaning that
# it will fail the file magic test if the //s flag is removed from the regex.
$i = image_info("$img_dir/anim.webp") ||
  die ("Couldn't read test-exif.webp: $!");

is ($i->{file_ext}, 'webp', 'WebP');
is ($i->{file_media_type}, 'image/webp', 'media_type');
is ($i->{Animation}, 1, 'animation');
is ($i->{Compression}, undef, 'no compression given for animations');
is ($i->{width}, 1, 'width');
is ($i->{height}, 1, 'height');
