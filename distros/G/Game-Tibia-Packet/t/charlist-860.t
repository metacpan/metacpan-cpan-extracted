use Test::More;
use Test::HexString;

BEGIN {
    use_ok 'Game::Tibia::Packet::Charlist';
}

my $instance = Game::Tibia::Packet::Charlist->new(version => 860);

done_testing;



