#!/usr/bin/perl -w

use strict;
use Test::More tests => 23;

use Games::Mastermind;
use Games::Mastermind::Solver::BruteForce;

my $pegs = [ qw(B C G R Y W) ];
my $holes = 4;

{
    package Games::Mastermind::Tester;

    use base qw(Games::Mastermind::Solver::BruteForce);

    sub _guess {
        return $_[0]->_possibility( 0 );
    }
}

my $game = Games::Mastermind->new
    ( pegs  => $pegs,
      holes => $holes,
      );
my $player = Games::Mastermind::Tester->new( $game );

$game->code( [ qw(W W W W) ] );

is( $player->remaining, 1296 );
is( $player->_possibility, undef );
is( $player->_possibility( 0 ), 0 );
is( $player->_possibility( 1295 ), 1295 );
is( $player->_possibility( 800 ), 800 );

is_deeply( [ $player->move ], [ 0, [ qw(B B B B) ], [ 0, 0 ] ] );
is( $player->remaining, 625 );
is( ref( $player->_possibility ), 'ARRAY' );
is( $player->_possibility( 0 ), 259 );
is( $player->_possibility( 624 ), 1295 );

is_deeply( [ $player->move( [ qw(C C C C) ] ) ],
           [ 0, [ qw(C C C C) ], [ 0, 0 ] ] );
is( $player->remaining, 256 );

is_deeply( [ $player->move ], [ 0, [ qw(G G G G) ], [ 0, 0 ] ] );
is( $player->remaining, 81 );

is_deeply( [ $player->move ], [ 0, [ qw(R R R R) ], [ 0, 0 ] ] );
is( $player->remaining, 16 );

is_deeply( [ $player->move ], [ 0, [ qw(Y Y Y Y) ], [ 0, 0 ] ] );
is( $player->remaining, 1 );

is_deeply( [ $player->move ], [ 1, [ qw(W W W W) ], [ 4, 0 ] ] );
is( $player->remaining, 1 );

is_deeply( [ $player->move ], [ 1, undef, undef ] );

$player->reset;
$player->{possibility} = [ 1244, 0 .. 1243, 1245 .. 1295 ];
$game->code( [ qw(W B B G) ] );
is_deeply( [ $player->move ], [ 0, [ qw(G R Y W) ], [ 0, 2 ] ] );
is( $player->remaining, 312 );
