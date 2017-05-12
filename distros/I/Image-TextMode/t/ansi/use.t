use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Image::TextMode::Format::ANSI' );
is_deeply( [ sort Image::TextMode::Format::ANSI->extensions ],
    [ qw( ans cia ice ) ], 'extensions' );
