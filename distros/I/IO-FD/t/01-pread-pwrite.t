use Test::More;

use IO::FD;
use Fcntl;
use POSIX "errno_h";

{
	#Create an temp fd 
	my $fd=IO::FD::mkstemp("/tmp/mytempXXXXXXXXX");
	ok defined($fd), "Temp fd";

	#Write data to it
  my $buffer="HelloHello";#x100;
  
  #ok defined(IO::FD::syswrite($fd,$buffer)), "2 argument write: $!";

  # pwrite ignores the file position. test appending by specifing the position
  #
  ok defined(IO::FD::pwrite($fd,$buffer,5,0)), "pwrite";
  ok defined(IO::FD::pwrite($fd,$buffer,5,5)), "pwrite";

  my $input;

  $input="";

  # Sysread updates the file position. Currently the position is 0
  # as pwrite does not update file position
  #
  ok defined(IO::FD::sysread $fd, $input, 10), "Verify pwrite";

  ok $input eq $buffer,"Verify pwrite";


  # pread ignores the file position. So the previous sysread has no effect
	$input="";
	ok defined(IO::FD::pread($fd, $input, 5,0)), "pread";
	ok $input eq substr($buffer,0,5), "Input and output ok";

  $input="";
	ok defined(IO::FD::pread($fd, $input, 5,1)), "pread";
	ok $input eq substr($buffer,1,5), "Input and output ok";
	IO::FD::close $fd;
}
done_testing;
