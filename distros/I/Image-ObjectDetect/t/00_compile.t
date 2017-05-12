use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Image::ObjectDetect');
    can_ok('Image::ObjectDetect', 'xs_detect');
}

