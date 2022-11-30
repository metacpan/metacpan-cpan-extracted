use Test::More;

use strict;
use warnings;

use IO::FD;
use Fcntl;
use Socket ":all";
use Errno qw<EINTR EAGAIN :POSIX>;
use Time::HiRes qw<sleep>;



#Create a listener 

ok defined IO::FD::socket my $listener, AF_INET, SOCK_STREAM, 0;
ok defined IO::FD::fcntl($listener, F_SETFL, O_NONBLOCK);
ok defined IO::FD::setsockopt $listener, SOL_SOCKET, SO_REUSEADDR, 1;
my $error;
my @res;
my $ip;
my $port;
($error, @res)=getaddrinfo "0.0.0.0", 0, {flags=>AI_PASSIVE};
ok defined $res[0]{addr}, "Local bind address";

my $bind_addr=$res[0]{addr};

ok defined IO::FD::bind($listener, $bind_addr), "Bind ok";
my $addr=IO::FD::getsockname($listener);


ok defined ($error=IO::FD::listen($listener, 20)), "listen ok";


die  "Could not listen: $!" unless $error;

#my $port;

($error, $ip, $port)=getnameinfo($addr, NI_NUMERICHOST);

die "Could not get name info: $error" if $error;



#Create a number of clients
my @clients;
my $count=10;
for(1..$count){
	ok defined IO::FD::socket(my $client, AF_INET, SOCK_STREAM,0);
	ok defined IO::FD::fcntl($client, F_SETFL, O_NONBLOCK);
	($error,@res)=getaddrinfo("127.0.0.1", $port, {flags=>AI_NUMERICHOST});
	die "could not get address" if $error;
	
	my $peer=IO::FD::connect($client, $res[0]{addr});
	unless(defined  $peer){
		die "Error in connect: $!" if $! != EINPROGRESS;
	}

	#ok defined IO::FD::syswrite($client,"HELLO!")

	push @clients, $client;

}

sleep 1;

#Accept multiple clinets

my @fds;
my @peers;

ok defined IO::FD::accept_multiple @fds, @peers, $listener;



ok @fds==$count, "Accepted multiple";

for(@peers){
	#say STDERR length $_," peer: ", unpack "H*", $_;
	($error, $ip, $port)=getnameinfo($_, NI_NUMERICHOST);	
	ok $ip eq "127.0.0.1", "Peer IP ok";
}

IO::FD::close $_ for @clients;
IO::FD::close $listener;

done_testing;
