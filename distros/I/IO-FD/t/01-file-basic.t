use Test::More tests=>11;

use IO::FD;
use Fcntl;

#Test opening a file in different modes

{
	#A temp path
	my $name=IO::FD::mktemp("/tmp/mytempXXXXXXXXX");
	ok defined($name), "Temp file name ok";

	#Open with create and read only
	ok IO::FD::sysopen(my $fd, $name, O_CREAT|O_RDONLY,0), "Opening $name: $!";

	#Close
	ok IO::FD::close($fd), "Closing fd";

	#Test for double close
	ok !defined(IO::FD::close($fd)), "Double Closing fd";
}

{
	#Create a tempfile and return fd
	my $fd=IO::FD::mkstemp("/tmp/mytempXXXXXXXXX");
	ok defined($fd), "Temp fd ok";

	ok IO::FD::close($fd), "Closing fd";
}


{
	#Create an temp fd 
	my $fd=IO::FD::mkstemp("/tmp/mytempXXXXXXXXX");
	ok defined($fd), "Temp fd";

	#Write data to it
	my $buffer="Hello world";
	ok defined(IO::FD::syswrite($fd,$buffer)), "2 argument write: $!";

	#seek back to start
	ok defined(IO::FD::sysseek($fd,0,0)), "Seek file";


	#Read with general sysread
	$input="";
	ok defined(IO::FD::sysread($fd,$input,20)), "general sysread";

	#compare
	ok $input eq $buffer, "Input and output ok";

	IO::FD::close $fd;
}

