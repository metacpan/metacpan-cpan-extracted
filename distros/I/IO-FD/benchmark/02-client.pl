use lib "lib";
use lib "blib/lib";
use lib "blib/arch";
use IO::FD;

use Socket ":all";
my $sock_file=$ARGV[0]//"test.sock";
my $counter=$ARGV[1]//100_000;

my $addr=pack_sockaddr_un($sock_file);
my $complete=0;
for(1..$counter){
	die "Could not create socket $!" unless defined IO::FD::socket my $socket, AF_UNIX, SOCK_STREAM, 0;
	#say STDERR "Socket is: $socket";
	warn("could not connect $!") and last unless defined IO::FD::connect($socket, $addr);
	IO::FD::close $socket;
	$complete=$_;
}
say STDERR "COUNTER: $complete";
