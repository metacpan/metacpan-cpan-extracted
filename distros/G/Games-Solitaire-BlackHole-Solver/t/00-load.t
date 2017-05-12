#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Games::Solitaire::BlackHole::Solver' );
    use_ok( 'Games::Solitaire::BlackHole::Solver::App' );
}

diag( "Testing Games::Solitaire::BlackHole::Solver $Games::Solitaire::BlackHole::Solver::VERSION, Perl $], $^X" );
