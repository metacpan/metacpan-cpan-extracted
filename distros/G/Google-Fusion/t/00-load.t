#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Google::Fusion' ) || print "Bail out!\n";
}

diag( "Testing Google::Fusion $Google::Fusion::VERSION, Perl $], $^X" );
