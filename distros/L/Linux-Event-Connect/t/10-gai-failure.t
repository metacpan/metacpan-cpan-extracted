use v5.36;
use Test::More;

use Linux::Event;
use Linux::Event::Connect;
use Errno ();

my $loop = Linux::Event->new;

my $called = 0;
my $errno;
my $gai;

# Host contains a space, which should be rejected by getaddrinfo without DNS.
my $req = Linux::Event::Connect->new(
  loop => $loop,
  host => "not a host name",
  port => 80,
  on_error => sub ($r, $e, $data) {
    $called = 1;
    $errno = $e;
    $gai = $r->gai_error;
  },
  on_connect => sub ($r, $fh, $data) {
    fail("unexpected connect success");
    close $fh;
  },
);

ok($req->is_done, "request finished immediately");
ok($called, "on_error was called");
ok(defined $gai && $gai ne '', "gai_error string stored");
ok(!defined $req->fh, "no fh remains");

# Mapping policy:
# - if the getaddrinfo error looks like NONAME/NODATA/NO_DATA -> ENOENT
# - otherwise -> EIO
if ($gai =~ /NONAME|NODATA|NO_DATA/i) {
  is($errno, Errno::ENOENT(), "gai error maps to ENOENT for NONAME-like failures");
} else {
  is($errno, Errno::EIO(), "gai error maps to EIO for other failures");
}

done_testing;
