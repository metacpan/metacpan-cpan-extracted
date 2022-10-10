use Test::More tests=>7;
use IO::FD;

use Socket ":all";

{
	#Create a pipe
	ok defined( IO::FD::socketpair(my $sock1, my $sock2, AF_UNIX, SOCK_DGRAM, 0)), "Socket pair creation";
	
	my $data="Data to write";

	#Send from sock1 to sock2


	ok defined(IO::FD::send($sock1,$data,0)), "Write to socket";
	
	my $buffer="";
	ok defined(IO::FD::recv($sock2, $buffer, 100, 0)), "read from pipe";
	ok $data eq $buffer, "Data comparison";


	#Send from sock2 to sock1
	ok defined(IO::FD::send($sock2, $data, 0)), "Write to socket";
	
	$buffer="";
	ok defined(IO::FD::recv($sock1, $buffer, 100, 0)), "read from pipe";

	ok $data eq $buffer, "Data comparison";


	IO::FD::close $sock1;
	IO::FD::close $sock2;
}
