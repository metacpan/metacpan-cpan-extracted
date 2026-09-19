#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Board;
use Game::Oware::Bot;
use Game::Oware::Variant ();

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# THE SEARCH IGNORES THE CYCLE RULE, AND THIS IS WHAT MAKES THAT SAFE.
#
# D2 makes the value of a position depend on its history: the same board is a
# draw if it is the third occurrence and is not otherwise. The search does not
# carry that, so it happily evaluates lines past a point where the rule would
# already have swept the board.
#
# The engine still terminates, because the rule fires whatever the bot believes.
# That is the claim, and a claim about termination is worth nothing unless
# something runs it to the end.

my $CAP = 400;

subtest 'a bot game from the opening always ends' => sub {
	for my $trial (1 .. 5) {
		my $game = Game::Oware->new(seed => "opening-$trial");
		my %bot = map {
			$_ => Game::Oware::Bot->new(level => 2, seed => "bot-$trial-$_")
		} qw/ p1 p2 /;

		my $plies = 0;
		while ($game->status eq 'active' && $plies < $CAP) {
			my ($seat) = $game->waiting_on;
			my $house = $bot{$seat}->choose($game, $seat);
			last unless defined $house;
			$game->play($seat, $house);
			$plies++;
		}

		is($game->status, 'finished', "trial $trial finished in $plies plies");
		cmp_ok($plies, '<', $CAP, "trial $trial did not need the harness cap");
		is(Game::Oware::Board->total($game->board), 48, "trial $trial: forty-eight seeds");

		ok(defined $game->result->reason, "trial $trial ended for a stated reason");
	}
};

subtest 'a game already near the cut ends at it' => sub {
	my $limit = Game::Oware::Variant::plies_without_capture('abapa');

	my $game = Game::Oware->new(seed => 'near-the-cut');
	$game->no_capture($limit - 5);

	my %bot = map {
		$_ => Game::Oware::Bot->new(level => 3, seed => "near-$_")
	} qw/ p1 p2 /;

	my $plies = 0;
	while ($game->status eq 'active' && $plies < $CAP) {
		my ($seat) = $game->waiting_on;
		my $house = $bot{$seat}->choose($game, $seat);
		last unless defined $house;
		$game->play($seat, $house);
		$plies++;
	}

	is($game->status, 'finished', "it ended, in $plies plies");
	is($game->result->reason, 'cycle', 'and the cycle rule is what ended it');
	is(Game::Oware::Board->total($game->board), 48, 'forty-eight seeds');

	# NOT asserted: that it ends within five plies. Starting the counter near
	# the cut does not keep it there, because any capture resets it to nought,
	# and a bot that plays well captures early. The first draft of this subtest
	# demanded six plies and got ninety-eight, which is the engine behaving
	# correctly and the test asserting a thing nobody had thought through.
	diag("started five plies from the cut and ran $plies plies before the rule fired");
};

subtest 'the repeating circuit ends under a bot as well as under first-legal' => sub {
	# The only position in this distribution that repeats: one seed each in F
	# and f, everything else banked. Each seat has exactly one legal move, so
	# the bot has no choice to make and the cycle rule does all the work.
	my $game = Game::Oware->new(seed => 'circuit',
		board => [ (0) x 5, 1, (0) x 5, 1, 23, 23 ]);

	my %bot = map {
		$_ => Game::Oware::Bot->new(level => 4, seed => "circuit-$_")
	} qw/ p1 p2 /;

	my $plies = 0;
	while ($game->status eq 'active' && $plies < $CAP) {
		my ($seat) = $game->waiting_on;
		my $house = $bot{$seat}->choose($game, $seat);
		last unless defined $house;
		$game->play($seat, $house);
		$plies++;
	}

	is($plies, 24, 'twenty-four plies, two laps of the circuit');
	is($game->result->reason, 'cycle', 'ended by the cycle rule');
	is($game->result->result, 'draw', 'as a draw');
};

subtest 'a bot never returns a move the game will refuse' => sub {
	# The whole-game version of t/18's guard, at a level that searches deeply
	# enough to disagree with the shallow one.
	my $game = Game::Oware->new(seed => 'refusal');
	my %bot = map {
		$_ => Game::Oware::Bot->new(level => 3, seed => "refusal-$_")
	} qw/ p1 p2 /;

	my $refused = 0;
	my $plies = 0;

	while ($game->status eq 'active' && $plies < 200) {
		my ($seat) = $game->waiting_on;
		my $house = $bot{$seat}->choose($game, $seat);
		last unless defined $house;
		my $out = $game->play($seat, $house);
		$refused++ if ref $out && $out->isa('Game::Oware::Error');
		$plies++;
	}

	is($refused, 0, "nothing was refused across $plies plies");
};

done_testing;
