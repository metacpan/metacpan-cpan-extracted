# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 27;
BEGIN { use_ok('Image::LibRSVG') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $rsvg = new Image::LibRSVG();

open( FILE, "< examples/artscontrol.svg" );
my $content = join "", <FILE>;
close( FILE );

ok( defined $rsvg );

## convert
ok( $rsvg->convert( "examples/artscontrol.svg", "examples/test.png" ) );
ok( ! $rsvg->convert( "examples/artscontrol.sv", "examples/test.png" ) );
ok( $rsvg->loadFromString( $content ) );

## convertAtZoom
ok( $rsvg->convertAtZoom( "examples/artscontrol.svg", "examples/test.png", 1.5, 1.5 ) );
ok( ! $rsvg->convertAtZoom( "examples/artscontrol.sv", "examples/test.png", 1.5, 1.5 ) );
ok( $rsvg->loadFromStringAtZoom( $content, 1.5, 1.5 ) );

## convertAtMaxSize
ok( $rsvg->convertAtMaxSize( "examples/artscontrol.svg", "examples/test.png", 200, 300 ) );
ok( ! $rsvg->convertAtMaxSize( "examples/artscontrol.sv", "examples/test.png", 200, 300 ) );
ok( $rsvg->loadFromStringAtMaxSize( $content, 200, 300 ) );

## convertAtSize
ok( $rsvg->convertAtSize( "examples/artscontrol.svg", "examples/test.png", 200, 300 ) );
ok( ! $rsvg->convertAtSize( "examples/artscontrol.sv", "examples/test.png", 200, 300 ) );
ok( $rsvg->loadFromStringAtSize( $content, 200, 300 ) );

## convertAtZoomWithMax
ok( $rsvg->convertAtZoomWithMax( "examples/artscontrol.svg", "examples/test.png", 1.5, 1.5, 200, 300 ) );
ok( ! $rsvg->convertAtZoomWithMax( "examples/artscontrol.sv", "examples/test.png", 1.5, 1.5, 200, 300 ) );
ok( $rsvg->loadFromStringAtZoomWithMax( $content, 1.5, 1.5, 200, 300 ) );

## loading & saving
ok( $rsvg->loadImage( "examples/artscontrol.svg" ) );
ok( $rsvg->saveAs( "examples/test.png" ) );

## get pictures as scalar
ok( $rsvg->getImageBitmap() );

## check when loading fails
ok( ! $rsvg->loadImage( "examples/artscontrol.sv" ) );
ok( ! $rsvg->saveAs( "examples/test.png" ) );

## if we use z-lib let's give it a try
if( Image::LibRSVG->isGzCompressionSupported() ) {
    ok( $rsvg->loadImage( "examples/artscontrol.svg.gz" ) );
    ok( $rsvg->saveAs( "examples/test.png" ) );
} else {
    ok(1);
    ok(1);
}

## formats
ok( ref( Image::LibRSVG->getKnownFormats() ) eq "ARRAY" );
ok( ref( Image::LibRSVG->getSupportedFormats() ) eq "ARRAY" );
ok( Image::LibRSVG->isFormatSupported("png") );
