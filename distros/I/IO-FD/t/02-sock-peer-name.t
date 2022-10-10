use Test::More tests=>10;

use strict;
use warnings;

use IO::FD;
use Fcntl;
use Socket ":all";
use Errno qw<EINTR EAGAIN :POSIX>;
use Time::HiRes qw<sleep>;

ok defined IO::FD::socket(my $socket, AF_INET, SOCK_STREAM, 0), "Create socket";
ok defined IO::FD::setsockopt($socket, SOL_SOCKET, SO_REUSEADDR,1);

#ok defined IO::FD::fcntl($socket, F_SETFL, O_NONBLOCK);

my ($error,@res)=getaddrinfo("0.0.0.0",0, {flags=>AI_PASSIVE});	#Pick a port

ok defined $res[0]{addr}, "Local address";
my $bind_addr=$res[0]{addr};

ok defined(IO::FD::bind($socket, $bind_addr)), "Binding ok";
my $addr= IO::FD::getsockname($socket);

ok sockaddr_family($bind_addr) eq sockaddr_family($addr), "getsockname";



ok defined($error=IO::FD::listen($socket, 10)), "Listening";

die "Could not listen: $!" unless $error;

my $port;
($error,undef,$port)=getnameinfo($addr);

die "Could not get name info: $error" if $error;
#now connect to the listening socket


ok defined IO::FD::socket(my $client, AF_INET,SOCK_STREAM, 0);
ok defined IO::FD::fcntl($client, F_SETFL, O_NONBLOCK);


($error,@res)=getaddrinfo("127.0.0.1", $port, {flags=>AI_NUMERICHOST});
die "could not get address" if $error;


#NOTE: Nonblocking connect will return with EINPROGRESS.
# We assume all is ok as the accepting socket is blocking.
unless(IO::FD::connect($client, $res[0]{addr})){
	die "Error in connect" if $! != EINPROGRESS;
}

my $peer=IO::FD::accept(my $c, $socket);
if($peer){
	IO::FD::syswrite($c,"HELLO!");
}
else {
	die "Error accepting";
}

my $peer_name= IO::FD::getpeername($c);

ok sockaddr_family($bind_addr) eq sockaddr_family($addr), "getpeername";

ok $peer_name eq IO::FD::getsockname($client),"getsockname";

IO::FD::close($socket);
IO::FD::close($client);
IO::FD::close($c);
