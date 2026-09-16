#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;

sub notations { [map { $_->notation } @{$_[0]->legal_moves}] }

subtest 'a capture crowds out every other move' => sub {
	plan tests => 5;
	# black has a man on 9 that could step, and a man on 15 that must jump
	my $game = Game::Checkers->new(fen => 'B:W18:B9,15');
	ok $game->must_capture, 'a jump is available';
	is_deeply notations($game), ['15x22'], 'so it is the only legal move';

	my $refused = $game->move('9-13');
	ok $refused->must_capture, 'the quiet move is refused';
	is $refused->code, 'must_capture', 'with the flag that says why';
	is_deeply [map { $_->notation } @{$refused->legal}], ['15x22'],
		'and the error carries what could be played instead';
};

subtest 'which capture is the player choice' => sub {
	plan tests => 4;
	# English draughts has no maximum capture rule: either jump will do
	my $game = Game::Checkers->new(fen => 'B:W18,19:B15');
	is_deeply notations($game), [qw/15x22 15x24/], 'two jumps, both legal';

	my $left = $game->clone;
	is $left->move('15x22')->notation, '15x22', 'the first is accepted';

	my $right = $game->clone;
	is $right->move('15x24')->notation, '15x24', 'and so is the second';

	is $right->board->at(19), 0, 'the piece it jumped is gone';
};

subtest 'the compulsion is per side, not per piece' => sub {
	plan tests => 2;
	my $game = Game::Checkers->new;
	$game->move('11-15');
	$game->move('22-18');
	ok $game->must_capture, 'black must now take';
	is_deeply notations($game), ['15x22'], 'and there is one way to do it';
};

done_testing;
