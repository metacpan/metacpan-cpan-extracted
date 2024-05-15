use Test::More;

use Game::Cribbage::Deck::Card;


my $card = Game::Cribbage::Deck::Card->new(
	suit => 'H',
	symbol => 'K',
);


is($card->value(), 10);
is($card->stringify(), "K♥️");
done_testing();
