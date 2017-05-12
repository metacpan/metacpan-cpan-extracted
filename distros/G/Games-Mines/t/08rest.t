#! perl

use Test::More tests=> 30;
use strict;

use Games::Mines::Play;

my $game = Games::Mines::Play->new(30,40,50);


$game->set_ASCII;

foreach my $k (keys %{$game->{'map'}}) {
    is($game->{'map'}->{$k},$k);
}

 SKIP:{
     skip "These tests only work if you have Term::ANSIColor", 14
	 unless( $Games::Mines::Play::loaded_ansi_color );
     ok($game->set_ANSI_Color);
     
     foreach my $k (keys %{$game->{'map'}}) {
	 ok($game->{'map'}->{$k});
     }
 }

$Games::Mines::Play::loaded_ansi_color=0;
ok( not defined($game->set_ANSI_Color));

