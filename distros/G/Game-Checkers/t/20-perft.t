#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;
use Game::Checkers::Rules;

sub perft {
	my ($position, $turn, $depth) = @_;
	my $moves = Game::Checkers::Rules::generate($position, $turn);
	return scalar @{$moves} if $depth <= 1;
	my $nodes = 0;
	my $next = $turn eq 'black' ? 'white' : 'black';
	for my $raw (@{$moves}) {
		Game::Checkers::Rules::apply($position, $raw);
		$nodes += perft($position, $next, $depth - 1);
		Game::Checkers::Rules::unapply($position, $raw);
	}
	return $nodes;
}

sub position_of {
	my ($fen) = @_;
	my $game = $fen ? Game::Checkers->new(fen => $fen) : Game::Checkers->new;
	return ([@{$game->board->position}], $game->turn);
}

subtest 'the first two depths, derived by hand' => sub {
	plan tests => 9;
	my $game = Game::Checkers->new;
	is_deeply [map { $_->notation } @{$game->legal_moves}],
		[qw/9-13 9-14 10-14 10-15 11-15 11-16 12-16/],
		'seven opening moves, which is perft(1)';

	# After one move each, no black man is next to a white one: Black reaches
	# row 3 at the furthest and White starts on row 5. So every one of Black's
	# seven moves leaves White all seven of its own, and perft(2) is 7 times 7.
	for my $opening (@{$game->legal_moves}) {
		my $after = $game->clone;
		$after->move($opening);
		is scalar @{$after->legal_moves}, 7,
			'White still has seven after ' . $opening->notation;
	}

	my ($position, $turn) = position_of();
	is perft($position, $turn, 2), 49, 'so perft(2) is 49';
};

subtest 'two branches of the third depth, also by hand' => sub {
	plan tests => 2;
	# After 11-15 23-19 the men on 7 and 8 can step into the square 11 left
	# behind, 9 has both its moves, 10 and 12 have one each, 15 can go to 18 but
	# not to 19, and the back four are all blocked by their own men: seven.
	my $quiet = Game::Checkers->new;
	$quiet->move($_) for qw/11-15 23-19/;
	is_deeply [map { $_->notation } @{$quiet->legal_moves}],
		[qw/7-11 8-11 9-13 9-14 10-14 12-16 15-18/],
		'a quiet branch has seven replies';

	# and after 11-15 22-18 the capture is compulsory, so the branch has one
	my $capture = Game::Checkers->new;
	$capture->move($_) for qw/11-15 22-18/;
	is_deeply [map { $_->notation } @{$capture->legal_moves}], ['15x22'],
		'a branch with a jump in it has one';
};

subtest 'the published ladder' => sub {
	plan tests => 5;
	# Aart Bik's perft numbers for 8x8 English draughts from the starting
	# position, posted in "perft for 8x8 checkers" on TalkChess:
	# https://talkchess.com/viewtopic.php?t=27814
	#
	#   1: 7   2: 49   3: 302   4: 1469   5: 7361
	#   6: 36768   7: 179740   8: 845931   9: 3963680   10: 18391564
	#
	# His generator counts a king's captures of the same pieces in different
	# orders separately, and so does this one, which is what makes the two
	# comparable. That case first arises at depth 12, below anything asserted
	# here or in xt/perft-deep.t.
	my @published = (7, 49, 302, 1469, 7361);
	my ($position, $turn) = position_of();
	for my $depth (1 .. @published) {
		is perft($position, $turn, $depth), $published[$depth - 1],
			"perft($depth) is $published[$depth - 1]";
	}
};

subtest 'apply and unapply are exact inverses' => sub {
	plan tests => 2;
	# perft above walks one array, mutating and restoring it. The same count
	# taken on a fresh copy at every node cannot be wrong in the same way, so
	# the two agreeing is what says unapply restores everything, kings and
	# captured pieces included.
	my $copying;
	$copying = sub {
		my ($position, $turn, $depth) = @_;
		my $moves = Game::Checkers::Rules::generate($position, $turn);
		return scalar @{$moves} if $depth <= 1;
		my $nodes = 0;
		for my $raw (@{$moves}) {
			my $fresh = [@{$position}];
			Game::Checkers::Rules::apply($fresh, $raw);
			$nodes += $copying->($fresh, $turn eq 'black' ? 'white' : 'black', $depth - 1);
		}
		return $nodes;
	};

	my ($opening, $turn) = position_of();
	is perft($opening, $turn, 5), $copying->($opening, $turn, 5),
		'the same count from the opening, whether the board is restored or copied';

	my ($kings, $king_turn) = position_of('B:WK24,K27,K32:BK1,K9,K18');
	is perft($kings, $king_turn, 4), $copying->($kings, $king_turn, 4),
		'and from a position of nothing but kings, where undoing has most to do';
};

subtest 'positions the opening never reaches' => sub {
	plan tests => 4;
	# REGRESSION BASELINES, not a proof. These numbers came from this
	# distribution's own generator on 13 Sep 2026 and no published table
	# covers them: they say that today's generator counts what yesterday's
	# did, and nothing more. The published ladder above is the correctness
	# check; these four positions are here because the opening exercises
	# neither a jump nor a crowning, and that is where generators go wrong.
	my %expect = (
		# a man crowning in the middle of a jump, from t/08
		'B:W21,26,27:B22' => [1, 3, 5, 14],

		# nothing but kings, so every piece moves and jumps in four directions
		'B:WK24,K27,K32:BK1,K9,K18' => [10, 55, 411, 2478],

		# a midgame with twenty pieces, from a level 2 self play game
		'B:W18,21,23,24,26,27,28,29,31,32:B1,2,3,4,5,8,11,12,13,16'
			=> [9, 51, 273, 1551],

		# a midgame that opens with a compulsory capture
		'B:W13,14,15,27,28,29,31,32:B1,4,5,7,8,11,12' => [1, 8, 42, 234],
	);

	for my $fen (sort keys %expect) {
		my ($position, $turn) = position_of($fen);
		is_deeply [map { perft($position, $turn, $_) } 1 .. 4], $expect{$fen},
			"perft 1 to 4 from $fen";
	}
};

done_testing;
