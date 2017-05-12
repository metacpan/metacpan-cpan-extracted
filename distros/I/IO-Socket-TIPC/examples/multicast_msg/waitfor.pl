#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::TIPC 'TIPC_MAX_USER_MSG_SIZE';

my $socket = IO::Socket::TIPC->new(
	SocketType => 'rdm',
	Local => '{1935081472, 1}',
	LocalScope => 'zone',
);

my $match = shift;

die "Usage: $0 \"<searchpattern>\"\n" unless defined $match;

while(1) {
	my $string;
	my $sender = $socket->recvfrom($string, TIPC_MAX_USER_MSG_SIZE);
	if(defined($string)) {
		if(length($string) >= length($match)) {
			if(substr($string, 0, length($match)) eq $match) {
				print($string, "\n");
				exit 0;
			}
		}
	} else {
		if(defined($sender)) {
			my $id = $sender->stringify();
			print("got undefined data from peer $id\n");
		}
	}
}
