#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware::Move;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# Game::Oware::Move is a value object, so everything here is about what it
# REFUSES. Each refusal is something no correct engine can produce, which is why
# they die rather than returning an error object: a player's bad move is a
# Game::Oware::Error and never reaches this class.

subtest 'a plain move' => sub {
	my $move = Game::Oware::Move->new(
		seat => 'p1', house => 4, sown => 6, last => 10);

	is($move->seat, 'p1', 'seat');
	is($move->house, 4, 'house');
	is($move->sown, 6, 'sown');
	is($move->last, 10, 'last');
	is_deeply($move->captured, [], 'captured nothing');
	is($move->taken, 0, 'took nothing');
	is($move->slammed, 0, 'and did not slam');

	is($move->name, 'E', 'it names itself in notation');
	is($move->stringify, 'E', 'and reads as just the house');
};

subtest 'a capturing move' => sub {
	my $move = Game::Oware::Move->new(
		seat => 'p1', house => 4, sown => 6, last => 10,
		captured => [ 10, 9, 8 ], taken => 8);

	is_deeply($move->captured, [ 10, 9, 8 ], 'the houses, in walk-back order');
	is($move->taken, 8, 'and the count');
	is($move->stringify, 'E takes 8', 'which is what it reads as');
};

subtest 'a forfeited slam' => sub {
	my $move = Game::Oware::Move->new(
		seat => 'p1', house => 4, sown => 6, last => 10,
		slammed => 1, forfeited => [ 10, 9, 8 ]);

	ok($move->slammed, 'it slammed');
	is_deeply($move->captured, [], 'and so it captured nothing');
	is_deeply($move->forfeited, [ 10, 9, 8 ], 'but it says what it gave back');
	is($move->taken, 0, 'and took nothing');
	is($move->stringify, 'E (slam forfeited)',
		'and says so, because otherwise the rule reads as a bug');
};

# Under illegal_unless_only a slammed move captures normally, which is why slammed
# and forfeited are two fields rather than one flag meaning two things.
subtest 'a slam that was allowed to capture' => sub {
	my $move = Game::Oware::Move->new(
		seat => 'p1', house => 4, sown => 6, last => 10,
		slammed => 1, captured => [ 10, 9, 8 ], taken => 8);

	ok($move->slammed, 'it slammed');
	is_deeply($move->forfeited, [], 'and gave nothing back');
	is($move->stringify, 'E takes 8 (slam)', 'and reads as what it was');
};

subtest 'what it refuses' => sub {
	eval {
		Game::Oware::Move->new(seat => 'p3', house => 0, sown => 1, last => 1);
	};
	like($@, qr/seat must be p1 or p2/, 'there are two seats');

	eval {
		Game::Oware::Move->new(seat => 'p1', house => 6, sown => 1, last => 7);
	};
	like($@, qr/only sow from its own house/, 'p1 cannot sow from p2 row');

	eval {
		Game::Oware::Move->new(seat => 'p1', house => 0, sown => 0, last => 1);
	};
	like($@, qr/sows at least one seed/, 'a move moves something');

	eval {
		Game::Oware::Move->new(seat => 'p1', house => 12, sown => 1, last => 1);
	};
	like($@, qr/a house is 0 to 11/, 'a store is not a house');

	# A hand of two seeds touched two houses, so a chain of three describes a
	# capture the sowing never reached.
	eval {
		Game::Oware::Move->new(seat => 'p1', house => 0, sown => 2, last => 2,
			captured => [ 2, 1, 11 ], taken => 6);
	};
	like($@, qr/never captures more houses than it sowed/,
		'the chain cannot outrun the hand');

	eval {
		Game::Oware::Move->new(seat => 'p1', house => 0, sown => 8, last => 8,
			captured => [ 8, 7, 6, 5 ], taken => 9);
	};
	like($@, qr/never captures its own house/, 'and it stops at your own row');

	# The houses here are p2's, so that these refusals are reached rather than
	# the own-house one above them. An earlier draft used a p1 house and passed
	# for the wrong reason.
	eval {
		Game::Oware::Move->new(seat => 'p1', house => 0, sown => 9, last => 8,
			slammed => 1, captured => [ 8 ], taken => 2, forfeited => [ 9 ]);
	};
	like($@, qr/either captured its chain or forfeited it/,
		'a move cannot do both');

	eval {
		Game::Oware::Move->new(seat => 'p1', house => 0, sown => 9, last => 8,
			forfeited => [ 8 ]);
	};
	like($@, qr/only a grand slam forfeits/, 'nothing else gives a chain back');

	# A forfeited chain that took seeds anyway is caught by the check above
	# this one, because a forfeit captures nothing and `taken` without
	# `captured` is already a refusal. A separate die for it would never be
	# reached, which is the sort of unreachable branch t/13-flags.t exists to
	# find, so there is not one.
	eval {
		Game::Oware::Move->new(seat => 'p1', house => 0, sown => 9, last => 8,
			slammed => 1, forfeited => [ 8 ], taken => 2);
	};
	like($@, qr/taken disagrees with captured/, 'and a forfeit takes no seeds');
};

# D8. The site's view-leak gate bans `score` singular with an anchored regex,
# and Oware's natural English for a store is a "score house". The field is
# invented here, eight phases before the gate is written.
subtest 'no field is called score, or line' => sub {
	open my $fh, '<', 'lib/Game/Oware/Move.pm'
		or plan skip_all => 'run from the distribution root';
	my $source = do { local $/; <$fh> };
	close $fh;

	$source =~ s/^__END__.*\z//ms;

	unlike($source, qr/^has \s+ score\b/mx, 'no property called score');
	unlike($source, qr/^has \s+ line\b/mx, 'and none called line');
	like($source, qr/^has \s+ taken\b/mx, 'the count is taken');
	like($source, qr/^has \s+ captured\b/mx, 'and the houses are captured');
};

done_testing;
