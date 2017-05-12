#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Image::QRCode::Effects' ) || print "Bail out!\n";
}

diag( "Testing Image::QRCode::Effects $Image::QRCode::Effects::VERSION, Perl $], $^X" );
