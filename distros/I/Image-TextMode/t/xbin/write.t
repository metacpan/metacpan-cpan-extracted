use strict;
use warnings;

use Test::More tests => 6;

use_ok( 'Image::TextMode::Format::XBin' );

{
    my $file = 'test1.xb';
    my $xbin = Image::TextMode::Format::XBin->new;
    $xbin->read( "t/xbin/data/${file}" );

    isa_ok( $xbin, 'Image::TextMode::Format::XBin' );

    my $output;
    open( my $fh, '+<', \$output );
    $xbin->write( $fh );

    my $xbin2 = Image::TextMode::Format::XBin->new;
    seek( $fh, 0, 0 );
    $xbin2->read( $fh );
    close( $fh );

    is_deeply( $xbin2->header,    $xbin->header,    'roundtrip write()' );
    is_deeply( $xbin2->font,      $xbin->font,      'roundtrip write()' );
    is_deeply( $xbin2->palette,   $xbin->palette,   'roundtrip write()' );
    is_deeply( $xbin2->pixeldata, $xbin->pixeldata, 'roundtrip write()' );
}

