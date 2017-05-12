#! perl

use strict;
use Test::More tests => 51;

##################

use Games::Mines;

my $game;

srand 2; # so we always get the same field.
$game = Games::Mines->new(12,45,89);

$game->{'field'} = [
		    [ { contains    => " ",visibility  => ''},
		      { contains    => "2",visibility  => ''},
		      { contains    => "*",visibility  => ''}, ],
		    
		    [ { contains    => " ",visibility  => '.'},
		      { contains    => "4",visibility  => '.'},
		      { contains    => "*",visibility  => '.'}, ],
		    
		    [ { contains    => " ",visibility  => 'F'},
		      { contains    => "6",visibility  => 'F'},
		      { contains    => "*",visibility  => 'F'}, ],
		    ];
################## _at

is( $game->_at(0,0),' ');
is( $game->_at(0,1), 2 );
is( $game->_at(0,2),'*');
is( $game->_at(1,0),' ');
is( $game->_at(1,1), 4 );
is( $game->_at(1,2),'*');
is( $game->_at(2,0),' ');
is( $game->_at(2,1), 6 );
is( $game->_at(2,2),'*');

################### shown
ok( $game->shown(0,0) );
ok( $game->shown(0,1) );
ok( $game->shown(0,2) );
ok( not $game->shown(1,0) );
ok( not $game->shown(1,1) );
ok( not $game->shown(1,2) );
ok( not $game->shown(2,0) );
ok( not $game->shown(2,1) );
ok( not $game->shown(2,2) );

################### hidden
ok( not $game->hidden(0,0) );
ok( not $game->hidden(0,1) );
ok( not $game->hidden(0,2) );
ok( $game->hidden(1,0) );
ok( $game->hidden(1,1) );
ok( $game->hidden(1,2) );
ok( $game->hidden(2,0) );
ok( $game->hidden(2,1) );
ok( $game->hidden(2,2) );

################## at

is( $game->at(0,0),' ');
is( $game->at(0,1), 2 );
is( $game->at(0,2),'*');
is( $game->at(1,0),'.');
is( $game->at(1,1),'.');
is( $game->at(1,2),'.');
is( $game->at(2,0),'F');
is( $game->at(2,1),'F');
is( $game->at(2,2),'F');


################### flagged
ok( not $game->flagged(0,0) );
ok( not $game->flagged(0,1) );
ok( not $game->flagged(0,2) );
ok( not $game->flagged(1,0) );
ok( not $game->flagged(1,1) );
ok( not $game->flagged(1,2) );
ok( $game->flagged(2,0) );
ok( $game->flagged(2,1) );
ok( $game->flagged(2,2) );


################## _fill_count
$game->_fill_count(2,2);
is($game->_at(2,1), '7');
is($game->_at(1,1), '5');
is($game->_at(0,1), '2');

$game->_fill_count(1,2);
is($game->_at(2,1), '8');
is($game->_at(1,1), '6');
is($game->_at(0,1), '3');

