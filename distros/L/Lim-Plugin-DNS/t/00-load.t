#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lim::Plugin::DNS' ) || print "Bail out!\n";
}

diag( "Testing Lim::Plugin::DNS $Lim::Plugin::DNS::VERSION, Perl $], $^X" );
