#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MIME::Multipart::Parse::Ordered' ) || print "Bail out!\n";
}

diag( "Testing MIME::Multipart::Parse::Ordered $MIME::Multipart::Parse::Ordered::VERSION, Perl $], $^X" );
