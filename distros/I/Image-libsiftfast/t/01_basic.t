use strict;
use warnings;
use Image::libsiftfast;
use Test::More tests => 1;

my $sift = Image::libsiftfast->new;
isa_ok($sift, "Image::libsiftfast");