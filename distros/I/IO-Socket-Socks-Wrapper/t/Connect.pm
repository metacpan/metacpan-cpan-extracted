package Connect;

use strict;
use Socket;

sub make {
	my ($addr, $port) = @_;
	
	my $paddr = sockaddr_in($port, inet_aton($addr)||return);
	my $proto = getprotobyname('tcp');
	
	socket(my $sock, PF_INET, SOCK_STREAM, $proto) || return;
	connect($sock, $paddr) || return;
	
	return $sock;
}

1;
