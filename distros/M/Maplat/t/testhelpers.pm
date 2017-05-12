sub connect_memcached {
    my $hostname = "localhost";
    my $port = 11211;
    my $timeout = 5;    
    my $response;        
    
    eval {
        local $SIG{ALRM} = sub { die "early exit - SIGALRM caught" };
        alarm $timeout*2; #twice longer than timeout used later by select()  
 
        my $iaddr = inet_aton($hostname) || die "inet_aton: $!";
        my $paddr = sockaddr_in($port, $iaddr) || die "sockaddr_in: $!";
        my $proto = getprotobyname('tcp') || die "getprotobyname: $!";
        socket(SOCK, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
        connect(SOCK, $paddr) || die "connect: $!";
        
        (close SOCK) || die "close(): $!";
        alarm 0;
    }; 
    if ($@) {
      	return "[ERROR] $@";
    }
    else {
        return "OK";
    }    
}

1;

