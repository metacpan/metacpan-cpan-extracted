#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;
use Game::Merrills::Rules;
use Game::Merrills::Test::Position qw/position_of stream/;

sub positions {
	my ($seed, $want) = @_;
	my $next = stream($seed);
	my @games;
	my $tries = 0;
	while (@games < $want && $tries++ < 20 * $want) {
		my $game = Game::Merrills->new;
		my $stop = 4 + $next->(50);
		while ($game->status eq 'active' && $game->ply < $stop) {
			my $legal = $game->legal_moves;
			$game->move($legal->[ $next->(scalar @{$legal}) ]);
		}
		push @games, $game if $game->status eq 'active' && @{ $game->legal_moves } > 1;
	}
	return @games;
}

subtest 'remembering positions changes the work, not the worth of the move' => sub {
	# With positions to spare, so that neither search is cut short. The move
	# itself may differ between two of equal worth, so it is the score that
	# is held equal.
	local $Game::Merrills::Bot::LEVEL{3} = { depth => 4, nodes => 5_000_000, jitter => 0 };
	my @games = positions(1515, 16);
	is(scalar @games, 16, 'sixteen positions');
	my ($same_score, $same_depth, $cheaper, %phase) = (0, 0, 0);
	for my $game (@games) {
		my $with = Game::Merrills::Bot->new(level => 3);
		my $without = Game::Merrills::Bot->new(level => 3, transposition => 0);
		$with->choose($game);
		$without->choose($game);
		$phase{ $game->phase }++;
		$same_score++ if $with->last_search->{score} == $without->last_search->{score};
		$same_depth++ if $with->last_search->{depth} == 4 && $without->last_search->{depth} == 4;
		$cheaper++ if $with->last_search->{nodes} <= $without->last_search->{nodes};
	}
	is($same_depth, 16, 'both looked four deep every time');
	is($same_score, 16, 'and judged their move to be worth the same');
	cmp_ok($cheaper, '>=', 12, "remembering was no dearer in $cheaper of the 16");
	cmp_ok(scalar keys %phase, '>=', 2, 'across phases: ' . join ', ', map { "$_ $phase{$_}" } sort keys %phase);
};

subtest 'out of positions, it still answers with a legal move' => sub {
	my ($game) = positions(77, 1);
	for my $nodes (1, 2, 10, 60) {
		local $Game::Merrills::Bot::LEVEL{3} = { depth => 5, nodes => $nodes, jitter => 0 };
		my $bot = Game::Merrills::Bot->new(level => 3);
		my $move = $bot->choose($game);
		ok(scalar(grep { $_ == $move } @{ $game->legal_moves }), "allowed $nodes: " . $move->notation . ' is legal');
		cmp_ok($bot->last_search->{nodes}, '<=', $nodes, 'and it looked at no more than it was allowed');
	}
	local $Game::Merrills::Bot::LEVEL{3} = { depth => 5, nodes => 2, jitter => 0 };
	my $bot = Game::Merrills::Bot->new(level => 3);
	$bot->choose($game);
	is($bot->last_search->{depth}, 0, 'with too few to finish one look, it says it finished none');
	is($bot->last_search->{score}, undef, 'and claims no score');
};

subtest 'a deeper look is not thrown away for running out part way' => sub {
	my ($game) = positions(78, 1);
	my %depth;
	for my $nodes (200, 2_000, 20_000) {
		local $Game::Merrills::Bot::LEVEL{3} = { depth => 9, nodes => $nodes, jitter => 0 };
		my $bot = Game::Merrills::Bot->new(level => 3);
		$bot->choose($game);
		$depth{$nodes} = $bot->last_search->{depth};
	}
	cmp_ok($depth{200}, '>=', 1, "200 positions finish a look $depth{200} deep");
	cmp_ok($depth{2_000}, '>=', $depth{200}, "2,000 go at least as deep: $depth{2_000}");
	cmp_ok($depth{20_000}, '>', $depth{200}, "and 20,000 go deeper: $depth{20_000}");
};

subtest 'a won game is seen, and the quickest win is the one taken' => sub {
	# white can take black to two men at once, or dither
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3 e3/], black => [qw/b2 d2 e5/],
	));
	my $bot = Game::Merrills::Bot->new(level => 3);
	my $move = $bot->choose($game);
	ok($move->is_capture, 'it takes the man: ' . $move->notation);
	cmp_ok($bot->last_search->{score}, '>', Game::Merrills::Bot::WIN - 100,
		'and scores it as a win: ' . $bot->last_search->{score});
	is($bot->last_search->{score}, Game::Merrills::Bot::WIN - 1, 'one move away');
};

subtest 'a drawn game is seen as level, not as lost or won' => sub {
	# two moves from the no-mill limit, with nothing to take: whatever is
	# played, the game is about to be drawn
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 b2 e3 g1/], black => [qw/f6 c5 d2 b4/],
		no_mill => Game::Merrills::NO_MILL_PLIES - 1,
	));
	my $bot = Game::Merrills::Bot->new(level => 3);
	$bot->choose($game);
	is($bot->last_search->{score}, 0, 'every move draws at once, and the score is nought');
};

subtest 'the bot plays by the game it is given: no flying when flying is off' => sub {
	my $position = position_of(white => [qw/b6 e3 c5/], black => [qw/a1 d1 g4 e5/]);
	my $bot = Game::Merrills::Bot->new(level => 3);
	my $flying = $bot->choose(Game::Merrills->new(position => $position));
	ok($flying->flew, 'with flying on it flies: ' . $flying->notation);
	my $walking = $bot->choose(Game::Merrills->new(position => $position, flying => 0));
	ok(!$walking->flew, 'with flying off it walks: ' . $walking->notation);
};

subtest 'a side left with no move has lost, and the bot sees it at any depth' => sub {
	# black is hemmed in at every corner but for d7: white d6-d7 shuts it
	my $position = position_of(white => [qw/d6 a4 g4 d1 c3/], black => [qw/a7 g7 a1 g1/]);
	for my $level (1, 2, 3) {
		my $bot = Game::Merrills::Bot->new(level => $level, seed => 1);
		my $game = Game::Merrills->new(position => $position);
		my $move = $bot->choose($game);
		is($move->notation, 'd6-d7', "level $level shuts the door");
		cmp_ok($bot->last_search->{score}, '>=', Game::Merrills::Bot::WIN - 1,
			'and scores it as a win in one, not as a quiet move: ' . $bot->last_search->{score});
		$game->move($move);
		is($game->result->reason, 'blocked', 'which it is');
	}
};

subtest 'a third repetition is a draw to the bot, and a side that is behind takes it' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 b2 e3 g1 c3/], black => [qw/f6 c5 d2 b4/],
	));
	$game->move($_) for qw/a7-d7 f6-f4 d7-a7 f4-f6 a7-d7 f6-f4 d7-a7/;
	is($game->status, 'active', 'black to move, and f4-f6 would bring the position round a third time');
	my $bot = Game::Merrills::Bot->new(level => 3);
	my $move = $bot->choose($game);
	is($move->notation, 'f4-f6', 'black, a man down, takes the draw');
	is($bot->last_search->{score}, 0, 'and knows it is one: the score is nought, not minus a man');
	$game->move($move);
	is($game->result->reason, 'repetition', 'and the game is drawn');
};

subtest 'with flying off, the line it expects has no flight in it' => sub {
	my $position = position_of(white => [qw/b6 e3 c5/], black => [qw/a1 d1 g4 e5/]);
	for my $flying (0, 1) {
		my $game = Game::Merrills->new(position => $position, flying => $flying);
		my $bot = Game::Merrills::Bot->new(level => 3);
		$bot->choose($game);
		my $replay = $game->clone;
		my @refused = grep { ref $replay->move($_) eq 'Game::Merrills::Error' } @{ $bot->last_search->{pv} };
		is_deeply(\@refused, [], "flying $flying: every move of its line is legal in that game: @{ $bot->last_search->{pv} }");
		cmp_ok(scalar @{ $bot->last_search->{pv} }, '>=', 2, 'and the line is more than its own first move');
	}
};

subtest 'the judgement of a position, taken on its own' => sub {
	my $opening = Game::Merrills::Rules::position(Game::Merrills->new->board);
	is(Game::Merrills::Bot::_evaluate($opening, 'white', 1), 0, 'the empty board is level for white');
	is(Game::Merrills::Bot::_evaluate($opening, 'black', 1), 0, 'and for black');

	my $one = Game::Merrills->new;
	$one->move('d2');
	my $after = Game::Merrills::Rules::position($one->board);
	my $white = Game::Merrills::Bot::_evaluate($after, 'white', 1);
	cmp_ok(abs $white, '<', 50, "one man placed is not a man gained: a man in hand counts as a man ($white)");
	is(Game::Merrills::Bot::_evaluate($after, 'black', 1), -$white, 'and what is good for one side is as bad for the other');

	my $taken = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7/], black => [qw/d6/], hand => { white => 7, black => 7 },
	));
	cmp_ok(Game::Merrills::Bot::_evaluate(Game::Merrills::Rules::position($taken->board), 'white', 1),
		'>', 90, 'nine men against eight is worth about a man');
};

subtest 'what varies a weak level varies with how far the game has gone' => sub {
	my $raw = [ undef, 5, undef, 0, 0 ];
	my %by_ply = map { Game::Merrills::Bot::_jitter(7, $_, $raw) => 1 } 0 .. 30;
	cmp_ok(scalar keys %by_ply, '>', 5, 'the same move in the same game is nudged differently on different plies');
	my %by_seed = map { Game::Merrills::Bot::_jitter($_, 3, $raw) => 1 } 0 .. 30;
	cmp_ok(scalar keys %by_seed, '>', 5, 'and differently for different seeds');
	is(Game::Merrills::Bot::_jitter(7, 3, $raw), Game::Merrills::Bot::_jitter(7, 3, $raw), 'but always the same for the same three');
	cmp_ok((sort { $b <=> $a } keys %by_ply)[0], '<', 25, 'and never by as much as a quarter of a man');
};

done_testing;
