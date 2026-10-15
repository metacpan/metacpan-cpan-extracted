#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Bot;

sub save { return $_[0]->to_text }

sub load { return Game::Reversi->from_text($_[0]) }

sub bot { return Game::Reversi::Bot->new(level => 2, seed => 'round-trip') }

sub squares {
	my ($game) = @_;
	return [ map { [ map { $_->square } @{ $game->legal($_) } ] } $game->seats ];
}

sub next_three {
	my ($game) = @_;
	my $bot = bot();
	my @move;
	for (1 .. 3) {
		my ($colour) = $game->waiting_on or last;
		my $move = $bot->choose($game, $colour) or last;
		$game->play($colour, $move->square);
		push @move, "$colour:" . $move->square;
	}
	return join ' ', @move;
}

sub play {
	my ($game, $plies) = @_;
	my $bot = bot();
	while ($game->status eq 'active' && $plies--) {
		my ($colour) = $game->waiting_on;
		$game->play($colour, $bot->choose($game, $colour)->square);
	}
	return $game;
}

sub fresh { return Game::Reversi->new(seed => 'x' x 32, @_) }

sub round_trip {
	my ($game, $label) = @_;
	subtest $label => sub {
		plan tests => 9;
		my $text = save($game);
		my $loaded = load($text);
		isnt($loaded, $game, 'the load is a new game');
		is(save($loaded), $text, 'save(load(save)) is save');
		is_deeply(squares($loaded), squares($game), 'the same legal moves');
		is_deeply($loaded->board, $game->board, 'the same board');
		is($loaded->turn, $game->turn, 'the same colour on turn');
		is_deeply($loaded->events, $game->events, 'the same log, forfeits and ending included');
		is(next_three(load($text)), next_three($game->clone),
			'the bot plays the same next three moves');
		is($loaded->seed, $game->seed, 'the same seed when the game is over');
		if (my ($colour) = $loaded->waiting_on) {
			$loaded->play($colour, bot()->choose($loaded, $colour)->square);
		}
		is(save($game), $text, 'playing on the load leaves the original alone');
	};
}

round_trip(fresh(), 'at the start');

round_trip(play(fresh(), 3), 'after three moves');

my $capture = fresh();
my $bot = bot();
while ($capture->status eq 'active') {
	my ($colour) = $capture->waiting_on;
	last if @{ $capture->play($colour, $bot->choose($capture, $colour)->square)->flips };
}
ok(scalar(grep { $_->{kind} eq 'play' } @{ $capture->events }), 'a disc was turned');
round_trip($capture, 'after a capture');

my $full = play(fresh(), 1000);
is($full->status, 'finished', 'the bot plays a game to its end');
my $plies = grep { $_->{kind} eq 'place' || $_->{kind} eq 'play' } @{ $full->events };
round_trip(play(fresh(), $plies - 4), 'late in the game, four plies before its end');
round_trip($full, 'at the end, by ' . $full->result->result);

my $resigned = play(fresh(), 7);
$resigned->resign('b');
round_trip($resigned, 'after a resignation');
is(load(save($resigned))->winner, 'w', 'the resignation comes back as one');

my $timed = play(fresh(), 6);
$timed->timeout('w');
round_trip($timed, 'after a timeout');

my $abandoned = play(fresh(), 5);
$abandoned->abandon;
round_trip($abandoned, 'after an abandonment');

round_trip(play(fresh(variant => 'othello', turn => 'w'), 9), 'othello, white first');
like(save(fresh(variant => 'othello', turn => 'w')), qr/^variant othello\nfirst w\n/,
	'the variant and the first colour are named');

my $board = Game::Reversi->new(variant => 'othello')->board;
$board->[0] = 'w';
my $set = play(Game::Reversi->from_board($board, seed => "\x{e9}t\x{e9}"), 6);
like(save($set), qr/^board w\.{26}/m, 'a game from a board names it');
round_trip($set, 'from a board of its own');

round_trip(play(Game::Reversi->new, 5), 'with no seed');

subtest 'malformed text is refused with a message' => sub {
	plan tests => 6;
	eval { load('f5 zz') };
	like($@, qr/cannot read 'zz' as a transcript/, 'a square that is not one');
	eval { load("variant go\nd4") };
	like($@, qr/^Game::Reversi: there is no variant 'go'/, 'a variant that is not one');
	eval { load("board bw\nd4") };
	like($@, qr/^Game::Reversi: a board is 64 squares/, 'a board that is not one');
	eval { load("d4\nresign x") };
	like($@, qr/^Game::Reversi: 'resign x' does not name a colour/, 'a resignation by nobody');
	eval { load("d4\nabandon\ne4") };
	like($@, qr/^Game::Reversi: the transcript has moves after its ending/, 'moves after the end');
	eval { load(save($full) . "\nresign b") };
	like($@, qr/the moves already end the game/, 'an ending after the moves have ended it');
};

done_testing;
