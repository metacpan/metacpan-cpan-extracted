use Test::More;

use Game::Cribbage::Deck;


my $deck = Game::Cribbage::Deck->new();

my $cards = $deck->cards();

is(scalar @{$cards}, 52);

$deck->shuffle();

is(scalar @{$deck->deck}, 52);
$deck->draw();
is(scalar @{$deck->deck}, 51);
$deck->draw();
is(scalar @{$deck->deck}, 50);

$deck->reset();

is(scalar @{$deck->deck}, 52);
$deck->draw();
is(scalar @{$deck->deck}, 51);

done_testing();
