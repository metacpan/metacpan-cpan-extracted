#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Encode::Detect::Upload' ) || print "Bail out!\n";
}

diag( "Testing Encode::Detect::Upload $Encode::Detect::Upload::VERSION, Perl $], $^X" );
