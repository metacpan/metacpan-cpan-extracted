#! perl

use Test::More tests=>40;
use strict;

use Games::Mines::Play;

my $game = Games::Mines::Play->new(30,40,50);

# make copy
use File::Copy;
copy("t/game.dat","t/game.sav");

$game->load_game("t/game.sav",2);

is( scalar( @{$game->{GAME}->{'field'}->[0] } ) , 3);
is( scalar( @{$game->{GAME}->{'field'} } ) , 3);

# check internal
is( $game->_at(0,0),' ');
is( $game->_at(0,1),1);
is( $game->_at(0,2),1);
is( $game->_at(1,0),1);
is( $game->_at(1,1),2);
is( $game->_at(1,2),'*');
is( $game->_at(2,0),'*');
is( $game->_at(2,1),2);
is( $game->_at(2,2),1);

# check visible

is( $game->at(0,0),' ');
is( $game->at(0,1),1);
is( $game->at(0,2),'F');
is( $game->at(1,0),1);
is( $game->at(1,1),2);
is( $game->at(1,2),'.');
is( $game->at(2,0),'F');
is( $game->at(2,1),'.');
is( $game->at(2,2),'.');

##################

$game->save_game("t/game.sav",4);

$game = Games::Mines::Play->new(25,35,55);

$game->load_game("t/game.sav",4);

is( scalar( @{$game->{GAME}->{'field'}->[0] } ) , 3);
is( scalar( @{$game->{GAME}->{'field'} } ) , 3);

# check internal

is( $game->_at(0,0),' ');
is( $game->_at(0,1),1);
is( $game->_at(0,2),1);
is( $game->_at(1,0),1);
is( $game->_at(1,1),2);
is( $game->_at(1,2),'*');
is( $game->_at(2,0),'*');
is( $game->_at(2,1),2);
is( $game->_at(2,2),1);

# check visible

is( $game->at(0,0),' ');
is( $game->at(0,1),1);
is( $game->at(0,2),'F');
is( $game->at(1,0),1);
is( $game->at(1,1),2);
is( $game->at(1,2),'.');
is( $game->at(2,0),'F');
is( $game->at(2,1),'.');
is( $game->at(2,2),'.');
