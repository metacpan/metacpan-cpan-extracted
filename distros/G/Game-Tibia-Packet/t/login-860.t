use Test::More;
use Test::HexString;

BEGIN {
    use_ok 'Game::Tibia::Packet::Login';
}

my $instance = Game::Tibia::Packet::Login->new();

done_testing;



