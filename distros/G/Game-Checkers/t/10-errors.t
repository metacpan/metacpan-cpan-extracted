#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;

# every flag Game::Checkers::Error carries, each from a position built by hand

subtest 'game_over' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new;
	$game->resign('black');
	my $error = $game->move('11-15');
	ok $error->game_over, 'the flag';
	is $error->message, 'the game is over', 'the sentence';
	is_deeply $error->legal, [],
		'and nothing to offer instead, which is the whole point of it';
};

subtest 'not_a_move' => sub {
	plan tests => 4;
	my $game = Game::Checkers->new;
	ok $game->move('resign')->not_a_move, 'a word';
	ok $game->move('11-33')->not_a_move, 'a square that is not on the board';
	ok $game->move({})->not_a_move, 'an empty hashref';
	ok $game->move(\'11-15')->not_a_move, 'a reference to something else';
};

subtest 'not_your_piece' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new;
	ok $game->move('21-17')->not_your_piece, q|the other side's man|;
	ok $game->move('13-17')->not_your_piece, 'an empty square';
	ok scalar @{$game->move('13-17')->legal}, 'and the error carries the legal moves';
};

subtest 'must_capture' => sub {
	plan tests => 2;
	my $game = Game::Checkers->new(fen => 'B:W18:B9,15');
	my $error = $game->move('9-13');
	ok $error->must_capture, 'the flag';
	is_deeply [map { $_->notation } @{$error->legal}], ['15x22'], 'the jump it wanted';
};

subtest 'wrong_direction' => sub {
	plan tests => 2;
	my $game = Game::Checkers->new(fen => 'B:W29:B15');
	ok $game->move('15-11')->wrong_direction, 'a man going backwards';

	my $white = Game::Checkers->new(fen => 'W:W15:BK29');
	ok $white->move('15-19')->wrong_direction, 'in either colour';
};

subtest 'occupied' => sub {
	plan tests => 2;
	my $game = Game::Checkers->new(fen => 'B:W29:B15,19');
	ok $game->move('15-19')->occupied, 'a piece of your own in the way';

	my $enemy = Game::Checkers->new(fen => 'B:W19,24:B15');
	ok $enemy->move('15-19')->occupied, 'and an enemy is no different';
};

subtest 'not_legal' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new(fen => 'B:W29:B15');
	ok $game->move('15-24')->not_legal, 'a jump over an empty square';
	ok $game->move('15-16')->not_legal, 'a sideways move';

	my $own = Game::Checkers->new(fen => 'B:W29:B15,19');
	ok $own->move('15-24')->not_legal, 'a jump over your own piece';
};

subtest 'ambiguous' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new(fen => 'B:W18,19,26,27:BK15');
	my $error = $game->move({ from => 15, to => 15 });
	ok $error->ambiguous, 'two sequences with the same ends';
	is scalar @{$error->legal}, 2, 'and the error lists both';
	is $error->code, 'ambiguous', 'code names the flag';
};

subtest 'no_offer and nothing_to_undo' => sub {
	plan tests => 4;
	my $game = Game::Checkers->new;
	ok $game->accept_draw('white')->no_offer, 'accepting nothing';
	ok $game->decline_draw('white')->no_offer, 'declining nothing';
	ok $game->undo->nothing_to_undo, 'undoing nothing';

	$game->move('11-15');
	is $game->undo->notation, '11-15', 'and undoing something works';
};

subtest 'an error is an error whatever it says' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new;
	my $error = $game->move('21-17');
	ok $error->error, 'the one flag a caller can always test';
	is $error->stringify, $error->message, 'stringify is the message';
	isa_ok $error, 'Game::Checkers::Error';
};

done_testing;
