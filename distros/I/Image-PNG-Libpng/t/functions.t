# Test misc. functions.

use warnings;
use strict;
use Test::More;
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';
use FindBin '$Bin';
# Bad city, bad bad city, fat city bad.
my $png = read_png_file ("$Bin/tantei-san.png");
is ($png->height (), 281);
is ($png->width (), 293);
is ($png->get_channels (), 1);
is ($png->get_bit_depth (), 8);
# You get up in the morning at the cracking of dawn, you hustle and
# you hassle all day. The things that a man has to do for a living,
# just to keep the reaper away.
cmp_ok ($png->get_color_type, '==', PNG_COLOR_TYPE_PALETTE, "color type");
cmp_ok ($png->get_interlace_type, '==', PNG_INTERLACE_NONE, "interlace type");
done_testing ();
