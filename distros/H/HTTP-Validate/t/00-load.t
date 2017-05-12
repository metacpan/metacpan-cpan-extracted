#!perl -T

use lib 'lib';

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTTP::Validate' ) || print "Bail out!\n";
}

diag( "Testing HTTP::Validate $HTTP::Validate::VERSION, Perl $], $^X" );
