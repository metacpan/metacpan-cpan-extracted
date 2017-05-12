use strict;
use warnings;

use Test::More tests => 6;

use_ok( 'Image::TextMode::Format::IDF' );

{
    my $file = 'test1.idf';
    my $idf  = Image::TextMode::Format::IDF->new;
    $idf->read( "t/idf/data/${file}" );

    isa_ok( $idf, 'Image::TextMode::Format::IDF' );

    my $output;
    open( my $fh, '+<', \$output );
    $idf->write( $fh );

    my $idf2 = Image::TextMode::Format::IDF->new;
    seek( $fh, 0, 0 );
    $idf2->read( $fh );
    close( $fh );

    is_deeply( $idf2->header,    $idf->header,    'roundtrip write()' );
    is_deeply( $idf2->font,      $idf->font,      'roundtrip write()' );
    is_deeply( $idf2->palette,   $idf->palette,   'roundtrip write()' );
    is_deeply( $idf2->pixeldata, $idf->pixeldata, 'roundtrip write()' );
}

