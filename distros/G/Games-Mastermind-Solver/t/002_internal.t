#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;

use Games::Mastermind;
use Games::Mastermind::Solver::BruteForce;

my $pegs = [ qw(B C G R Y W) ];
my $holes = 4;

my $game = Games::Mastermind->new
    ( pegs  => $pegs,
      holes => $holes,
      );
my $player = Games::Mastermind::Solver::BruteForce->new( $game );

is_deeply( [ Games::Mastermind::Solver::BruteForce::_from_number( 0, $pegs, $holes ) ],
           [ qw(B B B B) ] );
is_deeply( [ Games::Mastermind::Solver::BruteForce::_from_number( 1295, $pegs, $holes ) ],
           [ qw(W W W W) ] );
is_deeply( [ Games::Mastermind::Solver::BruteForce::_from_number( 1244, $pegs, $holes ) ],
           [ qw(G R Y W) ] );

is( $player->_peg_number, 6 );
is_deeply( $player->_pegs, [ qw(B C G R Y W) ] );
is( $player->_holes, 4 );

srand( 123 );
my $chosen = $player->_guess;
srand( 123 );
is( $player->_guess, $chosen );

$player->{possibility} = [];

eval {
    my $chosen = $player->_guess;
    ok( 0, 'Must not get there' );
};
ok( $@, 'Correctly dies' );

