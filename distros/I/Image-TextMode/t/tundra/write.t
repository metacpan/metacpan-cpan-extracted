use strict;
use warnings;

use Test::More tests => 6;

use_ok( 'Image::TextMode::Format::Tundra' );

{
    my $file   = 'test1.tnd';
    my $tundra = Image::TextMode::Format::Tundra->new;
    $tundra->read( "t/tundra/data/${file}" );

    isa_ok( $tundra, 'Image::TextMode::Format::Tundra' );

    my $output;
    open( my $fh, '+<', \$output );
    $tundra->write( $fh );

    my $tundra2 = Image::TextMode::Format::Tundra->new;
    seek( $fh, 0, 0 );
    $tundra2->read( $fh );
    close( $fh );

    is_deeply( $tundra2->header, $tundra->header, 'roundtrip write()' );
    is_deeply( $tundra2->font,   $tundra->font,   'roundtrip write()' );

TODO: {
        local $TODO = 'palette and pixel data is not yet roundtrip exact';
        is_deeply( $tundra2->palette, $tundra->palette, 'roundtrip write()' );
        is_deeply( $tundra2->pixeldata, $tundra->pixeldata,
            'roundtrip write()' );
    }
}
