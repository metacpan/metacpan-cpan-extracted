#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Fortune::WWW::Postillion' ) || print "Bail out!\n";
}

diag( "Testing Fortune::WWW::Postillion $Fortune::WWW::Postillion::VERSION, Perl $], $^X" );
