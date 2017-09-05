use Test::More;
use Test::HexString;

BEGIN {
    use_ok 'Game::Tibia::Packet::Login';
}

my $packet = pack 'H*', '2000010200e4029c61bf4186eab941a89c9c41c907cc00090077697265736861726b';

my $p = Game::Tibia::Packet::Login->new(packet => $packet, version => 740);

is_hexstr $p->finalize, $packet;

done_testing;
