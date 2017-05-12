#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IPsonar' ) || print "Bail out!\n";
}

diag( "Testing IPsonar $IPsonar::VERSION, Perl $], $^X" );
