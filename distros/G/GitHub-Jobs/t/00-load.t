#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'GitHub::Jobs' ) || print "Bail out!\n";
}

diag( "Testing GitHub::Jobs $GitHub::Jobs::VERSION, Perl $], $^X" );
