use Test::More tests => 3;

use strict;
use warnings;

use_ok( 'Image::TextMode::Palette' );

{
    my $p = Image::TextMode::Palette->new( colors => [ [ ( 255 ) x 3 ], ], );

    isa_ok( $p, 'Image::TextMode::Palette' );
    is_deeply( $p->colors, [ [ ( 255 ) x 3 ] ], 'colors' );
}
