use v5.36;
use strict;
use warnings;

use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

use Linux::Event;
use Linux::Event::Stream;

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";

sub set_nonblocking ($fh) {
  my $flags = fcntl($fh, F_GETFL, 0);
  die "fcntl(F_GETFL): $!" if !defined $flags;
  return if $flags & O_NONBLOCK;
  fcntl($fh, F_SETFL, $flags | O_NONBLOCK) or die "fcntl(F_SETFL): $!";
}

set_nonblocking($a);
set_nonblocking($b);

# Shrink kernel send buffer so we hit EAGAIN sooner (Linux may clamp/double).
setsockopt($a, SOL_SOCKET, SO_SNDBUF, pack("i", 1024))
or die "setsockopt(SO_SNDBUF): $!";

my $loop  = Linux::Event->new;
my $waker = $loop->waker;

my $timed_out = 0;
my $timeout_id = $loop->after(8, sub ($loop) {
  $timed_out = 1;
  diag "TIMEOUT after 8s";
  $loop->stop;
  $waker->signal;
});

# Pre-fill kernel send buffer so Stream must buffer in userland.
my $junk = 'j' x 8192;
while (1) {
  my $n = syswrite($a, $junk);
  last if !defined($n) && ($!+0 == 11); # EAGAIN
  last if !defined $n;                  # best-effort
}

my $s = Linux::Event::Stream->new(
  loop => $loop,
  fh   => $a,
  high_watermark => 1024,
  low_watermark  => 256,
);

ok(!$s->is_write_blocked, 'starts unblocked');

# Put marker at the START so we can tell reads began without requiring full drain.
my $marker  = "<STREAM:WM:$^T:$$:" . int(rand(1_000_000)) . ">";
my $payload = $marker . ('x' x 400_000);

ok($s->write($payload), 'write payload');
ok($s->is_write_blocked, 'becomes blocked above high watermark');

my $drain = '';
my $seen  = 0;

# Keep watcher alive (RAII).
my $wb = $loop->watch($b, read => sub ($loop, $fh, $watcher) {
  while (1) {
    my $buf = '';
my $n = sysread($fh, $buf, 8192);

last if !defined($n) && ($!+0 == 11); # EAGAIN
die "sysread error: $!" if !defined $n;
last if $n == 0;                      # EOF

$drain .= $buf;
  }

  $seen = 1 if !$seen && index($drain, $marker) >= 0;
});

my $poll_id;
sub poll ($loop) {
  if ($seen && !$s->is_write_blocked) {
    $loop->cancel($timeout_id);
    $loop->cancel($poll_id) if defined $poll_id;
    $s->close;
    $loop->stop;
    $waker->signal;
    return;
  }
  $poll_id = $loop->after(0.001, \&poll);
}
$poll_id = $loop->after(0.001, \&poll);

$loop->run;

ok(!$timed_out, 'did not timeout')
or BAIL_OUT("watermarks test timed out");

ok($seen, 'peer began receiving payload');
ok(!$s->is_write_blocked, 'unblocked after draining below low watermark');

done_testing;
