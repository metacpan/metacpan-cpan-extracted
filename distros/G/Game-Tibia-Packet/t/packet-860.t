use Test::More;
use Test::HexString;

use Game::Tibia::Packet tibia => 1000;
use Game::Tibia::Packet tibia => 860;

my $instance = Game::Tibia::Packet->new;
ok $instance;

done_testing;
