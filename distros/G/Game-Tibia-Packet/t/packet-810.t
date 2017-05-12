use Test::More;
use Test::HexString;
use Data::HexDump;

BEGIN {
    use_ok 'Game::Tibia::Packet';
}

my $packet = pack 'H*', '28007d12e0a3d2fd80c005da2854d3a11716f2a2dbb9890cb55b28251b8676ad853aa9e641a91cbe6bf3';
my $xtea = pack 'H*', 'da1148fff2457e2c46fc7dfab0781358';

my $p = Game::Tibia::Packet->new(packet => $packet, xtea => $xtea, version => 810);

is_hexstr $p->finalize($xtea), $packet;

done_testing;
