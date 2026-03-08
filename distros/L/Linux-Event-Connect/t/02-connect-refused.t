use v5.36;
use Test::More;

use Linux::Event;
use Linux::Event::Connect;

use Socket qw(SOCK_STREAM SOL_SOCKET SO_REUSEADDR inet_pton AF_INET pack_sockaddr_in);
use Errno ();

my $loop = Linux::Event->new;

# Create a listener to obtain an ephemeral port, then close it to make connect refuse.
my $ls;
socket($ls, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
setsockopt($ls, SOL_SOCKET, SO_REUSEADDR, pack("i", 1));
bind($ls, pack_sockaddr_in(0, inet_pton(AF_INET, "127.0.0.1"))) or die "bind: $!";
listen($ls, 1) or die "listen: $!";
my ($port) = unpack("x2n", getsockname($ls));
close $ls;

my $called = 0;
my $got_errno;

my $req = Linux::Event::Connect->new(
  loop => $loop,
  host => '127.0.0.1',
  port => $port,
  timeout_s => 0.25,
  on_error => sub ($r, $errno, $data) {
    $called = 1;
    $got_errno = $errno;
    $loop->stop;
  },
  on_connect => sub ($r, $fh, $data) {
    $called = 1;
    $got_errno = 0;
    close $fh;
    $loop->stop;
  },
);

$loop->run;

ok($called, "callback fired");
ok(defined $got_errno, "errno captured");
ok($req->is_done, "request done");

# Most systems should return ECONNREFUSED; allow other nonzero failure errno under unusual races.
ok($got_errno == 0 || $got_errno == Errno::ECONNREFUSED() || $got_errno == Errno::EHOSTUNREACH() || $got_errno == Errno::ENETUNREACH(),
  "errno is plausible (got $got_errno)");

done_testing;
