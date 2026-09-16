#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;

sub notations { [map { $_->notation } @{$_[0]->legal_moves}] }

subtest 'a king moves one square in any direction' => sub {
	plan tests => 2;
	my $centre = Game::Checkers->new(fen => 'B:W29:BK15');
	is_deeply notations($centre), [qw/15-10 15-11 15-18 15-19/],
		'a king in the middle has four moves, two of them backwards';

	my $edge = Game::Checkers->new(fen => 'B:W29:BK13');
	is_deeply notations($edge), [qw/13-9 13-17/],
		'and a king on the edge has two';
};

subtest 'a king jumps backwards' => sub {
	plan tests => 3;
	# the white man on 15 is north of the black king on 19, which a man could
	# not touch and a king must
	my $game = Game::Checkers->new(fen => 'B:W15:BK19');
	ok $game->must_capture, 'the jump is compulsory';
	is_deeply notations($game), ['19x10'], 'backwards over 15, landing on 10';

	my $move = $game->move('19x10');
	is_deeply $move->captures, [15], 'and it takes the man';
};

subtest 'a king is still a king' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new(fen => 'B:W29:BK15');
	ok $game->move('15-24')->not_legal, 'a king does not slide two squares';

	my $move = $game->move('15-10');
	ok $move->king, 'the move knows the piece was crowned already';
	ok !$move->promoted, 'and it did not crown again';
};

done_testing;
