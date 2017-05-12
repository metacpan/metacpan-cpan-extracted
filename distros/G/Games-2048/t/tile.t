use 5.012;
use strictures;
use Test::More;
use Games::2048;

my $tile = Games::2048::Tile->new;
my $winning_tile = Games::2048::Tile->new(value => 2048);

isa_ok $tile, "Games::2048::Tile", "tile";
isa_ok $winning_tile, "Games::2048::Tile", "winning tile";

is $tile->value, 2, "default value";
is $winning_tile->value, 2048, "set value in constructor";

is $tile->merged, 0, "default merged";

done_testing;
