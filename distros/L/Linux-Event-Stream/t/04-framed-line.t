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
});

my @got;
my $closed = 0;
my $errors = 0;

my $s = Linux::Event::Stream->new(
  loop       => $loop,
  fh         => $a,
  codec      => 'line',
  on_message => sub ($s, $line, $data) {
    push @got, $line;
    if (@got == 3) {
      $s->close;
      $loop->cancel($timeout_id);
      $loop->stop;
      $waker->signal;
    }
  },
  on_error => sub ($s, $errno, $data) {
    $errors++;
  },
  on_close => sub ($s, $data) { $closed++ },
);

# Write two full lines and a partial line, then complete it later.
my $t1 = $loop->after(0.01, sub ($loop) {
  syswrite($b, "one\ntwo\npart");
});

my $t2 = $loop->after(0.02, sub ($loop) {
  syswrite($b, "ial\n");
});

$loop->run;

is_deeply(\@got, [qw(one two partial)], 'received framed lines');
is($errors, 0, 'no errors');
is($closed, 1, 'on_close fired once');

done_testing;
