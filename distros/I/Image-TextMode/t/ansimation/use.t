use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Image::TextMode::Format::ANSIMation' );
ok( !defined Image::TextMode::Format::ANSIMation->extensions, 'extensions' );
