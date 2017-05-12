use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Image::TextMode::Format::IDF' );
is_deeply( [ sort Image::TextMode::Format::IDF->extensions ],
    [ 'idf' ], 'extensions' );
