#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;
use Game::Checkers::Bot;

sub play {
	my (%option) = @_;
	my $game = Game::Checkers->new($option{fen} ? (fen => $option{fen}) : ());
	my %bot = map {
		$_ => Game::Checkers::Bot->new(
			level => $option{level},
			seed => $option{seed}
		)
	} qw/black white/;
	my $plies = $option{plies} || 60;
	while ($game->status eq 'active' && $game->ply < $plies) {
		$game->move($bot{$game->turn}->choose($game));
	}
	return join ' ', map { $_->notation } @{$game->history};
}

subtest 'the same seed plays the same game' => sub {
	plan tests => 3;
	my $first = play(level => 2, seed => 42);
	my $second = play(level => 2, seed => 42);
	is $second, $first, 'twice through, move for move';
	ok length $first, 'and it was a game, not an empty list';

	my $third = play(level => 1, seed => 42);
	isnt $third, $first, 'a different level is a different game';
};

subtest 'the seed is live below level 3' => sub {
	plan tests => 2;
	my %game;
	$game{play(level => 1, seed => $_, plies => 8)}++ for 1 .. 20;
	cmp_ok scalar keys %game, '>', 1,
		'twenty seeds at level 1 do not all play the same game';

	my %again;
	$again{play(level => 2, seed => $_, plies => 8)}++ for 1 .. 20;
	cmp_ok scalar keys %again, '>', 1, 'nor at level 2';
};

subtest 'the seed is dead at level 3 and above' => sub {
	plan tests => 2;
	# a small endgame rather than the opening, because what is being asserted is
	# that the seed changes nothing, and a four piece tree says that in a
	# hundredth of the search
	my $endgame = 'B:W16,19,22,24:BK15';
	is play(level => 3, seed => 1, plies => 8, fen => $endgame),
		play(level => 3, seed => 999, plies => 8, fen => $endgame),
		'level 3 ignores the seed: the move is a pure function of the position';

	my $position = Game::Checkers->new(fen => $endgame);
	my $one = Game::Checkers::Bot->new(level => 4, seed => 1);
	my $other = Game::Checkers::Bot->new(level => 4, seed => 999);
	is $one->choose($position)->notation, $other->choose($position)->notation,
		'and so does level 4';
};

subtest 'the search leaves the game alone' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new;
	$game->move($_) for qw/11-15 23-19 8-11/;
	my $fen = $game->to_fen;
	my $ply = $game->ply;

	Game::Checkers::Bot->new(level => 3)->choose($game);
	is $game->to_fen, $fen, 'the position is untouched by a search';
	is $game->ply, $ply, 'and so is the history';
	is $game->status, 'active', 'and the game is still on';
};

done_testing;
