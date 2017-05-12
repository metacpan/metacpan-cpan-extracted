use Test;
BEGIN { plan tests => 31 }

use Games::Cards::Poker qw(:all);

ok(1);
my $name = CardName('As');
ok($name, 'Ace of Spades');

my $card = NameCard($name);
ok($card, 'As');

$name = CardName('Kd');
ok($name, 'King of Diamonds');

$card = NameCard($name);
ok($card, 'Kd');

$name = CardName('Qh');
ok($name, 'Queen of Hearts');

$card = NameCard($name);
ok($card, 'Qh');

$name = CardName('7d');
ok($name, 'Seven of Diamonds');

$card = NameCard($name);
ok($card, '7d');

$name = CardName('3c');
ok($name, 'Three of Clubs');

$card = NameCard($name);
ok($card, '3c');

$name = CardName('2d');
ok($name, 'Two of Diamonds');

$card = NameCard($name);
ok($card, '2d');

$name = CardName('2c');
ok($name, 'Two of Clubs');

$card = NameCard($name);
ok($card, '2c');

$name = HandName(0);
ok($name, 'Royal Flush');

$name = HandName('AKQJTs');
ok($name, 'Royal Flush');

$name = HandName(qw( Jh Kh Th Ah Qh ));
ok($name, 'Royal Flush');

@hand = qw( Jh Kh Th Ah Qh );
$name = HandName(\@hand);
ok($name, 'Royal Flush');

$name = HandName(1);
ok($name, 'Straight Flush');

$name = HandName('KQJT9s');
ok($name, 'Straight Flush');

$name = HandName(qw( Jh Kh Th 9h Qh ));
ok($name, 'Straight Flush');

@hand = qw( Jh Kh Th 9h Qh );
$name = HandName(\@hand);
ok($name, 'Straight Flush');

$name = HandName(2000);
ok($name, 'Three-of-a-Kind');

$name = HandName(7000);
ok($name, 'High Card');

$name = HandName(HandScore(7000));
ok($name, 'High Card');

$name = CardName('A');
ok($name, 'Ace');

$card = NameCard($name);
ok($card, 'A');

$name = CardName('s');
ok($name, 'Spades');

$card = NameCard($name);
ok($card, 's');

$name = CardName('2');
ok($name, 'Two');
