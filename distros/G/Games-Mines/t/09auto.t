#! perl

use Test::More tests=> 52;
use strict;

use Games::Mines::Play;

my $game;

srand 2; # so we always get the same field.
$game = Games::Mines::Play->new(12,45,89);


################## width
is($game->width,11);

################## height
is($game->height,44);

################## _limit
my(@r) = $game->_limit(10,20,"foo","bar");
is( $r[0], 10);
is( $r[1], 20);
is( $r[2], "foo");

@r = $game->_limit(14,56,"foo","bar");
is( $r[0], 11);
is( $r[1], 44);
is( $r[2], "foo");

@r = $game->_limit(-7,-5,"foo","bar");
is( $r[0], 0);
is( $r[1], 0);
is( $r[2], "foo");

################## running

$game = Games::Mines::Play->new(3,3,2);
ok( not $game->running);

$game->fill_mines;

ok( $game->running);

################## fill_mines

is( $game->_at(0,0),' ');
is( $game->_at(0,1),1);
is( $game->_at(0,2),1);
is( $game->_at(1,0),1);
is( $game->_at(1,1),2);
is( $game->_at(1,2),'*');
is( $game->_at(2,0),'*');
is( $game->_at(2,1),2);
is( $game->_at(2,2),1);

################## pre-stepped

is( $game->at(0,0),'.');
is( $game->at(2,1),'.');
is( $game->at(1,1),'.');
ok( $game->hidden(0,0));
ok( not $game->shown(0,0));
ok( not $game->found_all);

################## post-step

$game->step(0,0);
is( $game->at(0,0),' ');
is( $game->at(2,1),'.');
is( $game->at(1,1),'2');
ok( not $game->hidden(0,0));
ok( $game->shown(0,0));
ok( not $game->found_all);

################## flagging

$game->flag(1,2);
$game->flag(2,2);
is( $game->at(1,2),'F');
is( $game->at(2,2),'F');
ok( $game->hidden(2,2));
ok( not $game->shown(2,2));
ok( not $game->found_all);
ok( $game->flagged(1,2));
ok( $game->flagged(2,2));
ok( not $game->flagged(0,2));

################## flagging

$game->unflag(2,2);
$game->flag(2,0);
is( $game->at(2,2),'.');
ok( $game->hidden(2,2));
ok( not $game->shown(2,2));
ok( not $game->found_all);
ok( not $game->flagged(2,2));

################## flagging

ok( $game->running);

$game->step(0,2);
$game->step(2,1);
$game->step(2,2);
ok( $game->found_all);
ok( not $game->running);

##################
srand 2; # so we always get the same field.
$game = Games::Mines::Play->new(3,3,2);

$game->step(0,2);
ok( not $game->found_all);
ok( not $game->running);

