use warnings;
use strict;
use Test::More tests => 3;

BEGIN { use_ok ('Image::PNG::Const'); };

use Image::PNG::Const ':all';

ok (PNG_COLOR_MASK_ALPHA == 4, "Got a test constant");
ok (PNG_COLOR_TYPE_RGBA == 6, "Test an or'd constant");
