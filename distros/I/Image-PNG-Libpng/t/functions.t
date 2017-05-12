# Test misc. functions.

use warnings;
use strict;
use Test::More;
use Image::PNG::Libpng ':all';
use FindBin;
my $png = read_png_file ("$FindBin::Bin/tantei-san.png");
is ($png->height (), 281);
is ($png->width (), 293);
is ($png->get_channels (), 1);
is ($png->get_bit_depth (), 8);
done_testing ();
