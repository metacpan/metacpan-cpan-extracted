use Test::More;

use Game::Cribbage::Player::Hand;

my $hand = Game::Cribbage::Player::Hand->new(
	player => 'player1',
);

is($hand->player(), 'player1');

use Game::Cribbage::Deck;
my $deck = Game::Cribbage::Deck->new();
for (0 .. 5) {
	$hand->add($deck->draw());
}

is (scalar @{$hand->cards}, 6);

$hand->discard($hand->cards->[0], $hand);
$hand->discard($hand->cards->[-1], $hand);

is(scalar @{$hand->cards}, 4);
is(scalar @{$hand->crib}, 2);

done_testing();
