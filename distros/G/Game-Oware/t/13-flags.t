#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Error;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# Every error flag, produced by a real refusal.
#
# The point of the closing subtest is that the list of flags this class declares
# and the list a game can actually produce are THE SAME LIST. A flag nothing can
# raise becomes a sentence in a consumer's catalogue that no player will ever
# see and a translator will still be asked to translate, and there is no way to
# notice except by asserting it here.

sub game {
	my (@houses) = @_;
	return Game::Oware->new(seed => 'x' x 32) unless @houses;
	my $seeds = 0;
	$seeds += $_ for @houses;
	return Game::Oware->new(
		seed => 'x' x 32, board => [ @houses, 48 - $seeds, 0 ]);
}

my @refusals = (
	[
		'not_your_turn', 'p2 moves at the opening, and p1 is on turn',
		sub { game()->play('p2', 6) },
	],
	[
		'not_your_house', 'p1 plays a house on the far row',
		sub { game()->play('p1', 6) },
	],
	[
		'empty_house', 'p1 plays a house with nothing in it',
		sub { game(0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4)->play('p1', 0) },
	],
	[
		'must_feed', 'p2 is starved and p1 plays a house that does not reach',
		sub { game(3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0)->play('p1', 0) },
	],
	[
		'game_over', 'anything at all, once the game has finished',
		sub {
			my $game = game();
			$game->resign('p1');
			return $game->play('p2', 6);
		},
	],
);

my %produced;

for my $refusal (@refusals) {
	my ($flag, $description, $provoke) = @$refusal;

	subtest "$flag: $description" => sub {
		my $error = $provoke->();

		isa_ok($error, 'Game::Oware::Error');
		is($error->code, $flag, "the flag is $flag");
		ok($error->error, 'and error is true, so a caller need not know which');
		ok(length $error->message, 'and it carries a sentence');

		$produced{$flag} = 1;
	};
}

subtest 'between them those refusals produce every flag the class declares' => sub {
	is_deeply([ sort keys %produced ], [ sort @{ Game::Oware::Error->flags } ],
		'no flag is unreachable, and none is missing a test');

	is_deeply([ sort keys %{ Game::Oware::Error->messages } ],
		[ sort @{ Game::Oware::Error->flags } ],
		'and every flag has a sentence');
};

# PRECEDENCE. A move can be wrong in more than one way at once, and which
# refusal comes back has to be the same every time or a consumer cannot map it
# to a message. Turn is decided before anything about the move itself.
subtest 'not_your_turn is decided before anything about the move' => sub {
	my $game = game(4, 4, 4, 4, 4, 4, 0, 4, 4, 4, 4, 4);

	my $error = $game->play('p2', 6);

	is($error->code, 'not_your_turn',
		'off turn, playing an empty house, and the turn is what comes back');
};

subtest 'game_over is decided before the turn' => sub {
	my $game = game();
	$game->resign('p1');

	is($game->play('p1', 99999 % 12)->code, 'game_over', 'finished beats everything');
};

subtest 'must_feed carries the moves that would have worked' => sub {
	my $game = game(3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

	my $error = $game->play('p1', 0);

	is($error->code, 'must_feed', 'the flag');
	is_deeply($error->legal, [ 5 ],
		'and the house that does reach, because counting seeds is not the player job');
};

subtest 'an unknown flag is programmer error' => sub {
	eval { Game::Oware::Error->throw('no_such_flag') };
	like($@, qr/is not an error flag/, 'it dies rather than inventing a sentence');

	eval { Game::Oware::Error->throw(undef) };
	like($@, qr/is not an error flag/, 'and so does nothing at all');
};

subtest 'an out of range house is programmer error, not a refusal' => sub {
	my $game = game();

	eval { $game->play('p1', 99) };
	like($@, qr/a house is 0 to 11/,
		'a consumer validates its own input at its own boundary');
};

done_testing;
