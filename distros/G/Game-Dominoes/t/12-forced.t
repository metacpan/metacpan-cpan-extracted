#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Boneyard;
use Game::Dominoes::Hand;
use Game::Dominoes::Tile;

plan tests => 7;

sub tile { Game::Dominoes::Tile->of(@_) }

sub events { my ($g, $kind) = @_; return grep { $_->{kind} eq $kind } @{ $g->history } }

subtest 'legal never offers a draw, only plays' => sub {
	plan tests => 3;

	# This is the rule the client and the site both depend on. A turn limit
	# on a correspondence site is a day or three, and spending one on a move
	# with exactly one outcome is how a thirty play hand becomes a three
	# month game.
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2);
	my ($kinds, $empty, $n) = ({}, 0, 0);

	while ($g->status eq 'active' && $n++ < 5000) {
		my $moves = $g->legal($g->turn);
		$empty++ unless @$moves;
		$kinds->{ $_->{kind} }++ for @$moves;
		last unless @$moves;
		$g->play($g->turn, $moves->[0]);
	}

	is_deeply [ sort keys %$kinds ], ['play'],
		'every move offered across a whole game is a play';
	is $empty, 0, 'and the seat on the clock always had something to do';
	is $g->status, 'finished', 'the game finished';
};

subtest 'a seat that cannot play draws, and the engine does it' => sub {
	plan tests => 4;

	# Seat 2 holds one tile that matches nothing on the table, so when the
	# turn reaches it the engine must draw for it rather than hand a draw
	# back as a decision.
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(
		tiles => [ tile(5, 5), tile(4, 2) ]
	));
	$g->turn(1);
	$g->history([]);

	$g->play(1, '6-4@L');

	ok scalar(events($g, 'draw')), 'the engine drew for the seat that could not play';
	is $g->turn, 2, 'the turn is still with that seat';
	ok $g->hand_count(2) > 1, 'which now holds more tiles than it was dealt';

	my $moves = $g->legal(2);
	ok scalar(@$moves), 'and it has a play to make';
};

subtest 'a drawn tile is the tile that must be played' => sub {
	plan tests => 3;

	# Pagat: "When a player draws a playable tile, it goes on the table
	# immediately and the player's turn ends." So a drawn tile is not a
	# choice; only its arm may be.
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(
		tiles => [ tile(2, 2), tile(6, 5) ]
	));
	$g->turn(1);

	$g->play(1, '6-4@L');

	is $g->forced_tile && $g->forced_tile->stringify, '6-5',
		'the seat drew past the 2-2 and stopped on the 6-5';

	my $moves = $g->legal(2);
	is_deeply [ sort map { $_->{tile}->stringify } @$moves ], ['6-5'],
		'and that is the only tile it may play, even though it holds others';

	is scalar(grep { $_->{tile}->stringify eq '3-3' } @$moves), 0,
		'the tile it was dealt is not offered';
};

subtest 'the boneyard is drawn to empty' => sub {
	plan tests => 3;

	# The pinned rule, from the primary source: a player who cannot play
	# "must draw tiles from the boneyard until he has a tile to play or the
	# boneyard is empty". A reserve of two belongs to Draw Dominoes, a
	# different game, and is a listed VARIATION here, not the rule.
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2);
	is $g->reserve, 0, 'nothing is held back by default';

	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(
		tiles => [ tile(2, 2), tile(5, 0) ]
	));
	$g->turn(1);
	$g->history([]);
	$g->play(1, '6-4@L');

	# Assert on the history, not on the boneyard: nobody can play here, so
	# the hand blocks inside this one call and a fresh hand is dealt, which
	# means the boneyard you can see afterwards is the NEXT one.
	my $drawn = 0;
	$drawn += $_->{count} for events($g, 'draw');
	is $drawn, 2, 'the seat drew the yard out looking for a play';
	ok scalar(events($g, 'pass')), 'and then passed, having found none';
};

subtest 'the reserve variation holds tiles back and forces a pass' => sub {
	plan tests => 3;

	# "Some play that the last tile or the last two tiles in the boneyard can
	# never be drawn. If the boneyard is reduced to one (or two) tiles
	# players who cannot play must pass."
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2, reserve => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(
		reserve => 2,
		tiles => [ tile(2, 2), tile(5, 0) ]
	));
	$g->turn(1);
	$g->history([]);
	$g->play(1, '6-4@L');

	is scalar(events($g, 'draw')), 0, 'no draw happened at all';
	ok scalar(events($g, 'pass')) >= 2, 'both seats passed instead';
	my ($end) = events($g, 'hand_end');
	like $end->{reason}, qr/\Ablocked/,
		'so the hand blocked with tiles still sitting in the yard';
};

subtest 'a hand blocks when every seat passes in succession' => sub {
	plan tests => 3;

	# Nobody can play and there is nothing to draw, so both seats pass and
	# the hand is over. Pagat: "The hand continues until one player dominoes
	# or until all players are blocked."
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => []));
	$g->turn(1);
	$g->history([]);

	my $before = $g->hand_number;
	$g->play(1, '6-4@L');

	my ($end) = events($g, 'hand_end');
	ok $end, 'the hand ended';
	like $end->{reason}, qr/\Ablocked/, 'because it was blocked';
	cmp_ok $g->hand_number, '>', $before, 'and the next hand was dealt';
};

subtest 'the lightest hand wins a blocked deal' => sub {
	plan tests => 2;

	# Seat 2 holds 3-3, six pips. Seat 1 holds 1-1, two pips. Seat 1 is
	# lighter and scores seat 2's six, rounded to the nearest five.
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => []));
	$g->turn(1);
	$g->scores({ 1 => 0, 2 => 0 });
	$g->history([]);

	$g->play(1, '6-4@L');

	my ($end) = events($g, 'hand_end');
	is $end->{seat}, 1, 'the lighter hand won the deal';
	# 6-4 scored 10 as the opening lead, then 6 pips round to 5.
	is $g->scores->{1}, 15, 'and scored the loser pips rounded to the nearest five';
};
