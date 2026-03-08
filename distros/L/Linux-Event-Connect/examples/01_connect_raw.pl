use v5.36;
use strict;
use warnings;

use Socket qw(
  AF_INET SOCK_STREAM SOL_SOCKET SO_REUSEADDR
  inet_pton pack_sockaddr_in
);

use Linux::Event;
use Linux::Event::Connect;

my $loop = Linux::Event->new;

# Create a tiny local TCP server on an ephemeral port.
my $ls;
socket($ls, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
setsockopt($ls, SOL_SOCKET, SO_REUSEADDR, pack("i", 1)) or die "setsockopt: $!";
bind($ls, pack_sockaddr_in(0, inet_pton(AF_INET, "127.0.0.1"))) or die "bind: $!";
listen($ls, 10) or die "listen: $!";
my ($port) = unpack("x2n", getsockname($ls));

my $accepted = 0;

$loop->watch($ls,
  read => sub ($loop2, $fh, $watcher) {
    my $client;
    accept($client, $fh) or die "accept: $!";
    $accepted = 1;
    syswrite($client, "hello from server\n");
    close $client;
    $loop2->unwatch($fh);
    close $fh;
  },
);

my $req = Linux::Event::Connect->new(
  loop => $loop,
  host => '127.0.0.1',
  port => $port,
  timeout_s => 2,

  on_connect => sub ($req, $fh, $data) {
    my $buf = '';
    sysread($fh, $buf, 4096);
    print "Client read: $buf";
    close $fh;
    $loop->stop;
  },

  on_error => sub ($req, $errno, $data) {
    $! = $errno;
    die "Connect failed: $errno ($!)\n";
  },
);

$loop->run;

die "server did not accept\n" if !$accepted;
