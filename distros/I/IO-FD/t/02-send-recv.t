use Test::More;
use IO::FD;

use Socket ":all";
use POSIX "errno_h";

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

{

  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::recv called with something other than a file descriptor/, "Got warning";
  };
  my $ret=IO::FD::recv "",my $buf, undef,undef;
  ok !defined($ret), "Undef for bad fd";
  ok $! == EBADF,"bad fd";

  eval {
    my $ret=IO::FD::recv 0, "", undef,undef;
  };

  ok $@ =~ "Modification of a read-only value attempted", "Die on readonly buffer";
  
}
{

  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::send called with something other than a file descriptor/, "Got warning";
  };
  my $ret=IO::FD::send "",my $buf, undef,undef;
  ok !defined($ret), "Undef for bad fd";
  ok $! == EBADF,"bad fd";
  
}


done_testing;
