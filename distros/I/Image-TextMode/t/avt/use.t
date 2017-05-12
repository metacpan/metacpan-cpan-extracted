use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Image::TextMode::Format::AVATAR' );
is_deeply( [ sort Image::TextMode::Format::AVATAR->extensions ],
    [ qw( avt ) ], 'extensions' );
