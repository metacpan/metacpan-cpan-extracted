#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 5;

BEGIN {
    use_ok('Games::TicTacToe')         || print "Bail out!";
    use_ok('Games::TicTacToe::Board')  || print "Bail out!";
    use_ok('Games::TicTacToe::Player') || print "Bail out!";
    use_ok('Games::TicTacToe::Move')   || print "Bail out!";
    use_ok('Games::TicTacToe::Params') || print "Bail out!";
}

diag( "Testing Games::TicTacToe $Games::TicTacToe::VERSION, Perl $], $^X" );
