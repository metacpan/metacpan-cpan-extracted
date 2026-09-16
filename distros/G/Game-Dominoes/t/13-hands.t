#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Hand;
use Game::Dominoes::Result;
use Game::Dominoes::Set qw(PIPS);
use Game::Dominoes::Tile;

plan tests => 8;

sub tile { Game::Dominoes::Tile->of(@_) }

# Play a whole game out, always taking the first legal move, and return it.
sub played {
	my (%args) = @_;
	my $g = Game::Dominoes->new(seed => 'a' x 32, %args);
	my $n = 0;
	while ($g->status eq 'active' && $n++ < 20000) {
		my $moves = $g->legal($g->turn);
		last unless @$moves;
		my $out = $g->play($g->turn, $moves->[0]);
		die $out->stringify if ref $out eq 'Game::Dominoes::Error';
	}
	return $g;
}

subtest 'a game runs many hands to the target' => sub {
	plan tests => 4;

	my $g = played();
	is $g->status, 'finished', 'the game finished';
	is $g->result->reason, 'target', 'because somebody reached the target';
	cmp_ok $g->hand_number, '>', 1, 'and it took more than one hand';
	cmp_ok +(sort { $b <=> $a } values %{ $g->scores })[0], '>=', $g->target,
		'the winning score is at or past the target';
};

subtest 'the target defaults come from the primary source' => sub {
	plan tests => 4;

	# "usually 250 points for two players and 200 points with three or four".
	is(Game::Dominoes->new(seed => 'a' x 32, players => 2)->target, 250,
		'250 at two seats');
	is(Game::Dominoes->new(seed => 'a' x 32, players => 3)->target, 200,
		'200 at three');
	is(Game::Dominoes->new(seed => 'a' x 32, players => 4)->target, 200,
		'and 200 at four');

	is(Game::Dominoes->new(seed => 'a' x 32, target => 61, scale => 5)->target, 61,
		'and the cribbage board variation takes 61 with the divided scale');
};

subtest 'the game stops the moment the target is reached' => sub {
	plan tests => 3;

	# "When a player or team reaches the agreed target the game ends
	# immediately. The remaining tiles (if any) in the players' hands are not
	# played or counted."
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2, target => 10);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3) ]);
	$g->turn(1);
	$g->scores({ 1 => 0, 2 => 0 });

	# 6-4 as the opening lead counts ten, which is the target exactly.
	$g->play(1, '6-4@L');

	is $g->status, 'finished', 'the game ended on the scoring play';
	is $g->scores->{1}, 10, 'at exactly the target';
	ok $g->hand(1)->count, 'with a tile still in hand, unplayed and uncounted';
};

subtest 'the score carries across hands' => sub {
	plan tests => 2;

	my $g = played();
	my $total = 0;
	for my $event (@{ $g->history }) {
		$total += $event->{points} || 0;
	}
	my $scored = 0;
	$scored += $_ for values %{ $g->scores };

	is $scored, $total,
		'every point in the final scores was awarded by a recorded event';
	cmp_ok scalar(grep { $_->{kind} eq 'hand_end' } @{ $g->history }), '>', 0,
		'and hands ended along the way';
};

subtest 'the deal accounts for 168 pips at every ply of every hand' => sub {
	plan tests => 3;

	for my $players (2, 3, 4) {
		my $g = Game::Dominoes->new(seed => 'c' x 32, players => $players);
		my ($bad, $n) = (0, 0);
		while ($g->status eq 'active' && $n++ < 20000) {
			my $total = $g->layout->pips + $g->boneyard->pips;
			$total += $g->hand($_)->pips for $g->seats;
			$bad++ if $total != PIPS;
			my $moves = $g->legal($g->turn);
			last unless @$moves;
			$g->play($g->turn, $moves->[0]);
		}
		is $bad, 0, "$players players: no ply lost or duplicated a tile";
	}
};

subtest 'places are a finishing order, not just a winner' => sub {
	plan tests => 6;

	for my $players (2, 3, 4) {
		my $g = played(players => $players);
		my $places = $g->places;

		is scalar(keys %$places), $players, "$players players: every seat is placed";

		# The winner has the top score, and place 1 belongs to whoever it is.
		my ($top) = sort { $g->scores->{$b} <=> $g->scores->{$a} } $g->seats;
		is $places->{$top}, 1, "$players players: the highest score is first";
	}
};

subtest 'a tie shares a place and leaves the next one empty' => sub {
	plan tests => 4;

	# Built straight from Result rather than hunted for across seeds: two
	# seats level on second means two seats at 2 and NOBODY at 3, the way a
	# race result is written.
	my $r = Game::Dominoes::Result->new(
		places => { 1 => 1, 2 => 2, 3 => 2, 4 => 4 },
		scores => { 1 => 200, 2 => 150, 3 => 150, 4 => 90 },
		reason => 'target',
	);

	is $r->winner, 1, 'there is a single winner';
	ok !$r->is_draw, 'so it is not a draw';
	is_deeply $r->ranking, [ [1], [ 2, 3 ], [4] ],
		'the ranking keeps the tie visible instead of flattening it';
	is scalar(grep { $_ == 3 } values %{ $r->places }), 0, 'and nobody is third';
};

subtest 'a drawn game has no single winner' => sub {
	plan tests => 3;

	my $r = Game::Dominoes::Result->new(
		places => { 1 => 1, 2 => 1 },
		scores => { 1 => 250, 2 => 250 },
		reason => 'target',
	);

	is $r->winner, undef, 'winner is undef when the top place is shared';
	ok $r->is_draw, 'which is a draw, not an error';
	is_deeply $r->winners, [ 1, 2 ], 'and both seats are named';
};
