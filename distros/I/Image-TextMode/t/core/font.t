use Test::More tests => 5;

use strict;
use warnings;

use_ok( 'Image::TextMode::Font' );

{
    my $f = Image::TextMode::Font->new(
        width  => 8,
        height => 8,
        chars  => [ [ ( 255 ) x 8 ], ],
    );

    isa_ok( $f, 'Image::TextMode::Font' );
    is( $f->width,  8, 'width' );
    is( $f->height, 8, 'height' );
    is_deeply( $f->chars, [ [ ( 255 ) x 8 ] ], 'chars' );
}
