use v5.36;
use strict;
use warnings;

use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Socket qw(
  AF_INET SOCK_STREAM SOL_SOCKET SO_REUSEADDR
  inet_pton pack_sockaddr_in
);

use Linux::Event;
use Linux::Event::Connect;

my $have_stream = eval {
  require Linux::Event::Stream;
  1;
};

die "This example requires Linux::Event::Stream\n" if !$have_stream;

my $loop = Linux::Event->new;

# Safety: stop after 5 seconds so this example never hangs silently.
$loop->after(5, sub ($loop2) {
  die "timeout: did not complete within 5s\n";
});

# Tiny echo server: accept one connection, echo one line, then close.
my $ls;
socket($ls, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
setsockopt($ls, SOL_SOCKET, SO_REUSEADDR, pack("i", 1)) or die "setsockopt: $!";
bind($ls, pack_sockaddr_in(0, inet_pton(AF_INET, "127.0.0.1"))) or die "bind: $!";
listen($ls, 10) or die "listen: $!";
my ($port) = unpack("x2n", getsockname($ls));

my $server_done = 0;

$loop->watch($ls,
  read => sub ($loop2, $fh, $watcher) {
    my $client;
    accept($client, $fh) or die "accept: $!";
    $loop2->unwatch($fh);
    close $fh;

    # nonblocking client socket
    my $flags = fcntl($client, F_GETFL, 0);
    fcntl($client, F_SETFL, $flags | O_NONBLOCK);

    my $buf = '';

    $loop2->watch($client,
      read => sub ($loop3, $c, $w) {
        my $tmp = '';
        my $n = sysread($c, $tmp, 4096);
        if (!defined $n) {
          return if $!{EAGAIN} || $!{EWOULDBLOCK};
          die "server read error: $!\n";
        }
        if ($n == 0) {
          $loop3->unwatch($c);
          close $c;
          $server_done = 1;
          $loop3->stop;
          return;
        }

        $buf .= $tmp;
        if ($buf =~ /\n/) {
          syswrite($c, $buf);
          $loop3->unwatch($c);
          close $c;
          $server_done = 1;
          $loop3->stop;
        }
      },
      error => sub ($loop3, $c, $w) {
        $loop3->unwatch($c);
        close $c;
        die "server socket error\n";
      },
    );
  },
);

my $req = Linux::Event::Connect->new(
  loop => $loop,
  host => '127.0.0.1',
  port => $port,
  timeout_s => 2,

  data => { loop => $loop, got => '' },

  on_connect => sub ($req, $fh, $data) {
    my $stream = Linux::Event::Stream->new(
      loop => $data->{loop},
      fh   => $fh,

      on_read => sub ($stream2, $bytes, $buf) {
        $data->{got} .= $buf;
        if ($data->{got} =~ /\n/) {
          print "Client got: $data->{got}";
          $data->{loop}->stop;
        }
      },

      on_error => sub ($stream2, $errno, $data2) {
        $data2->{loop}->stop;
      },

      on_close => sub ($stream2, $data2) {
        $data2->{loop}->stop;
      },

      data => $data,
    );

    $stream->write("ping\n");
  },

  on_error => sub ($req, $errno, $data) {
    $! = $errno;
    die "Connect failed: $errno ($!)\n";
  },
);

$loop->run;

die "server did not complete\n" if !$server_done;
