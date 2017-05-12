use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Image::TextMode::Format::PCBoard' );
is_deeply( [ sort Image::TextMode::Format::PCBoard->extensions ],
    [ qw( pcb ) ], 'extensions' );
