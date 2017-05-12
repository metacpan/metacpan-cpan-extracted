#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'GnuPG::Crypticle' ) || print "Bail out!\n";
}

diag( "Testing GnuPG::Crypticle $GnuPG::Crypticle::VERSION, Perl $], $^X" );
