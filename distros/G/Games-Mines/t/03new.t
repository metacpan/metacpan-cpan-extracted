#! perl

use strict;
use Test::More tests => 28;

##################

use Games::Mines;

my $game;

$game = bless {
	       'field'  => undef()
	      },"Games::Mines";

$game->_reset(4,4);

is( keys( %{$game->{'field'}->[0]->[0] } ) , 3);
is( scalar( @{$game->{'field'}->[0] } ) , 4);
is( scalar( @{$game->{'field'} } ) , 4);


$game->_reset(30,40);

is( keys( %{$game->{'field'}->[0]->[0] } ) , 3);
is( scalar( @{$game->{'field'}->[0] } ) , 40);
is( scalar( @{$game->{'field'} } ) , 30);


$game->_reset(12,45);

is( keys( %{$game->{'field'}->[0]->[0] } ) , 3);
is( scalar( @{$game->{'field'}->[0] } ) , 45);
is( scalar( @{$game->{'field'} } ) , 12);


#################

$game = Games::Mines->new(4,4,2);

is(ref($game),"Games::Mines");
ok($game->isa("Games::Mines") );

is( keys( %{$game->{'field'}->[0]->[0] } ) , 3);
is( scalar( @{$game->{'field'}->[0] } ) , 4);
is( scalar( @{$game->{'field'} } ) , 4);

is_deeply( [ $game->_limit(2,3,'foo','bar')], [2,3,'foo','bar']);
is_deeply( [ $game->_limit(-7,-2,'foo','bar')], [0,0,'foo','bar']);
is_deeply( [ $game->_limit(5,5,'baz')], [3,3,'baz']);

$game = Games::Mines->new(30,40,50);

is( keys( %{$game->{'field'}->[0]->[0] } ) , 3);
is( scalar( @{$game->{'field'}->[0] } ) , 40);
is( scalar( @{$game->{'field'} } ) , 30);

$game = Games::Mines->new(12,45,89);

is( keys( %{$game->{'field'}->[0]->[0] } ) , 3);
is( scalar( @{$game->{'field'}->[0] } ) , 45);
is( scalar( @{$game->{'field'} } ) , 12);

##################

$game = $game->new(30,40,50);


is( keys( %{$game->{'field'}->[0]->[0] } ) , 3);
is( scalar( @{$game->{'field'}->[0] } ) , 40);
is( scalar( @{$game->{'field'} } ) , 30);


##################

$game = Games::Mines->new(8,9,72);

ok( defined($game) );


$game = Games::Mines->new(8,9,73);

ok( not defined($game) );

