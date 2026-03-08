use v5.36;
use strict;
use warnings;

use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
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

my $loop  = Linux::Event->new;
my $waker = $loop->waker;

my $timeout_id = $loop->after(2.0, sub ($loop) {
  diag "TIMEOUT after 2.0s";
  $loop->stop;
  $waker->signal;
});

my $s = Linux::Event::Stream->new(
  loop       => $loop,
  fh         => $a,
  codec      => 'line',
  on_message => sub ($s, $msg, $data) { },
);

my $drain = '';
$loop->watch($b,
  read => sub ($loop, $fh, $watcher) {
    while (1) {
      my $buf = '';
      my $n = sysread($fh, $buf, 8192);
      last if !defined($n) && ($!+0 == 11);
      die "sysread error: $!" if !defined $n;
      last if $n == 0;
      $drain .= $buf;
    }

    if (length($drain) >= 3) {
      $s->close;
      $loop->cancel($timeout_id);
      $loop->stop;
      $waker->signal;
    }
  },
);

ok($s->write_message('hi'), 'write_message accepted');

$loop->run;

is($drain, "hi\n", 'line codec appended newline');

done_testing;
