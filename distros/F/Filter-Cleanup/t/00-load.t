#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Filter::Cleanup' ) || print "Bail out!\n";
}

diag( "Testing Filter::Cleanup $Filter::Cleanup::VERSION, Perl $], $^X" );
