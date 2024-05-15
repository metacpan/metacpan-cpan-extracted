use Test::More;

use Game::Cribbage::Board;

my $board = Game::Cribbage::Board->new();

$board->add_player(name => 'Robert');
$board->add_player(name => 'Luck');

is(scalar @{$board->players}, 2);
is($board->players->[0]->name, 'Robert');
is($board->players->[1]->name, 'Luck');

$board->start_game();

is(scalar @{$board->deck->cards}, 52);
is($board->rounds->number, 1);
is($board->rounds->current_round->number, 1);

done_testing();
