#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;

sub save { return $_[0]->to_text }

sub load { return Game::Merrills->from_text($_[0]) }

sub bot { return Game::Merrills::Bot->new(level => 2, seed => 42) }

sub legal { return join ' ', sort map { $_->notation } @{ $_[0]->legal_moves } }

sub next_three {
	my ($game) = @_;
	my $bot = bot();
	my @move;
	for (1 .. 3) {
		my $move = $bot->choose($game) or last;
		$game->move($move);
		push @move, $move->notation;
	}
	return join ' ', @move;
}

sub play {
	my ($game, $plies) = @_;
	my $bot = bot();
	while ($game->status eq 'active' && $plies--) {
		$game->move($bot->choose($game));
	}
	return $game;
}

sub round_trip {
	my ($game, $label) = @_;
	subtest $label => sub {
		plan tests => 8;
		my $text = save($game);
		my $loaded = load($text);
		isnt $loaded, $game, 'the load is a new game';
		is save($loaded), $text, 'save(load(save)) is save';
		is legal($loaded), legal($game), 'the same legal moves';
		is $loaded->to_position, $game->to_position, 'the same position and counts';
		is_deeply $loaded->repetition, $game->repetition, 'the same repetition table';
		is $loaded->flying, $game->flying, 'the same rule for flying';
		is next_three(load($text)), next_three($game->clone),
			'the bot plays the same next three moves';
		if (my $move = bot()->choose($loaded)) {
			$loaded->move($move);
		}
		elsif ($loaded->status eq 'active') {
			$loaded->offer_draw('white');
		}
		is save($game), $text, 'playing on the load leaves the original alone';
	};
}

round_trip(Game::Merrills->new, 'at the start');

round_trip(play(Game::Merrills->new, 3), 'after three moves');

my $capture = Game::Merrills->new;
my $bot = bot();
while ($capture->status eq 'active' && !grep { $_->is_capture } @{ $capture->history }) {
	$capture->move($bot->choose($capture));
}
ok scalar(grep { $_->is_capture } @{ $capture->history }), 'a mill was closed and a man taken';
round_trip($capture, 'after a capture');

my $full = play(Game::Merrills->new, 1000);
is $full->status, 'finished', 'the bot plays a game to its end';
round_trip(play(Game::Merrills->new, $full->ply - 4), 'late in the game, four plies before its end');
round_trip($full, 'at the end, by ' . $full->result->reason);

my $fixed = play(Game::Merrills->new(flying => 0), 30);
like save($fixed), qr/^flying no$/m, 'a game without flying says so';
round_trip($fixed, 'a game without flying');

my $resigned = play(Game::Merrills->new, 7);
$resigned->resign('white');
round_trip($resigned, 'after a resignation');
is load(save($resigned))->result->winner, 'black', 'the resignation comes back as one';

my $timed = play(Game::Merrills->new, 6);
$timed->timeout('black');
round_trip($timed, 'after a timeout');

my $offered = play(Game::Merrills->new, 5);
$offered->offer_draw('black');
round_trip($offered, 'with a draw offer standing');
is load(save($offered))->draw_offered_by, 'black', 'the offer comes back';

my $agreed = play(Game::Merrills->new, 5);
$agreed->offer_draw('black');
$agreed->accept_draw('white');
round_trip($agreed, 'after an agreed draw');
is load(save($agreed))->result->reason, 'agreement', 'the agreement comes back as one';

subtest 'malformed text is refused with a message' => sub {
	plan tests => 5;
	like eval { load('1. d2 zz'); 1 } ? '' : $@, qr/^record: move 2, 'zz' is not a move/,
		'a move that is not one';
	like eval { load("1. d2 f4\nresult white boredom\n"); 1 } ? '' : $@,
		qr/^record: the result must be a winner or draw and a reason/, 'a result that is not one';
	like eval { load("1. d2 f4\nresult draw resign\n"); 1 } ? '' : $@,
		qr/^record: the result must be/, 'a resignation with no winner';
	like eval { load("flying maybe\n1. d2 f4\n"); 1 } ? '' : $@,
		qr/^record: flying must be yes or no/, 'a flying line that is neither';
	my $over = save($full) . "result white resign\n";
	like eval { load($over); 1 } ? '' : $@,
		qr/^illegal record: it ends by resign, but the moves already end the game/,
		'an ending after the moves have ended it';
};

done_testing;
