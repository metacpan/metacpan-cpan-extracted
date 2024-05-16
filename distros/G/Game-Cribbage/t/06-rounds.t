use Test::More;

use Game::Cribbage::Board;
use Game::Cribbage::Rounds;

my $board = Game::Cribbage::Board->new();

$board->build_deck();

$board->add_player(name => 'Robert');
$board->add_player(name => 'Luck');

my $rounds = Game::Cribbage::Rounds->new(
	number => 3,
);

is($rounds->number(), 3);

$rounds->next_round($board);

is($rounds->current_round->number, 1);
is($rounds->history->[0]->number, 1);

done_testing();
