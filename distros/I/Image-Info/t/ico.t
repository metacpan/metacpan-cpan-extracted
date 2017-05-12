#!/usr/bin/perl -w

use strict;
use FindBin;
use Test::More;

plan tests => 5;

use Image::Info qw(image_info dim);

my(@i) = image_info("$FindBin::RealBin/../img/test.ico")
    or die "Couldn't read test.ico: $!";

#use Data::Dumper; print Dumper(\@i), "\n";

is($i[0]->{file_ext}, 'ico', 'ext');
is($i[0]->{file_media_type}, 'image/x-icon', 'media type');
is($i[0]->{colors}, 256);
is(dim($i[0]), '24x24', 'dim() of first image');
is(dim($i[1]), '16x16', 'dim() of second image');
