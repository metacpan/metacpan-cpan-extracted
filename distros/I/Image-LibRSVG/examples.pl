#!/usr/bin/perl

use Image::LibRSVG;
use strict;

my $known_formats = Image::LibRSVG->getKnownFormats();

print "KNOWN FORMATS:\n";

foreach( @{ $known_formats } ) {
    print "    * $_\n";
}

my $formats = Image::LibRSVG->getSupportedFormats();

print "SUPPORTED FORMATS:\n";

foreach( @{ $formats } ) {
    print "    * $_\n";
}

my $rsvg = new Image::LibRSVG();

$rsvg->convert( "examples/artscontrol.svg", "examples/artscontrol_convert.png" );
$rsvg->convert( "examples/kate.svg", "examples/kate_convert.png" );
$rsvg->convert( "examples/klipper.svg", "examples/klipper_convert.png" );
$rsvg->convert( "examples/kmail.svg", "examples/kmail_convert.png" );
$rsvg->convert( "examples/konsole.svg", "examples/konsole_convert.png" );
$rsvg->convert( "examples/kwrite.svg", "examples/kwrite_convert.png" );
$rsvg->convert( "examples/openoffice.svg", "examples/openoffice_convert.png" );
$rsvg->convert( "examples/staroffice.svg", "examples/staroffice_convert.png" );
$rsvg->convert( "examples/wine.svg", "examples/wine_convert.png" );

## and a compressed one
$rsvg->convert( "examples/konsole.svgz", "examples/konsole_convert_gzipped.png" );


$rsvg->loadImage( "examples/artscontrol.svg" );
$rsvg->saveAs( "examples/artscontrol.svg.load.png" );
