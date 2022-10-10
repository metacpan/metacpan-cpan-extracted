use Test::More tests=>7;
use IO::FD;

use Socket ":all";

{
	#Create a pipe
	ok defined( IO::FD::socketpair(my $sock1,my $sock2, AF_UNIX, SOCK_STREAM,0)), "Socket pair creation";
	
	my $data="Data to write";

	#Send from sock1 to sock2


	ok defined(IO::FD::syswrite($sock1,$data)), "Write to socket";
	
	my $buffer="";
	ok defined(IO::FD::sysread($sock2, $buffer, 100)), "read from pipe";
	ok $data eq $buffer, "Data comparison";


	#Send from sock2 to sock1
	ok defined(IO::FD::syswrite($sock2,$data)), "Write to socket";
	
	$buffer="";
	ok defined(IO::FD::sysread($sock1, $buffer, 100)), "read from pipe";

	ok $data eq $buffer, "Data comparison";


	IO::FD::close $sock1;
	IO::FD::close $sock2;
}
