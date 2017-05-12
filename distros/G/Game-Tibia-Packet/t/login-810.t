use Test::More;
use Test::HexString;
use Data::HexDump;

BEGIN {
    use_ok 'Game::Tibia::Packet::Login';
}

my $packet = pack 'H*', '91000102002a0347375d47010b5d47d7fc42474fafb9d56b8d16395b14901c0c239faa7bfb128ed693b9e9563f1f229f74e04fc4e93293d9508b5ce611204dc02745b94c36fc3375dc831f17651a76933c92c49e50e58ab452636bc3bdeb4df2585f05bd8dcac9ed5836afdacc5582243f04fc03a5ced2ed9448b1027a299f768e11e99b423995c01bb12e5a5c26339e7b56c5';
my $xtea = pack 'H*', 'da1148fff2457e2c46fc7dfab0781358';

my $p = Game::Tibia::Packet::Login->new(packet => $packet);

is_hexstr $p->finalize, $packet;

done_testing;
