#!perl -T -Ilib

use Test::More tests => 1;

BEGIN {
    use_ok( 'Giovanni' ) || print "Bail out!\n";
}

diag( "Testing Giovanni $Giovanni::VERSION, Perl $], $^X" );
