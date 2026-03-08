use v5.36;
use Test::More;

use Linux::Event;
use Linux::Event::Connect;

use Socket qw(SOCK_STREAM SOL_SOCKET SO_REUSEADDR inet_pton AF_INET pack_sockaddr_in);
use Errno ();

my $loop = Linux::Event->new;

# Obtain an ephemeral port, then close it so connects will refuse.
my $ls;
socket($ls, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
setsockopt($ls, SOL_SOCKET, SO_REUSEADDR, pack("i", 1));
bind($ls, pack_sockaddr_in(0, inet_pton(AF_INET, "127.0.0.1"))) or die "bind: $!";
listen($ls, 1) or die "listen: $!";
my ($port) = unpack("x2n", getsockname($ls));
close $ls;

my $N = $ENV{N} // 500;

my $done = 0;
my $ok = 0;
my $err = 0;
my $unexpected_ok = 0;

# Safety stop: if we don't finish quickly, fail and stop.
$loop->after(2, sub ($loop2) {
  fail("stress timed out: done=$done ok=$ok err=$err (N=$N)");
  $loop2->stop;
});

for (1..$N) {
  Linux::Event::Connect->new(
    loop => $loop,
    host => '127.0.0.1',
    port => $port,
    timeout_s => 0.5,

    on_connect => sub ($r, $fh, $data) {
      $unexpected_ok++;
      close $fh;
      $done++;
      $ok++;
      $loop->stop if $done >= $N;
    },

    on_error => sub ($r, $errno, $data) {
      $done++;
      $err++;
      $loop->stop if $done >= $N;
    },
  );
}

$loop->run;

is($done, $N, "all requests completed");
is($unexpected_ok, 0, "no unexpected success");
ok($err + $ok == $N, "accounting sane");

done_testing;
