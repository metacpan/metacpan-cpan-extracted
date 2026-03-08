use strict;
use warnings;
use Test::More;

eval { require Net::EmptyPort; 1 }
  or plan skip_all => 'Net::EmptyPort required';

use IO::Socket::INET;
use IO::Socket::HappyEyeballs;

my $port = Net::EmptyPort::empty_port();

my $server_pid = fork();
if ($server_pid == 0) {
  my $server = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => $port,
    Listen    => 5,
    ReuseAddr => 1,
    Proto     => 'tcp',
  ) or die "Cannot create server: $!";

  while (my $client = $server->accept) {
    $client->close;
  }
  exit 0;
}

sleep 1;

# Default: blocking
my $sock = IO::Socket::HappyEyeballs->new(
  PeerHost => '127.0.0.1',
  PeerPort => $port,
  Timeout  => 5,
);

SKIP: {
  skip 'no connection', 1 unless $sock;
  is($sock->blocking, 1, 'default is blocking mode');
  $sock->close;
}

# Explicit non-blocking
$sock = IO::Socket::HappyEyeballs->new(
  PeerHost => '127.0.0.1',
  PeerPort => $port,
  Timeout  => 5,
  Blocking => 0,
);

SKIP: {
  skip 'no connection', 1 unless $sock;
  is($sock->blocking, 0, 'Blocking => 0 gives non-blocking socket');
  $sock->close;
}

kill 'TERM', $server_pid;
waitpid($server_pid, 0);

done_testing;
