#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Maple' ) || print "Bail out!\n";
    use_ok( 'Maple::Class' ) || print "Bail out!\n";
}

diag( "Testing Maple $Maple::VERSION, Perl $], $^X" );
