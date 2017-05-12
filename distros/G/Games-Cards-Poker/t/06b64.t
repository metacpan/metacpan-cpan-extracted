use Test;
BEGIN { plan tests => 15 }

use Games::Cards::Poker qw(:all);

ok(1);
my $b64c = CardB64('As');
ok($b64c, 'A');

$card = B64Card($b64c);
ok($card, 'As');

$b64c = CardB64('Kh');
ok($b64c, 'F');

$card = B64Card($b64c);
ok($card, 'Kh');

$b64c = CardB64('2c');
ok($b64c, 'z');

$card = B64Card($b64c);
ok($card, '2c');

$card = B64Card('N');
ok($card, 'Jh');

$card = B64Card('T');
ok($card, 'Tc');

$card = join('', B64Hand('N'));
ok($card, 'Jh');

my $b64h = HandB64(['Tc']);
ok($b64h, 'T');

my $hand = join(' ', B64Hand('BADC'));
ok($hand, 'Ah As Ac Ad');

$b64h = HandB64(qw(Ah As Ac Ad));
ok($b64h, 'BADC');

$hand = join(' ', B64Hand('ACme'));
ok($hand, 'As Ad 5d 7d');

$b64h = HandB64(qw(As Ad 5d 7d));
ok($b64h, 'ACme');
