#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Game::Life' ) || print "Bail out!
";
}

diag( "Testing Game::Life $Game::Life::VERSION, Perl $], $^X" );
