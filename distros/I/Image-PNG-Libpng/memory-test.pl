#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::PNG::Libpng;
use MIME::Base64;

for (0..10**6) {
    test ();
}

sub test {
my $imgdata = decode_base64('iVBORw0KGgoAAAANSUhEUgAAABwAAAAMAQMAAABLFU9MAAAABlBMVEX///8AAABVwtN+AAAALklEQVQImWNgQAMJzAcYGB6wJTAwJrAxMPxJYD8AJIBcBghxDCjx8zFQCcMBBgAD6gxf0rCeqgAAAABJRU5ErkJggg==');
my $png = Image::PNG::Libpng::read_from_scalar($imgdata);
my $IHDR = $png->get_IHDR();
}
