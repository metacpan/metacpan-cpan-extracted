# Test using UDP with two IO::Multiplex
# servers communicating with each other.
# Assume no UDP packet loss on loopback.

# This script tests the following:
# 1) Sending packets using a connected UDP socket.
#    (connect() and send() syscalls)
# 2) Sending packets using unconnected UDP socket.
#    (sendto() syscall)
# 3) Receiving UDP packets.
#    (bind() and recv() syscalls)
# 4) The tied handle interface to send UDP data.
#    print $fh $UDP_data;
# 5) The mux_input interface for incoming UDP data.
#    (simple $$data scalar consumption)

use strict;
use Test;
use IO::Socket;
use IO::Multiplex;
use POSIX qw(ENOTCONN EDESTADDRREQ);

if($^O eq 'MSWin32')
{   no warnings;
    *ENOTCONN = sub() {10057};
}

$| = 1;
plan tests => 15;

# Create a recv()ing socket.
ok my $sock1 = new IO::Socket::INET
  LocalAddr => "127.0.0.1",
  Proto => "udp",
  or die $!;

my $magic_port = $sock1->sockport;

# Create connect()ed socket for send()ing.
ok my $sock2 = new IO::Socket::INET
  PeerAddr => "127.0.0.1",
  PeerPort => $magic_port,
  Proto => "udp",
  or die $!;

# Create a generic unconnected socket for sendto()ing.
ok my $sock3 = new IO::Socket::INET
  Proto => "udp"
  or die $!;

my $msg1 = "uno";
my $msg2 = "dos";
my $msg3 = "tres";
my $msg4 = "cuatro";
my $msg5 = "cinco";
my $msg6 = "seis";

my $pid = fork();
# Catch runaway processes just in case...
alarm(10);
$SIG{ALRM} = sub {
  die "[$$] Got bored";
};

if (!defined $pid) {
  ok 0;
  die "fork: $!";
}

if ($pid) {
  # Parent process
  # This will be the Pitcher IO::Multiplex server.
  my $plexer = new IO::Multiplex;

  $plexer->add($sock2);
  $plexer->add($sock3);
  $plexer->set_callback_object("Pitcher");
  # Set timer to do mux_timeout in 2 seconds
  $plexer->set_timeout($sock2, 2);
  $plexer->loop;
  ok 1;
  exit;
} else {
  # Child process
  # This will be the Catcher IO::Multiplex server.
  # (No talking allowed.)
  my $plexer = new IO::Multiplex;

  $plexer->add($sock1);
  $plexer->set_callback_object("Catcher");

  $plexer->loop;
  exit;
}

sub Pitcher::mux_timeout {
  my $self    = shift;
  my $mux     = shift;
  my $fh      = shift;
  if (fileno $fh == fileno $sock2) {
    ok 1;
    # Connected UDP socket should know where to send it
    print $fh $msg1;
    ok !$!;
  } elsif (fileno $fh == fileno $sock3) {
    ok 1;
    # Unconnected UDP socket should fail
    # when trying to send() a packet.
    $! = 0;
    print $fh $msg2;
    ok ($! == ENOTCONN || $! == EDESTADDRREQ)
      or warn "DEBUG: bang = [$!](".($!+0).")";

    # Grab the real peer destination.
    ok my $saddr = $mux->{_fhs}{$sock2}{udp_peer};

    # Unconnected UDP socket will sendto() just fine
    # but only with an explicit destination.
    ok send($fh, $msg3, 0, $saddr);
    ok !$!;
  } else {
    die "$$: Not my fh?";
  }
}

sub Pitcher::mux_input {
  my $package = shift;
  my $mux     = shift;
  my $fh      = shift;
  my $data    = shift;
  if (fileno $fh == fileno $sock2) {
    ok ($$data eq $msg2);
    $mux->set_timeout($sock3, 3);
  } elsif (fileno $fh == fileno $sock3) {
    if ($$data eq $msg4) {
      ok 1;
      # Even though this was the unconnected socket,
      # it should remember where the last packer came from.
      print $fh $msg5;
      ok !$!;
    } elsif ($$data eq $msg6) {
      # Yippy, caught the final packet
      ok 1;
      # All done
      $mux->endloop;
    } else {
      die "sock3 caught weird [$$data]";
    }
  } else {
    die "$$: Pitcher found something weird [$$data]";
  }
  $$data = "";
}

# Just bounce it back with one up
sub Catcher::mux_input {
  my $package = shift;
  my $mux     = shift;
  my $fh      = shift;
  my $data    = shift;
  if ($$data eq $msg1) {
    print $fh $msg2;
  } elsif ($$data eq $msg3) {
    print $fh $msg4;
  } elsif ($$data eq $msg5) {
    print $fh $msg6;
    # I'm done.
    $mux->endloop;
  } else {
    die "$$: Caught something weird [$$data]";
  }
  $$data = "";
}
