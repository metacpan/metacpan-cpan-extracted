#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::TIPC 'TIPC_MAX_USER_MSG_SIZE';

my $socket = IO::Socket::TIPC->new(
	SocketType => 'rdm',
	Local => '{1935081472, 1}',
	LocalScope => 'zone',
);

while(1) {
	my $string;
	my $sender = $socket->recvfrom($string, TIPC_MAX_USER_MSG_SIZE);
	if(defined($string)) {
		print($string, "\n");
	} else {
		if(defined($sender)) {
			my $id = $sender->stringify();
			print("got undefined data from peer $id\n");
		}
	}
}
