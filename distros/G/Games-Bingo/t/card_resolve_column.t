#!/usr/bin/perl -w



use strict;
use Test::More tests => 91;

use_ok( 'Games::Bingo::Card' );

#Testing the resolution of numbers resolv column
my $bingo = Games::Bingo->new();
my @game_numbers;
$bingo->init(\@game_numbers, 90);

my $card = Games::Bingo::Card->new();

my $match = 0;
for(my $i = 0; $i < (scalar @game_numbers); $i++) {
	if ($game_numbers[$i] == 90) {
		#nop;
	} elsif ($game_numbers[$i] > 9) {
		$match++ if (($game_numbers[$i] % 10) == 0);
	} 
	is($card->_resolve_column($game_numbers[$i]), $match, "Testing number: $game_numbers[$i] against: $match");
}