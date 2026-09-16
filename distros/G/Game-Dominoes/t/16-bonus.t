#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Boneyard;
use Game::Dominoes::Hand;
use Game::Dominoes::Scoring qw(bonus);
use Game::Dominoes::Tile;

plan tests => 7;

sub tile { Game::Dominoes::Tile->of(@_) }

subtest 'the two cited rounding pairs' => sub {
	plan tests => 4;

	# Pagat, All Fives, on the winner scoring the losers' pips: "For example,
	# in a two-player game a losing hand with just the [1-2] would round up to
	# five points, while [1-1] would round down to zero points."
	is bonus(3), 5, 'the 1-2, three pips, rounds up to five';
	is bonus(2), 0, 'the 1-1, two pips, rounds down to nothing';

	# Wikipedia, Muggins: "the winner scores 25 for 27 pips in an opponent's
	# hand and 30 for 28 points". Muggins is a different game (it has no
	# spinner), but the rounding function it describes is the same one, so
	# this is a citable vector for the arithmetic even though its rule about
	# WHAT to round is not the one we took. See the subtest below.
	is bonus(27), 25, 'twenty-seven rounds down to twenty-five';
	is bonus(28), 30, 'twenty-eight rounds up to thirty';
};

subtest 'the whole rounding table, hand-derived' => sub {
	plan tests => 30;

	# Remainder 0 to 4, distances 0, then 1 and 4, then 2 and 3, then 3 and 2,
	# then 4 and 1. A tie is arithmetically impossible, so "nearest" is total
	# and there is no half-away-from-zero policy to choose. A defensive tie
	# branch here would be code that can never run.
	my %want = (
		0 => 0, 1 => 0, 2 => 0,
		3 => 5, 4 => 5, 5 => 5, 6 => 5, 7 => 5,
		8 => 10, 9 => 10, 10 => 10, 11 => 10, 12 => 10,
		13 => 15, 14 => 15, 15 => 15, 16 => 15, 17 => 15,
		18 => 20, 19 => 20, 20 => 20, 21 => 20, 22 => 20,
		23 => 25, 24 => 25, 25 => 25, 26 => 25, 27 => 25,
	);
	is bonus($_), $want{$_}, "$_ pips score $want{$_}" for sort { $a <=> $b } keys %want;

	is bonus(-4), 0, 'and nothing sensible comes of negative pips';
	is bonus(undef), 0, 'or of none at all';
};

subtest 'the pips are added up first and rounded ONCE' => sub {
	plan tests => 3;

	# This is the one place two published rules genuinely differ in their
	# answer, and it is invisible at two seats because there is only one
	# opponent to round.
	#
	#   Pagat All Fives:  "the total of the pips on the tiles remaining in the
	#                      opponents' hands, rounded up or down to the nearest
	#                      multiple of five"      -> add, then round once
	#   Wikipedia Muggins: "Each opponent's hand is rounded to the nearest
	#                      multiple of five ... These points are summed"
	#                                             -> round each, then add
	#
	# We play All Fives, so we add first. Three opponents on thirteen pips
	# each is the smallest case that tells the two apart.
	is bonus(13 + 13 + 13), 40, 'three hands of thirteen total 39 and round to 40';
	isnt bonus(13) * 3, bonus(13 + 13 + 13),
		'rounding each hand first would give a different answer';
	is bonus(13) * 3, 45, 'namely 45, which is the rule we did NOT take';
};

subtest 'a game really does add before rounding' => sub {
	plan tests => 2;

	# The unit test above proves the arithmetic. This proves the engine uses
	# it, which is a different claim and the one that could rot.
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 4);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(6, 6), tile(1, 0) ]);
	$g->hands->{3} = Game::Dominoes::Hand->new(tiles => [ tile(6, 5), tile(2, 0) ]);
	$g->hands->{4} = Game::Dominoes::Hand->new(tiles => [ tile(5, 4), tile(3, 1) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => []));
	$g->turn(1);
	$g->scores({ map { $_ => 0 } 1 .. 4 });
	$g->history([]);

	is $g->hand($_)->pips, 13, "seat $_ holds thirteen pips" for 2;

	# Seat 1 plays its only tile and goes out. 6-4 as the opening lead counts
	# ten and scores ten, then the bonus is 39 pips rounded once to 40.
	$g->play(1, '6-4@L');
	is $g->scores->{1}, 10 + 40,
		'the seat that went out scored the lead plus one rounding of 39';
};

subtest 'a blocked hand pays the lightest hand' => sub {
	plan tests => 2;

	# "If the game is blocked the player or team with fewest points on tiles
	# remaining in hand is considered the winner."
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 0) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(5, 5) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => []));
	$g->turn(1);
	$g->scores({ 1 => 0, 2 => 0 });
	$g->history([]);

	$g->play(1, '6-4@L');

	my ($end) = grep { $_->{kind} eq 'hand_end' } @{ $g->history };
	is $end->{seat}, 1, 'seat 1 holds one pip against ten, so it is lighter';
	is $g->scores->{1}, 10 + 10,
		'and scores the lead plus the loser ten pips';
};

subtest 'a tie for lightest is settled by the source, not by us' => sub {
	plan tests => 3;

	# This was written down as a house rule imported from Pagat Draw Dominoes
	# until the All Fives page was actually read. It settles it itself, and
	# with a three seat case nobody would guess:
	#
	#   "If there is a tie for least points in a blocked two-player or
	#    four-player game no one scores for the remaining tiles. In a
	#    three-player game if two players tie for least they split the third
	#    player's points between them."
	# Distinct tiles of equal weight: a double six set holds one of each, so
	# two seats cannot both hold the 2-0. A fixture that models an impossible
	# position can pass while proving nothing.
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(2, 0) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(1, 1) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => []));
	$g->turn(1);
	$g->scores({ 1 => 0, 2 => 0 });
	$g->history([]);

	$g->play(1, '6-4@L');

	my ($end) = grep { $_->{kind} eq 'hand_end' } @{ $g->history };
	is $end->{reason}, 'blocked_tied', 'both seats hold two pips, so it is a tie';
	is $end->{points}, 0, 'and at two seats nobody scores for the remaining tiles';
	is $g->scores->{1}, 10, 'the lead still scored, but no bonus was paid';
};

subtest 'at three seats a tie splits the third seat pips' => sub {
	plan tests => 4;

	# "In a three-player game if two players tie for least they split the
	# third player's points between them." This is the oddest rule on the
	# page and it exists nowhere else in the family, so it is implemented as
	# written rather than smoothed into the two and four seat rule.
	my $g = Game::Dominoes->new(seed => 'a' x 32, players => 3);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(2, 0) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(1, 1) ]);
	$g->hands->{3} = Game::Dominoes::Hand->new(tiles => [ tile(5, 5), tile(3, 0) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => []));
	$g->turn(1);
	$g->scores({ 1 => 0, 2 => 0, 3 => 0 });
	$g->history([]);

	$g->play(1, '6-4@L');

	my ($end) = grep { $_->{kind} eq 'hand_end' } @{ $g->history };
	is $end->{reason}, 'blocked_split', 'seats 1 and 2 tie on two pips each';

	# Seat 3 holds thirteen pips, which round to fifteen. Fifteen does not
	# halve evenly, and the page does not say what happens to the odd point.
	# HOUSE RULE, and the only one left in this ruleset: the remainder goes
	# to the lower seat.
	is $end->{points}, 15, 'the third seat thirteen pips round to fifteen';
	is $g->scores->{1}, 10 + 8, 'the lower seat takes the larger half';
	is $g->scores->{2}, 7, 'and the other takes the rest';
};
