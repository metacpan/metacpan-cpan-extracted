#! perl

use strict;
use Test::More tests => 46;

##################

use Games::Mines;

my $game;

srand 2; # so we always get the same field.

#################### fill_mines

$game = Games::Mines->new(3,3,2);

is( $game->why, "not started");

$game->fill_mines;

is( $game->why, "Running");

is( $game->_at(0,0),' ');
is( $game->_at(0,1), 1 );
is( $game->_at(0,2), 1 );
is( $game->_at(1,0), 1 );
is( $game->_at(1,1), 2 );
is( $game->_at(1,2),'*');
is( $game->_at(2,0),'*');
is( $game->_at(2,1), 2 );
is( $game->_at(2,2), 1 );

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

is($game->flags, 0 );
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
is($game->flags, 2 );

################## flagging

$game->unflag(2,2);
is($game->flags, 1 );
$game->flag(2,0);
is( $game->at(2,2),'.');
ok( $game->hidden(2,2));
ok( not $game->shown(2,2));
ok( not $game->found_all);
ok( not $game->flagged(2,2));
is($game->flags, 2 );

################## flagging

ok( $game->running);
$game->step(0,2);
$game->step(2,1);
$game->step(2,2);
ok( $game->found_all);
ok( not $game->running);
is($game->why,"You Win!!!");

##################

srand 2; # so we always get the same field.
$game = Games::Mines->new(3,3,2);

ok( not $game->running);
is( $game->why, "not started");

$game->fill_mines;

ok( $game->running);
is( $game->why, "Running");

$game->step(2,0);
ok( not $game->found_all);
ok( not $game->running);
is($game->why, "KABOOOOOM!!!");

