#!/usr/bin/perl

use warnings;
use strict;

use Socket;

my $s = shift || "/var/tmp/my.sock";

unlink($s) or die("Unable to unlink socket - check permissions\n");

# Since this listeners creates the socket file, the Appender needs
# the correct permissions to stream to it. Change when needed.
#umask(000);

socket(my $socket, PF_UNIX, SOCK_DGRAM, 0);
bind($socket, sockaddr_un($s));

while (1) {
	while (<$socket>) { print $_; }
}

