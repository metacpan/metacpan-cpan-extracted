use Test::More;

use Game::Cribbage::Player;

my $player = Game::Cribbage::Player->new(
	name => 'Robert',
);

is($player->name(), 'Robert');

done_testing();
