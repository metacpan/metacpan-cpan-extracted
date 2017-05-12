use strict;
use warnings;

use Test::More tests => 11;

use_ok( 'Image::TextMode::Pixel' );

# iCEColor: on (aka blink_mode: off)
{
    my $pixel = Image::TextMode::Pixel->new( char => 'x', attr => 255 );
    isa_ok( $pixel, 'Image::TextMode::Pixel' );
    is( $pixel->char,  'x', 'char' );
    is( $pixel->fg,    15,  'fg' );
    is( $pixel->bg,    15,  'bg' );
    is( $pixel->blink, 0,   'blink' );
}

# iCEColor: off (aka blink_mode: on)
{
    my $pixel = Image::TextMode::Pixel->new(
        char => 'x',
        attr => 255,
        { blink_mode => 1 }
    );
    isa_ok( $pixel, 'Image::TextMode::Pixel' );
    is( $pixel->char,  'x', 'char' );
    is( $pixel->fg,    15,  'fg' );
    is( $pixel->bg,    7,   'bg' );
    is( $pixel->blink, 1,   'blink' );
}
