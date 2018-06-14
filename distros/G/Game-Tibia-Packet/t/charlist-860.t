use Test::More tests => 3;
use Data::HexDump;

use Game::Tibia::Packet::Charlist tibia => 860;
my $XTEA = pack('H*', '3A03C7AF55FE647D238770DE5EB9BE32');

my $decoded = Game::Tibia::Packet::Charlist->new(
    xtea   => $XTEA,
    packet => pack('H*', '3C00541BB245DAEDC8CE939F9F4F698AEC5D74BD3EE01476640274BCEF6D5DE0F655482FA00C8135D53A9829410CAD39592A492D7B395D8767BC88F0C07F')
);
$decoded->{packet} = undef;
my $encoded = Game::Tibia::Packet::Charlist->new(
    version      => 860,
    premium_days => 256,
    motd         => 'yes',
    characters   => [
        {
            name  => 'Foo',
            world => {
                ip   => '127.0.0.1',
                port => 7172,
                name => 'Local'
            }
        },
        {
            name  => 'Bar',
            world => {
                port => 7172,
                ip   => '127.0.0.1',
                name => 'Remote'
            },
        }
    ],
    xtea => $XTEA
);

is $decoded->{version}, 860;
is $encoded->{version}, 860;

is_deeply $decoded, $encoded;
