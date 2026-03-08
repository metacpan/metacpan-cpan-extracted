use strict;
use warnings;
use Test::More;

eval { require Net::EmptyPort; 1 }
  or plan skip_all => 'Net::EmptyPort required';

use IO::Socket::HappyEyeballs;

# Find a port that nothing is listening on
my $port = Net::EmptyPort::empty_port();

my $sock = IO::Socket::HappyEyeballs->new(
  PeerHost => '127.0.0.1',
  PeerPort => $port,
  Timeout  => 2,
);

ok(!$sock, 'connection to closed port fails');
like($@, qr/(?:all attempts failed|Cannot connect)/, 'error message set');

done_testing;
