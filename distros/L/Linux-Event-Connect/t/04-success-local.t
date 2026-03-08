use v5.36;
use Test::More;

use Linux::Event;
use Linux::Event::Connect;

use Socket qw(SOCK_STREAM SOL_SOCKET SO_REUSEADDR inet_pton AF_INET pack_sockaddr_in);

my $loop = Linux::Event->new;

# Create a simple local listener (server side)
my $ls;
socket($ls, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
setsockopt($ls, SOL_SOCKET, SO_REUSEADDR, pack("i", 1));
bind($ls, pack_sockaddr_in(0, inet_pton(AF_INET, "127.0.0.1"))) or die "bind: $!";
listen($ls, 10) or die "listen: $!";
my ($port) = unpack("x2n", getsockname($ls));

my $accepted = 0;
my $connected = 0;

# Watch listener for readability and accept one connection.
my $w = $loop->watch($ls,
  read => sub ($loop2, $fh, $watcher) {
    my $client;
    my $peer = accept($client, $fh);
    ok($peer, "accept returned a peer");
    if ($peer) {
      $accepted = 1;
      close $client;
      $loop2->unwatch($fh);
      close $fh;
      $loop2->stop if $connected;
    }
  },
);

my $req = Linux::Event::Connect->new(
  loop => $loop,
  host => '127.0.0.1',
  port => $port,
  timeout_s => 1,

  on_connect => sub ($r, $fh, $data) {
    $connected = 1;
    ok(defined fileno($fh), "connected fh has fileno");
    close $fh;
    $loop->stop if $accepted;
  },

  on_error => sub ($r, $errno, $data) {
    fail("connect failed unexpectedly: $errno");
    $loop->stop;
  },
);

$loop->run;

ok($connected, "on_connect fired");
ok($accepted, "server accepted connection");

done_testing;
