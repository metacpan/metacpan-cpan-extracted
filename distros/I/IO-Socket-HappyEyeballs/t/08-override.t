use strict;
use warnings;
use Test::More;

eval { require Net::EmptyPort; 1 }
  or plan skip_all => 'Net::EmptyPort required';

use IO::Socket::INET;
use IO::Socket::IP;

# Start a simple TCP server
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
    my $line = <$client>;
    print $client "OK:$line" if defined $line;
    $client->close;
  }
  exit 0;
}

sleep 1;

# Before override: IO::Socket::IP->new works normally
my $sock1 = IO::Socket::IP->new(
  PeerHost => '127.0.0.1',
  PeerPort => $port,
  Timeout  => 5,
);
ok($sock1, 'IO::Socket::IP works before override');
$sock1->close if $sock1;

# Activate override
use IO::Socket::HappyEyeballs -override;

# After override: IO::Socket::IP->new now uses Happy Eyeballs
my $sock2 = IO::Socket::IP->new(
  PeerHost => '127.0.0.1',
  PeerPort => $port,
  Timeout  => 5,
);
ok($sock2, 'IO::Socket::IP works after override');

SKIP: {
  skip 'no connection after override', 2 unless $sock2;

  ok($sock2->connected, 'socket is connected via override');

  print $sock2 "test\n";
  my $resp = <$sock2>;
  is($resp, "OK:test\n", 'data exchange works through override');

  $sock2->close;
}

# Also test that direct HappyEyeballs->new still works
my $sock3 = IO::Socket::HappyEyeballs->new(
  PeerHost => '127.0.0.1',
  PeerPort => $port,
  Timeout  => 5,
);
ok($sock3, 'direct HappyEyeballs->new still works with override active');
$sock3->close if $sock3;

# Test that subclasses of IO::Socket::IP work (e.g. Net::HTTP)
SKIP: {
  eval { require Net::HTTP; 1 }
    or skip 'Net::HTTP not installed', 2;

  my $http_sock = Net::HTTP->new(
    PeerHost => '127.0.0.1',
    PeerPort => $port,
    Timeout  => 5,
  );
  ok($http_sock, 'Net::HTTP works through override');
  isa_ok($http_sock, 'Net::HTTP', 'socket is a Net::HTTP object');
  $http_sock->close if $http_sock;
}

# Test that non-TCP (e.g. UDP) is NOT intercepted
my $udp = IO::Socket::IP->new(
  LocalAddr => '127.0.0.1',
  Proto     => 'udp',
  Type      => IO::Socket::IP::SOCK_DGRAM(),
);
ok($udp, 'UDP socket still works normally (not intercepted)');
$udp->close if $udp;

kill 'TERM', $server_pid;
waitpid($server_pid, 0);

done_testing;
