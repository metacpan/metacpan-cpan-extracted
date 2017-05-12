#! perl

use Test::More tests=> 10;

##################

use strict;
use Games::Mines::Play;

use CGI;
use Data::Dumper;
my($game,$game2);

$game = Games::Mines::Play->new(30,40,50);

ok( defined($game) );

is( ref($game->{GAME}), "Games::Mines" );

$game2 = $game->new(30,40,50);

ok( defined($game2) );

is( ref($game2->{GAME}), "Games::Mines" );

##################
# dummy CGI object to see if containment works

$game = Games::Mines::Play->new(12,45,89,"CGI");

ok( defined($game) );

is( ref($game->{GAME}), "CGI" );

$game2 = $game->new(12,45,89,"CGI");

ok( defined($game) );

is( ref($game->{GAME}), "CGI" );

$game = Games::Mines::Play->new(8,9,72);

ok( defined($game) );


$game = Games::Mines::Play->new(8,9,73);

ok( not defined($game) );


