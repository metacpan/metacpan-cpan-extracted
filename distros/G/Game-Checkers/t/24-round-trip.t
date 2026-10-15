#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;
use Game::Checkers::Bot;

sub save { return $_[0]->to_pdn }

sub load { return Game::Checkers->from_pdn($_[0]) }

sub bot { return Game::Checkers::Bot->new(level => 2, seed => 42) }

sub legal { return join ' ', sort map { $_->notation } @{$_[0]->legal_moves} }

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
		plan tests => 6;
		my $text = save($game);
		my $loaded = load($text);
		isnt $loaded, $game, 'the load is a new game';
		is save($loaded), $text, 'save(load(save)) is save';
		is legal($loaded), legal($game), 'the same legal moves';
		is $loaded->status, $game->status, 'the same status';
		is next_three(load($text)), next_three($game->clone),
			'the bot plays the same next three moves';
		my $bot = bot();
		if (my $move = $bot->choose($loaded)) {
			$loaded->move($move);
		} else {
			$loaded->offer_draw('black') if $loaded->status eq 'active';
		}
		is save($game), $text, 'playing on the load leaves the original alone';
	};
}

my $start = Game::Checkers->new;
round_trip($start, 'at the start');

my $three = play(Game::Checkers->new, 3);
round_trip($three, 'after three moves');

my $capture = Game::Checkers->new;
my $bot = bot();
while ($capture->status eq 'active' && !grep { $_->is_jump } @{$capture->history}) {
	$capture->move($bot->choose($capture));
}
ok scalar(grep { $_->is_jump } @{$capture->history}), 'a capture was played';
round_trip($capture, 'after a capture');

my $full = play(Game::Checkers->new, 1000);
is $full->status, 'finished', 'the bot plays a game to its end';
my $late = Game::Checkers->new;
play($late, $full->ply - 4);
round_trip($late, 'late in the game, four plies before its end');
round_trip($full, 'at the end, ' . $full->result->stringify);

my $resigned = play(Game::Checkers->new, 7);
$resigned->resign('black');
round_trip($resigned, 'after a resignation');
is load(save($resigned))->result->stringify, 'White wins: Black resigned',
	'the resignation comes back as one';

my $offered = play(Game::Checkers->new, 5);
$offered->offer_draw('white');
round_trip($offered, 'with a draw offer standing');
is load(save($offered))->draw_offered_by, 'white', 'the offer comes back';

my $agreed = play(Game::Checkers->new, 5);
$agreed->offer_draw('white');
$agreed->accept_draw('black');
round_trip($agreed, 'after an agreed draw');
is load(save($agreed))->result->stringify, 'Draw: agreed', 'the agreement comes back as one';

my $fen = Game::Checkers->new(fen => 'W:WK10,K14:BK1,K3');
my $ply = 0;
while ($fen->status eq 'active' && $ply++ < 20) {
	$fen->move($fen->legal_moves->[0]);
}
round_trip($fen, 'from a set-up position, kings shuffling');
is load(save($fen))->no_progress, $fen->no_progress, 'the no-progress count comes back';
is_deeply load(save($fen))->repetition, $fen->repetition, 'and so does the repetition table';

subtest 'malformed text is refused with a message' => sub {
	plan tests => 5;
	ok !eval { load("1. 11-15 wibble\n"); 1 }, 'a move that is not one';
	like $@, qr/malformed PDN/, 'says so';
	my $text = save($resigned);
	$text =~ s/\[Ending "resign"\]/[Ending "boredom"]/;
	ok !eval { load($text); 1 }, 'an Ending that is not a reason';
	like $@, qr/the Ending tag must be one of/, 'says so';
	my $offer = save($offered);
	$offer =~ s/\[DrawOffer "white"\]/[DrawOffer "red"]/;
	like eval { load($offer); 1 } ? '' : $@, qr/DrawOffer tag must be black or white/,
		'a DrawOffer naming no side';
};

done_testing;
