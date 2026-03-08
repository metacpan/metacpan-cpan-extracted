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

my $timed_out = 0;
my $timeout_id = $loop->after(2.0, sub ($loop) {
  $timed_out = 1;
  diag "TIMEOUT after 2.0s";
  $loop->stop;
  $waker->signal;
});

my $errors = 0;
my $last;
my $closed = 0;

my $s = Linux::Event::Stream->new(
  loop       => $loop,
  fh         => $a,
  codec      => 'line',
  max_inbuf  => 10,
  on_message => sub ($s, $line, $data) {
    fail('should not emit messages when max_inbuf is exceeded');
  },
  on_error => sub ($s, $errno, $data) {
    $errors++;
    is($errno, 0, 'errno is 0 for codec/buffer errors');
    $last = $s->last_error;
  },
  on_close => sub ($s, $data) {
    $closed++;
    $loop->cancel($timeout_id);
    $loop->stop;
    $waker->signal;
  },
);

# Exceed max_inbuf without ever providing a newline.
$loop->after(0.01, sub ($loop) {
  syswrite($b, 'x' x 32);
});

$loop->run;

ok(!$timed_out, 'did not timeout') or BAIL_OUT('max_inbuf test timed out');
ok($errors >= 1, 'on_error fired');
like($last // '', qr/^codec:max_inbuf_exceeded:10\z/, 'last_error describes max_inbuf failure');
is($closed, 1, 'on_close fired once');

done_testing;
