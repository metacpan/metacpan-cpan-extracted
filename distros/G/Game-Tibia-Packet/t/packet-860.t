use Test::More;
use Test::HexString;

BEGIN {
    use_ok 'Game::Tibia::Packet';
}

my $instance = Game::Tibia::Packet->new();

done_testing;
