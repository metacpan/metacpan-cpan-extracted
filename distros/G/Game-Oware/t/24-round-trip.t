#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Bot;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

sub save { return $_[0]->to_text }

sub load { return Game::Oware->from_text($_[0]) }

sub bot { return Game::Oware::Bot->new(level => 2, seed => 'round-trip') }

sub next_three {
	my ($game) = @_;
	my $bot = bot();
	my @move;
	for (1 .. 3) {
		my ($seat) = $game->waiting_on or last;
		my $house = $bot->choose($game, $seat);
		last unless defined $house;
		$game->play($seat, $house);
		push @move, "$seat:$house";
	}
	return join ' ', @move;
}

sub play {
	my ($game, $plies) = @_;
	my $bot = bot();
	while ($game->status eq 'active' && $plies--) {
		my ($seat) = $game->waiting_on;
		$game->play($seat, $bot->choose($game, $seat));
	}
	return $game;
}

sub fresh { return Game::Oware->new(seed => 'x' x 32, @_) }

sub round_trip {
	my ($game, $label) = @_;
	subtest $label => sub {
		plan tests => 10;
		my $text = save($game);
		my $loaded = load($text);
		isnt($loaded, $game, 'the load is a new game');
		is(save($loaded), $text, 'save(load(save)) is save');
		is_deeply([ map { $loaded->legal($_) } $loaded->seats ],
			[ map { $game->legal($_) } $game->seats ], 'the same legal moves');
		is_deeply($loaded->board, $game->board, 'the same board');
		is($loaded->no_capture, $game->no_capture, 'the same cycle counter');
		is_deeply($loaded->seen, $game->seen, 'the same positions seen');
		is_deeply($loaded->events, $game->events, 'the same log');
		is(next_three(load($text)), next_three($game->clone),
			'the bot plays the same next three moves');
		is($loaded->seed, $game->seed, 'the same seed when the game is over');
		if (my ($seat) = $loaded->waiting_on) {
			$loaded->play($seat, bot()->choose($loaded, $seat));
		}
		is(save($game), $text, 'playing on the load leaves the original alone');
	};
}

round_trip(fresh(), 'at the start');

round_trip(play(fresh(), 3), 'after three moves');

my $capture = fresh();
my $bot = bot();
while ($capture->status eq 'active') {
	my ($seat) = $capture->waiting_on;
	last if $capture->play($seat, $bot->choose($capture, $seat))->taken;
}
cmp_ok($capture->captured->{p1} + $capture->captured->{p2}, '>', 0, 'a capture was made');
round_trip($capture, 'after a capture');

my $full = play(fresh(), 1000);
is($full->status, 'finished', 'the bot plays a game to its end');
my $plies = grep { $_->{kind} eq 'sow' } @{ $full->events };
round_trip(play(fresh(), $plies - 4), 'late in the game, four plies before its end');
round_trip($full, 'at the end, by ' . $full->result->reason);

my $resigned = play(fresh(), 7);
$resigned->resign('p1');
round_trip($resigned, 'after a resignation');
is(load(save($resigned))->winner, 'p2', 'the resignation comes back as one');

my $timed = play(fresh(), 6);
$timed->timeout('p2');
round_trip($timed, 'after a timeout');

my $abandoned = play(fresh(), 5);
$abandoned->abandon;
round_trip($abandoned, 'after an abandonment');

my $other = play(fresh(variant => 'awari', turn => 'p2', board => [ 3, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0 ]), 9);
like(save($other), qr/^variant awari\nfirst p2\nboard 3,5,/, 'a variant, a first seat and a board are named');
round_trip($other, 'awari, p2 first, from a board of its own');

round_trip(play(Game::Oware->new, 5), 'with no seed');

subtest 'malformed text is refused with a message' => sub {
	plan tests => 6;
	eval { load('EE') };
	like($@, qr/the seats alternate/, 'two moves by one seat');
	eval { load("variant ludo\nEc") };
	like($@, qr/^Game::Oware: there is no variant 'ludo'/, 'a variant that is not one');
	eval { load("seed xyz\nEc") };
	like($@, qr/^Game::Oware: a seed is written in hexadecimal/, 'a seed that is not hexadecimal');
	eval { load("Ec\nresign p3") };
	like($@, qr/^Game::Oware: 'resign p3' does not name a seat/, 'a resignation by no seat');
	eval { load("Ec\nresign p1\nAb") };
	like($@, qr/^Game::Oware: the transcript has moves after its ending/, 'moves after the end');
	eval { load(save($full) . "\nresign p1") };
	like($@, qr/the moves already end the game/, 'an ending after the moves have ended it');
};

done_testing;
