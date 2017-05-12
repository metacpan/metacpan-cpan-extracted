#!/usr/bin/perl -w

use Test::More;
use strict;

# test dim(), html_dim() and image_info()

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Image::Info") or die($@);
   };

use Image::Info qw(image_info);

my $h = image_info("../img/tiny.pgm")
  || die ("Cannot read tiny.pgm: $!");

#use Data::Dumper; print STDERR "# ", Data::Dumper::Dumper($h), "\n";

is ($h->{file_media_type}, "image/pgm", 'file_media_type');

is ($h->{width}, 1, 'width=1');
is ($h->{height}, 1, 'height=1');

{
  my $ppm16data = "P6 1 1 65535\nxxxxxx";
  my $i = image_info(\$ppm16data);
  ok($i, "read 16-bit/sample ppm");
  is_deeply ($i->{BitsPerSample}, [ 16, 16, 16 ], "BitsPerSample=16,16,16");
  is ($i->{SamplesPerPixel}, 3, "SamplesPerPixel=3");
}

