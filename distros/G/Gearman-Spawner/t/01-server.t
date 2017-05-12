use strict;
use warnings;

use Test::More tests => 2;

use FindBin '$Bin';
use lib "$Bin/lib";

use Gearman::Spawner::Server;
use IO::Socket::INET;

my $server = Gearman::Spawner::Server->create;
my $address = $server->address;
ok($server, "server created: $address");

my $mgmt = IO::Socket::INET->new($address);
ok($mgmt, 'can connect to server');
