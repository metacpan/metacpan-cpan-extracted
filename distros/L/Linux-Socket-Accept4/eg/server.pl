use strict;
 
use blib;
use Linux::Socket::Accept4;

use Socket;

my $port = 6666;

print "PID:$$ PORT:$port\n";

socket(my $server, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or die;
setsockopt($server, SOL_SOCKET, SO_REUSEADDR, 1)
   or die "Can't set socket option to SO_REUSEADDR $!\n";
bind($server, pack_sockaddr_in($port, INADDR_ANY)) or die;
listen($server, SOMAXCONN) or die;

# while(my $sockaddr = accept(my $csock, $server)){
while(my $sockaddr = accept4(my $csock, $server, SOCK_CLOEXEC)){
	my $org_handle = select($csock); $| = 1; select($org_handle);
	while (<$csock>){
		print {$csock} $_;
	}
    print `ls -1 /proc/$$/fd/ | wc -l`, "\n";
}

