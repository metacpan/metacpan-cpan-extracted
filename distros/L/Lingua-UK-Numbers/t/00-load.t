#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lingua::UK::Numbers' ) || print "Bail out!\n";
}

diag( "Testing Lingua::UK::Numbers $Lingua::UK::Numbers::VERSION, Perl $], $^X" );
