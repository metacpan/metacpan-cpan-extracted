#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Error;

# Every error flag is reachable from a real refusal.
#
# THE ERROR CLASS MAKES THIS CLAIM IN ITS POD, SO THE SUITE HAS TO MAKE IT TRUE.
# A code nothing can produce is dead weight, and in this distribution it is
# worse than that: the site adapter maps every flag onto a
# P2PGames::Game::Illegal code, so a dead flag becomes a dead row in a table
# somebody has to maintain.
#
# This file lives apart from the phase that introduced each flag on purpose. The
# flag list belongs to Game::Reversi::Error, not to whichever module happens to
# raise one, and when it was kept inside t/03-opening.t the arrival of four new
# flags broke a file that had nothing to do with them. Adding a flag without
# adding the refusal that produces it fails HERE, which is where it should.

my $B = 'Game::Reversi::Board';

sub sq { return $B->square_of(split //, $_[0]) }

sub fresh { return Game::Reversi->new(variant => $_[0] || 'historic') }

# Past the four placements, so the play rules are in force.
sub in_play {
	my $game = fresh('historic');
	$game->play($game->turn, $game->legal($game->turn)->[0]->square)
		for 1 .. 4;
	die 'expected the opening to be over' if $game->phase ne 'play';
	return $game;
}

sub finished {
	my $game = fresh('historic');
	while ($game->status eq 'active') {
		my $legal = $game->legal($game->turn);
		last unless @$legal;
		$game->play($game->turn, $legal->[0]->square);
	}
	return $game;
}

my @refusals = (
	[ not_centre => 'a placement off the centre four', sub {
		my $game = fresh('historic');
		return $game->play($game->turn, sq('a1'));
	} ],
	[ square_taken => 'a placement on a centre square already used', sub {
		my $game = fresh('historic');
		my $square = $game->legal($game->turn)->[0]->square;
		$game->play($game->turn, $square);
		return $game->play($game->turn, $square);
	} ],
	[ not_your_turn => 'a move by the seat that is not on turn', sub {
		my $game = fresh('historic');
		return $game->play($B->other($game->turn), sq('d4'));
	} ],
	[ no_flip => 'a play that outflanks nothing', sub {
		my $game = in_play();
		# A corner cannot be reached on the fifth ply by any line of play, so it
		# outflanks nothing whatever the opening was.
		return $game->play($game->turn, sq('a1'));
	} ],
	[ has_move => 'a deliberate pass while a move is available', sub {
		my $game = fresh('historic');
		return $game->pass($game->turn);
	} ],
	[ game_over => 'anything at all once the game is over', sub {
		return finished()->play('b', sq('a1'));
	} ],
);

my %produced;
for my $refusal (@refusals) {
	my ($flag, $what, $make) = @$refusal;
	my $error = $make->();

	isa_ok($error, 'Game::Reversi::Error', $what);
	next unless ref $error && $error->can('code');

	is($error->code, $flag, "$what is $flag");
	ok($error->error, "$flag is true, so a caller can test the return value");
	ok(length($error->message // ''), "$flag has a sentence to show a player");
	$produced{ $error->code }++;
}

# Both sides sorted: flags returns them in declaration order, which is the order
# they were added to the class phase by phase and not an order worth asserting.
is_deeply([ sort keys %produced ], [ sort @{ Game::Reversi::Error->flags } ],
	'and between them these refusals produce every flag the class declares');

subtest 'square_taken is reachable during play as well as during the opening' => sub {
	# The same flag from a different rule. Worth having because the two paths
	# are separate pieces of code: the opening checks its own four squares, and
	# the play phase checks the whole board.
	my $game = in_play();
	my $occupied = (grep { defined $game->board->[$_] } 0 .. 63)[0];
	my $error = $game->play($game->turn, $occupied);
	is($error->code, 'square_taken', 'playing onto a disc is refused');
	done_testing();
};

subtest 'not_your_turn is decided before anything else about the move' => sub {
	# A player who is not on turn is told that, whatever else is wrong with
	# what they sent. The order matters: telling somebody their move outflanks
	# nothing, when the real problem is that it is not their go, sends them
	# looking in the wrong place.
	my $game = in_play();
	my $off = $B->other($game->turn);
	is($game->play($off, sq('a1'))->code, 'not_your_turn',
		'an illegal move by the wrong seat is not_your_turn, not no_flip');
	is($game->pass($off)->code, 'not_your_turn',
		'and so is a pass by the wrong seat, not has_move');
	done_testing();
};

subtest 'game_over outranks even that' => sub {
	my $game = finished();
	is($game->play('b', sq('a1'))->code, 'game_over', 'a move');
	is($game->play('w', sq('a1'))->code, 'game_over', 'by either seat');
	is($game->pass('b')->code, 'game_over', 'and a pass');
	done_testing();
};

subtest 'a flag the class does not know is programmer error' => sub {
	ok(!eval { Game::Reversi::Error->throw('no_such_flag'); 1 },
		'throwing an unknown flag dies rather than returning an error');
	like($@, qr/not an error flag/, 'saying so');
	done_testing();
};

done_testing();
