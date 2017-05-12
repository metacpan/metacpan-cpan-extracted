use strict;
use warnings;

use Test::More tests => 5;

$ENV{ IMAGE_TEXTMODE_NOXS } = 1;

use_ok( 'Image::TextMode::Format::ANSIMation' );

{
    my $file = 'ansimation1.ans';
    my $ansi = Image::TextMode::Format::ANSIMation->new;
    $ansi->read( "t/ansimation/data/${file}" );

    isa_ok( $ansi, 'Image::TextMode::Format::ANSIMation' );

    my $output;
    open( my $fh, '+<', \$output );
    $ansi->write( $fh );

    my $ansi2 = Image::TextMode::Format::ANSIMation->new;
    seek( $fh, 0, 0 );
    $ansi2->read( $fh );
    close( $fh );

    is_deeply( $ansi2->font,    $ansi->font,    'roundtrip write()' );
    is_deeply( $ansi2->palette, $ansi->palette, 'roundtrip write()' );
    is_deeply( $ansi2->frames,  $ansi->frames,  'roundtrip write()' );
}
