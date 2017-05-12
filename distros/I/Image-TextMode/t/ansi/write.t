use strict;
use warnings;

use Test::More tests => 5;

$ENV{ IMAGE_TEXTMODE_NOXS } = 1;

use_ok( 'Image::TextMode::Format::ANSI' );

{
    my $file = 'test1.ans';
    my $ansi = Image::TextMode::Format::ANSI->new;
    $ansi->read( "t/ansi/data/${file}" );

    isa_ok( $ansi, 'Image::TextMode::Format::ANSI' );

    my $output;
    open( my $fh, '+<', \$output );
    $ansi->write( $fh );

    my $ansi2 = Image::TextMode::Format::ANSI->new;
    seek( $fh, 0, 0 );
    $ansi2->read( $fh );
    close( $fh );

    is_deeply( $ansi2->font,      $ansi->font,      'roundtrip write()' );
    is_deeply( $ansi2->palette,   $ansi->palette,   'roundtrip write()' );
    is_deeply( $ansi2->pixeldata, $ansi->pixeldata, 'roundtrip write()' );
}
