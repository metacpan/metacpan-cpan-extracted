#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'LPDS' ) || print "Bail out!\n";
}

diag( "Testing LPDS $LPDS::VERSION, Perl $], $^X" );
