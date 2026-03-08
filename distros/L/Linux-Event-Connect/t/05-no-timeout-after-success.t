use v5.36;
use Test::More;

use Linux::Event;
use Linux::Event::Connect;

use Socket qw(SOCK_STREAM SOL_SOCKET SO_REUSEADDR inet_pton AF_INET pack_sockaddr_in);

my $loop = Linux::Event->new;

# Listener
my $ls;
socket($ls, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
setsockopt($ls, SOL_SOCKET, SO_REUSEADDR, pack("i", 1));
bind($ls, pack_sockaddr_in(0, inet_pton(AF_INET, "127.0.0.1"))) or die "bind: $!";
listen($ls, 10) or die "listen: $!";
my ($port) = unpack("x2n", getsockname($ls));

my $accepted = 0;
my $connected = 0;
my $extra_error = 0;

$loop->watch($ls,
  read => sub ($loop2, $fh, $watcher) {
    my $client;
    accept($client, $fh);
    $accepted = 1 if $client;
    close $client if $client;
    $loop2->unwatch($fh);
    close $fh;
    $loop2->stop if $connected;
  },
);

my $req = Linux::Event::Connect->new(
  loop => $loop,
  host => '127.0.0.1',
  port => $port,
  timeout_s => 0.1,

  on_connect => sub ($r, $fh, $data) {
    $connected = 1;
    close $fh;
    $loop->stop if $accepted;
  },

  on_error => sub ($r, $errno, $data) {
    $extra_error++;
    $loop->stop;
  },
);

$loop->run;

# Pump more; timeout should have been cancelled on success.
for (1..10) {
  $loop->run_once(0);
}

ok($connected, "connected");
ok($accepted, "accepted");
is($extra_error, 0, "no late timeout error after success");

done_testing;
