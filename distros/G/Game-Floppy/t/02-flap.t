#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Floppy;

# ONE FLAP A TICK, applied on the tick after it is asked for: 176 + 3 - 30 is
# 149. A second flap before the tick is refused and 149 stands. The tilt goes
# to -45 on the flap and climbs one a tick to 45.

subtest 'a flap lands on the next tick' => sub {
	my $game = Game::Floppy->new;
	is($game->flap, 1, 'a flap while ready is taken');
	is($game->status, 'ready', 'and the game is still ready');
	is($game->bird->{y}, 176, 'nothing moved yet');
	my $step = $game->tick;
	is($game->status, 'active', 'the first tick makes it active');
	is($game->bird->{y}, 149, 'the bird fell 3 and rose 30');
	is($step->{flapped}, 1, 'the step says it flapped');
	is($game->tick->{flapped}, 0, 'the next does not');
	is($game->bird->{y}, 152, 'and the bird fell 3');
};

subtest 'a second flap in one tick is refused' => sub {
	my $game = Game::Floppy->new;
	ok($game->flap, 'the first');
	is($game->flap, 0, 'the second is refused');
	is($game->error->code, 'already_flapped', 'as already_flapped');
	is($game->error->message, 'one flap a tick', 'with its sentence');
	is($game->error->stringify, 'already_flapped: one flap a tick', 'and stringify');
	$game->tick;
	is($game->bird->{y}, 149, 'the tick lifted 30 once, not 60');
	ok($game->flap, 'a flap is taken again after the tick');
	is($game->error, undef, 'and the error is cleared');
};

subtest 'a flap on a finished game is refused' => sub {
	my $game = Game::Floppy->new;
	$game->quit;
	is($game->flap, 0, 'refused');
	is($game->error->code, 'not_active', 'as not_active');
};

subtest 'the tilt' => sub {
	my $game = Game::Floppy->new;
	$game->tick for 1 .. 10;
	is($game->bird->{tilt}, 10, 'one a tick from level');
	$game->tick for 1 .. 35;
	is($game->bird->{tilt}, 45, 'reaching 45 at tick 45');
	$game->tick;
	is($game->bird->{tilt}, 45, 'and staying there');
	$game->flap;
	$game->tick;
	is($game->bird->{tilt}, -44, '-45 on the flap and one up in the same tick');
	$game->tick;
	is($game->bird->{tilt}, -43, 'then one a tick');
};

subtest 'the error class' => sub {
	my $bad = eval { Game::Floppy::Error->of('bogus') };
	like($@, qr/'bogus' is not a code/, 'an unknown code dies');
	$bad = eval { Game::Floppy::Error->new(code => 'bogus', message => 'x') };
	like($@, qr/'bogus' is not a code/, 'and so does building one directly');
	is_deeply(Game::Floppy::Error->codes, [qw/ not_active already_flapped /], 'the codes are listed');
	my $messages = Game::Floppy::Error->messages;
	ok(length $messages->{$_}, "$_ has a sentence") for @{ Game::Floppy::Error->codes };
};

done_testing();
