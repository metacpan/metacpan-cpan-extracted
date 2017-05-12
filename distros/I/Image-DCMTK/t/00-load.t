#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Image::DCMTK' ) || print "Bail out!\n";
}

diag( "Testing Image::DCMTK $Image::DCMTK::VERSION, Perl $], $^X" );
