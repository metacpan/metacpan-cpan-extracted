use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Image::TextMode::Format::XBin' );
is_deeply( [ sort Image::TextMode::Format::XBin->extensions ],
    [ qw( xb xbin ) ], 'extensions' );
