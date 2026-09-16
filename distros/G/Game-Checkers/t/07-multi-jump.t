#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;

sub notations { [map { $_->notation } @{$_[0]->legal_moves}] }

subtest 'a sequence is one move' => sub {
	plan tests => 6;
	# 9 takes 14 landing on 18, then takes 23 landing on 27
	my $game = Game::Checkers->new(fen => 'B:W14,23:B9');
	is_deeply notations($game), ['9x18x27'], 'a double jump, written as its path';

	my $move = $game->move('9x18x27');
	is_deeply $move->path, [9, 18, 27], 'the path is the squares landed on';
	is_deeply $move->captures, [14, 23], 'both captures belong to the one move';
	is $game->board->at(27), Game::Checkers::Board::BLACK_MAN, 'the man ended on 27';
	is $game->board->at(14), 0, 'and took 14';
	is $game->board->at(23), 0, 'and 23';
};

subtest 'a triple' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new(fen => 'B:W6,15,24:B1');
	is_deeply notations($game), ['1x10x19x28'], 'three in one move';

	my $move = $game->move('1x10x19x28');
	is scalar @{$move->captures}, 3, 'three pieces taken';
	is $game->board->count('white')->{total}, 0, 'and White has nothing left';
};

subtest 'a piece is not jumped twice' => sub {
	plan tests => 2;
	# the king takes the man on 11 and lands on 8, from where the only jump
	# available would be back over the same man
	my $game = Game::Checkers->new(fen => 'B:W11:BK15');
	is_deeply notations($game), ['15x8'],
		'the sequence stops rather than taking the same piece again';

	# and the reason it stops is the ban, not an empty square: the captured man
	# stays on the board until the move ends
	my $move = $game->move('15x8');
	is_deeply $move->captures, [11], 'one capture';
};

subtest 'the same start and finish by two paths is ambiguous' => sub {
	plan tests => 6;
	# a king ringed by four men takes all four and comes home, clockwise or
	# anticlockwise
	my $game = Game::Checkers->new(fen => 'B:W18,19,26,27:BK15');
	is_deeply notations($game), ['15x22x31x24x15', '15x24x31x22x15'],
		'two sequences, both from 15 to 15';

	my $short = $game->clone->move('15x15');
	ok $short->ambiguous, 'the short form cannot choose between them';
	is scalar @{$short->legal}, 2, 'and says which two it matched';

	my $clockwise = $game->clone;
	my $move = $clockwise->move('15x24x31x22x15');
	is $move->notation, '15x24x31x22x15', 'the whole path picks one';
	is_deeply $move->captures, [19, 27, 26, 18], 'in the order they were taken';
	is $clockwise->board->count('white')->{total}, 0, 'all four gone';
};

subtest 'a sequence stopped part way is not a move' => sub {
	plan tests => 4;
	# 23 takes 18 landing on 14, and from there may take 10 or 9
	my $game = Game::Checkers->new(fen => 'W:W23:B9,10,18');
	is_deeply notations($game), ['23x14x5', '23x14x7'],
		'two continuations from the same first jump';

	ok $game->clone->move('23x14')->not_legal,
		'stopping on 14 is refused rather than completed for the player';

	is $game->clone->move('23x7')->notation, '23x14x7',
		'the short form is not ambiguous here, because the finishes differ';
	is $game->clone->move('23x5')->notation, '23x14x5', 'either one';
};

done_testing;
