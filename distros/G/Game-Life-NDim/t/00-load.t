#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Game::Life::NDim' );
    use_ok( 'Game::Life::NDim::Dim' );
    use_ok( 'Game::Life::NDim::Board' );
    use_ok( 'Game::Life::NDim::Life' );
}

diag( "Testing Game::Life::NDim $Game::Life::NDim::VERSION, Perl $], $^X" );
