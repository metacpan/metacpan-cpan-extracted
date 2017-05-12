#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Image::Empty' ) || print "Bail out!\n";
}

diag( "Testing Image::Empty $Image::Empty::VERSION, Perl $], $^X" );
