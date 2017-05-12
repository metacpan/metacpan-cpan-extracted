use strict;
use warnings;
use Image::libsiftfast;
use Test::More tests => 3;

my $sift = Image::libsiftfast->new;
can_ok($sift, "new");
can_ok($sift, "extract_keypoints");
can_ok($sift, "convert_to_pnm");