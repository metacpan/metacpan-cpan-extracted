#!#!/usr/bin/perl
#
# Copyright (C) 2012 by Mark Hindess

use strict;
use Socket;
use Test::More;
use Test::Requires qw/Test::SharedFork/;
use Test::SharedFork;
use Device::Onkyo;
use IO::Socket::INET;

socket my $s, PF_INET, SOCK_DGRAM, getprotobyname('udp');
setsockopt $s, SOL_SOCKET, SO_BROADCAST, 1;
binmode $s;
bind $s, sockaddr_in(0, inet_aton('127.0.0.1'))
  or plan skip_all => "Failed to bind to loopback address: $!";
my ($port, $addr) = sockaddr_in(getsockname($s));
my $tcp =
  IO::Socket::INET->new(Listen => 5, Proto => 'tcp',
                        LocalAddr => '127.0.0.1', LocalPort => 0)
  or plan skip_all => "Failed to listen on loopback address: $!";
my $tcp_port = $tcp->sockport;

my $pid = fork();
if ($pid == 0) {
  # child
  my $sel = IO::Select->new($s);
  $sel->can_read(10) or die;
  my $sender = recv $s, my $buf, 2048, 0;
  die 'error: '.$! unless (defined $sender);
  my $m = "!1ECNECNTX-NR609/".$tcp_port."/XX/0009B0123456\r\n";
  send($s, pack("a* N N N a*", 'ISCP', 0x10, length $m, 0x01000000, $m),
       0, $sender);
  $sel = IO::Select->new($tcp);
  $sel->can_read(10) or die;
  my $client = $tcp->accept;
  ok $client, 'client accepted';
  $sel = IO::Select->new($client);
  $sel->can_read(10) or die;
  my $bytes = sysread $client, $buf, 2048;
  is $bytes, 24, '... power on length';
  is_deeply [ unpack 'a4 N N N a*', $buf ],
    ['ISCP', 0x10, 0x8, 0x01000000, "!1PWR01\r"], '... power on';
} elsif ($pid) {
  # parent
  my $onkyo = Device::Onkyo->new(device => 'discover', port => $port,
                                 broadcast_dest_ip => '127.0.0.1',
                                 broadcast_source_ip => '127.0.0.1');
  ok $onkyo, 'object';
  is $onkyo->port, $tcp_port, '... discovered';
  $onkyo->command('power on');
  waitpid $pid, 0;
  done_testing;
} else {
  die $!;
}
