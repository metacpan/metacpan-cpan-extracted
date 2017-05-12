use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Image::TextMode::Format::Bin' );
is_deeply( [ sort Image::TextMode::Format::Bin->extensions ],
    [ 'bin' ], 'extensions' );
