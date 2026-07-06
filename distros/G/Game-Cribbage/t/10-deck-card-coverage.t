use strict;
use warnings;
use Test::More;

use Game::Cribbage::Deck;
use Game::Cribbage::Deck::Card;

# --- Deck::Card ---

my $ace_h = Game::Cribbage::Deck::Card->new(suit => 'H', symbol => 'A');
my $jack_s = Game::Cribbage::Deck::Card->new(suit => 'S', symbol => 'J');
my $queen_d = Game::Cribbage::Deck::Card->new(suit => 'D', symbol => 'Q');
my $king_c = Game::Cribbage::Deck::Card->new(suit => 'C', symbol => 'K');
my $seven_h = Game::Cribbage::Deck::Card->new(suit => 'H', symbol => 7);

is($ace_h->value,   1,  'A value is 1');
is($jack_s->value,  10, 'J value is 10');
is($queen_d->value, 10, 'Q value is 10');
is($king_c->value,  10, 'K value is 10');
is($seven_h->value, 7,  'numeric value is itself');

is($ace_h->run_value,   1,  'A run_value is 1');
is($jack_s->run_value,  11, 'J run_value is 11');
is($queen_d->run_value, 12, 'Q run_value is 12');
is($king_c->run_value,  13, 'K run_value is 13');
is($seven_h->run_value, 7,  'numeric run_value is itself');

ok($ace_h->suit_symbol,   'H suit_symbol returns something');
ok($jack_s->suit_symbol,  'S suit_symbol returns something');
ok($queen_d->suit_symbol, 'D suit_symbol returns something');
ok($king_c->suit_symbol,  'C suit_symbol returns something');

like($ace_h->ui_stringify,  qr/A/, 'ui_stringify contains symbol');
like($jack_s->ui_stringify, qr/J/, 'ui_stringify contains symbol for J');

like($ace_h->stringify,   qr/A/, 'stringify contains A');
like($seven_h->stringify, qr/7/, 'stringify contains 7');

my $ace_h2 = Game::Cribbage::Deck::Card->new(suit => 'H', symbol => 'A');
ok($ace_h->match($ace_h2), 'match returns 1 for same card');
ok(!$ace_h->match(Game::Cribbage::Deck::Card->new(suit => 'S', symbol => 'A')), 'match returns 0 for different suit');
ok(!$ace_h->match(Game::Cribbage::Deck::Card->new(suit => 'H', symbol => 'K')), 'match returns 0 for different symbol');

# --- Deck ---

my $deck = Game::Cribbage::Deck->new();
is(scalar @{$deck->deck}, 52, 'fresh deck has 52 cards');

# force_draw - pull a specific card
my $target = { suit => 'H', symbol => 'A' };
my $drawn = $deck->force_draw($target);
is($drawn->suit,   'H', 'force_draw returns correct suit');
is($drawn->symbol, 'A', 'force_draw returns correct symbol');
is(scalar @{$deck->deck}, 51, 'deck has 51 after force_draw');

# card_exists - not there after force_draw
ok(!$deck->card_exists($drawn), 'card_exists false for drawn card');

# card_exists - still there for another card (uses method calls now that bug is fixed)
my $still_in = Game::Cribbage::Deck::Card->new(suit => 'S', symbol => 'K');
ok($deck->card_exists($still_in), 'card_exists finds a card still in the deck');

# generate_card
my $gen = $deck->generate_card({ suit => 'D', symbol => '5' });
isa_ok($gen, 'Game::Cribbage::Deck::Card', 'generate_card returns a Card');
is($gen->suit,   'D', 'generated card suit');
is($gen->symbol, '5', 'generated card symbol');

# get
my $got = $deck->get(0);
isa_ok($got, 'Game::Cribbage::Deck::Card', 'get returns a Card');

# reset rebuilds to 52
$deck->reset;
$deck->draw for 1 .. 10;
is(scalar @{$deck->deck}, 42, 'drew 10 cards from 52');
$deck->reset;
is(scalar @{$deck->deck}, 52, 'reset restores 52 cards');

done_testing;
