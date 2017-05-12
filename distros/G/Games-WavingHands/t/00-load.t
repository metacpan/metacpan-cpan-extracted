#!perl -T

use Test::More tests => 8;

BEGIN {
	use_ok( 'Games::WavingHands' );
	use_ok( 'Games::WavingHands::Archive' );
	use_ok( 'Games::WavingHands::Engine' );
	use_ok( 'Games::WavingHands::Archive::WavingHands' );
	use_ok( 'Games::WavingHands::Engine::WavingHands' );
        use_ok( 'Games::WavingHands::Parser' );
        use_ok( 'Games::WavingHands::Parser::WavingHands' );
        use_ok( 'Games::WavingHands::Parser::Grammar::WavingHands' );

}

diag( "Testing Games::WavingHands $Games::WavingHands::VERSION, Perl $], $^X" );
