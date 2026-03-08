use v5.36;
use Test::More;

use Linux::Event;
use Linux::Event::Connect;

use Socket qw(AF_UNIX SOCK_STREAM pack_sockaddr_un);
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/sock";

my $loop = Linux::Event->new;

my $ls;
socket($ls, AF_UNIX, SOCK_STREAM, 0) or die "socket: $!";
bind($ls, pack_sockaddr_un($path)) or die "bind: $!";
listen($ls, 10) or die "listen: $!";

my $accepted = 0;
my $connected = 0;

$loop->watch($ls,
  read => sub ($loop2, $fh, $watcher) {
    my $client;
    accept($client, $fh) or die "accept: $!";
    $accepted = 1;
    close $client;
    $loop2->unwatch($fh);
    close $fh;
    $loop2->stop if $connected;
  },
);

my $req = Linux::Event::Connect->new(
  loop => $loop,
  unix => $path,
  timeout_s => 1,
  on_connect => sub ($r, $fh, $data) {
    $connected = 1;
    close $fh;
    $loop->stop if $accepted;
  },
  on_error => sub ($r, $errno, $data) {
    fail("unix connect failed: $errno");
    $loop->stop;
  },
);

$loop->run;

ok($connected, "unix on_connect fired");
ok($accepted, "unix server accepted");

done_testing;
