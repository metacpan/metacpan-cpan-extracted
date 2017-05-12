#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dir::Rocknroll' ) || print "Bail out!\n";
}

diag( "Testing Dir::Rocknroll $Dir::Rocknroll::VERSION, Perl $], $^X" );
