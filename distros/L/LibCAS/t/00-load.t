#!perl -T

use lib qw(. ..);

use Test::More tests => 1;

BEGIN {
    use_ok( 'LibCAS::Client' ) || print "Bail out!\n";
}

diag( "Testing LibCAS $LibCAS::Client::VERSION, Perl $], $^X" );
