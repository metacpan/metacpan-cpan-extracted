use strict; use warnings;
use Games::Cards::Pair;
use Test::More tests => 5;

my ($game, $card);
$game = Games::Cards::Pair->new;
$game->init;
ok(!$game->is_over);

$game = Games::Cards::Pair->new;
$game->init;
$card = $game->play("1,2");
ok($card);

eval { Games::Cards::Pair->new({ debug => 'a' }) };
like($@, qr/ERROR: Only 0 or 1 allowed./);

eval { Games::Cards::Pair->new({ debug => 2 }) };
like($@, qr/ERROR: Only 0 or 1 allowed./);

eval { $game->play($game) };
like($@, qr/ERROR: Invalid card received/);