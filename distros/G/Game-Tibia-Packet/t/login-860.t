use Test::More;

use Game::Tibia::Packet::Login tibia => 860;

my $instance = Game::Tibia::Packet::Login->new(version => 860);
ok $instance;

done_testing;



