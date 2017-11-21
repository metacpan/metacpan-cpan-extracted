#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MYDan' ) || print "Bail out!\n";
}

diag( "Testing MYDan $MYDan::VERSION, Perl $], $^X" );

