use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Image::DecodeQR');
    can_ok('Image::DecodeQR', 'decode');
}

