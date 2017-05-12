#!/usr/bin/perl -w

use Test::More tests => 1;

BEGIN {
    use_ok( 'Game::Life::Infinite::Board' ) || print "Bail out!
";
}

diag( "Testing Game::Life::Infinite::Board $Game::Life::Infinite::Board::VERSION, Perl $], $^X" );
