use strict;
use warnings;
use Test::More;

eval { require Test::TCP; 1 }
  or plan skip_all => 'Test::TCP required for connection tests';
eval { require Net::EmptyPort; 1 }
  or plan skip_all => 'Net::EmptyPort required for connection tests';

use IO::Socket::INET;
use IO::Socket::HappyEyeballs;

# Start a simple TCP server on localhost
my $port = Net::EmptyPort::empty_port();

my $server_pid = fork();
if ($server_pid == 0) {
  # Child: simple echo server
  my $server = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => $port,
    Listen    => 5,
    ReuseAddr => 1,
    Proto     => 'tcp',
  ) or die "Cannot create server: $!";

  while (my $client = $server->accept) {
    my $line = <$client>;
    print $client "ECHO:$line" if defined $line;
    $client->close;
  }
  exit 0;
}

# Give server time to start
sleep 1;

# Connect using HappyEyeballs
my $sock = IO::Socket::HappyEyeballs->new(
  PeerHost => '127.0.0.1',
  PeerPort => $port,
  Timeout  => 5,
);

ok($sock, 'connected to local server') or diag("Connect failed: $@");

SKIP: {
  skip 'no connection', 3 unless $sock;

  ok($sock->connected, 'socket reports connected');

  print $sock "hello\n";
  my $response = <$sock>;
  is($response, "ECHO:hello\n", 'received echo response');

  $sock->close;
  ok(!$sock->connected, 'socket closed');
}

# Cleanup
kill 'TERM', $server_pid;
waitpid($server_pid, 0);

done_testing;
