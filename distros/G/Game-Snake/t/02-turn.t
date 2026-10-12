#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Snake;

# TWO HEADINGS MAY WAIT. 0.11 changed heading the instant a key was pressed
# and sampled once a move, so two quick presses lost one. Here the first
# queued heading is what the next tick follows and a third press replaces
# the second, which is the site's rule. Reverse and same-direction are
# judged against the heading that will be in effect when the new one lands.

subtest 'the refusals' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8);

	is($game->turn('left'), 0, 'the heading it has is refused');
	is($game->error->code, 'same_direction', 'as same_direction');
	like($game->error->message, qr/already heading/, 'with a sentence');
	is($game->error->stringify, 'same_direction: ' . $game->error->message, 'and stringify joins them');
	is($game->error->error, 1, 'and error is 1');

	is($game->turn('right'), 0, 'the opposite is refused');
	is($game->error->code, 'reverse', 'as reverse');

	is($game->turn('up'), 1, 'a perpendicular is taken');
	is($game->error, undef, 'and the error is cleared');

	my $bad = eval { $game->turn('north'); 1 };
	like($@, qr/'north' is not a direction/, 'a word that is not a direction dies');

	$game->quit;
	is($game->turn('down'), 0, 'a turn on a finished game is refused');
	is($game->error->code, 'not_active', 'as not_active');
};

subtest 'the queue is two deep' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8);
	ok($game->turn('up'), 'up');
	ok($game->turn('left'), 'then left, both taken in one tick');
	$game->tick;
	is($game->heading, 'up', 'the first tick follows the first');
	$game->tick;
	is($game->heading, 'left', 'the second tick follows the second');
};

subtest 'a third press replaces the second' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8);
	ok($game->turn('up'), 'up');
	ok($game->turn('left'), 'left');
	ok($game->turn('right'), 'right, which replaces left');
	$game->tick;
	is($game->heading, 'up', 'up first');
	$game->tick;
	is($game->heading, 'right', 'then right, never left');
};

subtest 'reverse is judged against what will be in effect' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8);
	ok($game->turn('up'), 'heading left, up is queued');
	is($game->turn('down'), 0, 'down would reverse the queued up');
	is($game->error->code, 'reverse', 'and is refused as reverse');
	is($game->turn('up'), 0, 'up again is the same direction as the queued up');
	is($game->error->code, 'same_direction', 'and is refused as such');
	ok($game->turn('right'), 'right after up is fine, though it is the reverse of the current heading');
};

subtest 'a turn while ready is kept for the first tick' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8);
	is($game->status, 'ready', 'ready');
	ok($game->turn('up'), 'up is queued');
	is($game->status, 'ready', 'and the game is still ready');
	my $step = $game->tick;
	is($game->status, 'active', 'the first tick makes it active');
	is($game->heading, 'up', 'heading up');
	is_deeply([ $game->segments->[0]{x}, $game->segments->[0]{y} ], [ 3, 4 ], 'and the head went up');
};

subtest 'the error class' => sub {
	my $error = eval { Game::Snake::Error->of('bogus') };
	like($@, qr/'bogus' is not a code/, 'an unknown code dies');
	$error = eval { Game::Snake::Error->new(code => 'bogus', message => 'x') };
	like($@, qr/'bogus' is not a code/, 'and so does building one directly');
	$error = eval { Game::Snake::Error->of(undef) };
	like($@, qr/'undef' is not a code/, 'as does no code at all');
	is_deeply(Game::Snake::Error->codes, [qw/ same_direction reverse not_active /], 'the codes are listed');
	my $messages = Game::Snake::Error->messages;
	is_deeply([ sort keys %$messages ], [ sort @{ Game::Snake::Error->codes } ], 'each with a sentence');
	ok(length $messages->{$_}, "$_ has one") for @{ Game::Snake::Error->codes };
	is(Game::Snake::Error->of('reverse')->message, $messages->{reverse}, 'and of hands the sentence over');
};

done_testing();
