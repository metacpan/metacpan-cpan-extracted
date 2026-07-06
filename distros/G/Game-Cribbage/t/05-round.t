use Test::More;

use Game::Cribbage::Round;
use Game::Cribbage::Board;

my $board = Game::Cribbage::Board->new();

$board->build_deck();

$board->add_player(name => 'Robert');
$board->add_player(name => 'Luck');

my $round = Game::Cribbage::Round->new(
	number => 1,
)->init($board);

is($round->number(), 1);

done_testing();
