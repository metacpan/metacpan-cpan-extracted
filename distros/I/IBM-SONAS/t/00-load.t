#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IBM::SONAS' ) || print "Bail out!\n";
}

diag( "Testing IBM::SONAS $IBM::SONAS::VERSION, Perl $], $^X" );
