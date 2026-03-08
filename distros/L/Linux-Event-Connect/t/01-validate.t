use v5.36;
use Test::More;

use Linux::Event;
use Linux::Event::Connect;
use Socket qw(AF_INET);
use Errno ();

sub croaks_like ($code, $re, $name) {
  my $ok;
  my $err;
  {
    local $@;
    eval { $code->(); 1 } and $ok = 0;
    $err = $@;
    $ok = 1 if $err ne '';
  }
  ok($ok, $name);
  like($err, $re, "$name (message)");
}

my $loop = Linux::Event->new;

croaks_like(
  sub { Linux::Event::Connect->new(loop => $loop, host => '127.0.0.1') },
  qr/port is required/,
  "host without port croaks",
);

croaks_like(
  sub { Linux::Event::Connect->new(loop => $loop, port => 1234) },
  qr/host is required/,
  "port without host croaks",
);

croaks_like(
  sub { Linux::Event::Connect->new(loop => $loop, host => '127.0.0.1', port => 'http') },
  qr/port must be an integer/,
  "non-integer port croaks",
);

croaks_like(
  sub { Linux::Event::Connect->new(loop => $loop, host => '127.0.0.1', port => 80, family => AF_INET) },
  qr/family is not allowed in host\/port mode/,
  "family forbidden in host/port mode",
);

croaks_like(
  sub { Linux::Event::Connect->new(loop => $loop, unix => '/tmp/x.sock', host => 'x', port => 1) },
  qr/exactly one address mode/,
  "multiple modes croak",
);

croaks_like(
  sub { Linux::Event::Connect->new(loop => $loop, sockaddr => "x", family => AF_INET, type => 1) },
  qr/type is not allowed in sockaddr mode/,
  "type forbidden in sockaddr mode v0.001",
);

croaks_like(
  sub { Linux::Event::Connect->new(loop => $loop, sockaddr => "x") },
  qr/family is required in sockaddr mode/,
  "sockaddr mode requires family",
);

croaks_like(
  sub { Linux::Event::Connect->new(loop => $loop, host => '127.0.0.1', port => 1, nonblocking => 0) },
  qr/nonblocking must be true/,
  "nonblocking false croaks",
);

croaks_like(
  sub { Linux::Event::Connect->new(loop => $loop, host => '127.0.0.1', port => 1, frob => 1) },
  qr/unknown option\(s\)/,
  "unknown keys croak",
);

done_testing;
