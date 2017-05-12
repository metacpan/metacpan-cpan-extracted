#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::TIPC;

my $socket = IO::Socket::TIPC->new(SocketType => 'rdm');
my $dest = IO::Socket::TIPC::Sockaddr->new('{1935081472, 1, 1}');

my $string = shift;
chomp $string; # the recipient(s) can add it back if they want to.

$socket->sendto($dest, $string);
