#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mail::RoundTrip' ) || print "Bail out!\n";
}

diag( "Testing Mail::RoundTrip $Mail::RoundTrip::VERSION, Perl $], $^X" );
