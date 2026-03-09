#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Socket qw(AF_INET INADDR_LOOPBACK SOCK_STREAM SOL_SOCKET SO_REUSEADDR pack_sockaddr_in sockaddr_in inet_ntoa);
use Linux::Event::Loop;

socket(my $listen, AF_INET, SOCK_STREAM, 0) or die "socket failed: $!";
setsockopt($listen, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsockopt failed: $!";
bind($listen, pack_sockaddr_in(0, INADDR_LOOPBACK)) or die "bind failed: $!";
listen($listen, 16) or die "listen failed: $!";

my ($port, $addr) = sockaddr_in(getsockname($listen));
my $loop = Linux::Event::Loop->new(model => 'proactor', backend => 'uring');

socket(my $client, AF_INET, SOCK_STREAM, 0) or die "client socket failed: $!";

$loop->accept(
  fh          => $listen,
  on_complete => sub ($op, $result, $data) {
    die $op->error->message if $op->failed;
    my ($peer_port, $peer_addr) = sockaddr_in($result->{addr});
    say "accepted peer=" . inet_ntoa($peer_addr) . ":$peer_port";
    $loop->close(fh => $result->{fh});
  },
);

$loop->connect(
  fh          => $client,
  addr        => pack_sockaddr_in($port, INADDR_LOOPBACK),
  on_complete => sub ($op, $result, $data) {
    die $op->error->message if $op->failed;
    say "connect completed";
    $loop->shutdown(fh => $client, how => 'both');
    $loop->close(fh => $client);
    $loop->stop;
  },
);

$loop->run;
