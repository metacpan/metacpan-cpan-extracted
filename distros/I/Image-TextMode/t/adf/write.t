use strict;
use warnings;

use Test::More tests => 6;

use_ok( 'Image::TextMode::Format::ADF' );

{
    my $file = 'test1.adf';
    my $adf  = Image::TextMode::Format::ADF->new;
    $adf->read( "t/adf/data/${file}" );

    isa_ok( $adf, 'Image::TextMode::Format::ADF' );

    my $output;
    open( my $fh, '+<', \$output );
    $adf->write( $fh );

    my $adf2 = Image::TextMode::Format::ADF->new;
    seek( $fh, 0, 0 );
    $adf2->read( $fh );
    close( $fh );

    is_deeply( $adf2->header,    $adf->header,    'roundtrip write()' );
    is_deeply( $adf2->font,      $adf->font,      'roundtrip write()' );
    is_deeply( $adf2->palette,   $adf->palette,   'roundtrip write()' );
    is_deeply( $adf2->pixeldata, $adf->pixeldata, 'roundtrip write()' );
}

