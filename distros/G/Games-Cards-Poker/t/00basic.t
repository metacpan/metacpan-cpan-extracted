use Test;
BEGIN { plan tests => 15 }

use Games::Cards::Poker qw(:all);

ok(1);
my @deck = Deck();
ok(@deck, 52);

my $card = $deck[0];
ok($card, 'As');

$card = $deck[3];
ok($card, 'Ac');

$card = $deck[4];
ok($card, 'Ks');

$card = $deck[51];
ok($card, '2c');

my @hand = qw( 4c 9d Td 4s Ah );
SortCards(\@hand);
$card = $hand[0];
ok($card, 'Ah');

$card = $hand[1];
ok($card, 'Td');

$card = $hand[2];
ok($card, '9d');

$card = $hand[3];
ok($card, '4s');

$card = $hand[4];
ok($card, '4c');

my $shrt = ShortHand(@hand);
ok($shrt, 'AT944');

my $scor = ScoreHand(@hand);
ok($scor, 5552);

   $scor = ScoreHand(ShortHand(@hand));
ok($scor, 5552);

   $shrt = HandScore(ScoreHand(ShortHand(@hand)));
ok($shrt, 'AT944');
