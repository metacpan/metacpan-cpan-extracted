use strict; use warnings;
use Games::Cards::Pair;
use Games::Cards::Pair::Card;
use Test::More tests => 12;

eval { Games::Cards::Pair::Card->new(); };
like($@, qr/Attribute \(suit\) is required/);

eval { Games::Cards::Pair::Card->new({ suit => 'clubs' }); };
like($@, qr/Missing required arguments: value/);

eval { Games::Cards::Pair::Card->new({ value => 'queen' }); };
like($@, qr/Attribute \(suit\) is required/);

eval { Games::Cards::Pair::Card->new({ suit => 'CC', value => 1 }); };
like($@, qr/isa check for 'suit' failed/);

eval { Games::Cards::Pair::Card->new({ suit => 'C', value => 'queens' }); };
like($@, qr/isa check for 'value' failed/);

eval { Games::Cards::Pair::Card->new({ suit => 'C', value => 'joker' }); };
like($@, qr/Attribute \(suit\) is NOT required for Joker/);

my ($card1, $card2);
$card1 = Games::Cards::Pair::Card->new({ suit => 'C', value => 3});
$card2 = Games::Cards::Pair::Card->new({ suit => 'C', value => 2 });
is($card1->equal($card2), 0);

$card1 = Games::Cards::Pair::Card->new({ suit => 'C', value => 5 });
$card2 = Games::Cards::Pair::Card->new({ suit => 'C', value => 5 });
is($card1->equal($card2), 1);

$card1 = Games::Cards::Pair::Card->new({ value => 'Joker' });
$card2 = Games::Cards::Pair::Card->new({ suit  => 'C', value => 2 });
is($card1->equal($card2), 1);

$card1 = Games::Cards::Pair::Card->new({ suit  => 'C', value => 2 });
$card2 = Games::Cards::Pair::Card->new({ value => 'Joker' });
is($card1->equal($card2), 1);

is($card1->equal(Games::Cards::Pair->new()), 0);
is($card1->equal(), 0);