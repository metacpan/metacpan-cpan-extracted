use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Image::TextMode::Format::Tundra' );
is_deeply( [ sort Image::TextMode::Format::Tundra->extensions ],
    [ 'tnd' ], 'extensions' );
