#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'EJS::Template' ) || print "Bail out!\n";
}

diag( "Testing EJS::Template $EJS::Template::VERSION, Perl $], $^X" );
