# Get the user's libpng version string.

# This is so it's possible to see what version of libpng is in use in
# cpan testers reports which don't contain enough information.

use warnings;
use strict;
use Test::More;
use Image::PNG::Libpng ':all';
plan skip_all => "libpng version is " . get_libpng_ver () if 1;
ok (1);
done_testing ();
