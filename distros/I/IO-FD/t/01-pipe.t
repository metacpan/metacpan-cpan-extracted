use Test::More;
use IO::FD;


{
	#Create a pipe
	ok defined( IO::FD::pipe(my $read,my $write)), "Pipe creation";
	
	my $data="Data to write";
	ok defined(IO::FD::syswrite($write,$data)), "Write to pipe";
	
	my $buffer="";
	ok defined(IO::FD::sysread($read, $buffer, 100)), "read from pipe";

	ok $data eq $buffer, "Data comparison";
	IO::FD::close $read;
	IO::FD::close $write;
}
{
  eval {
    my $ret=IO::FD::pipe "",undef;
  };
  ok $@, "no readonly arguments in pipe";

}
done_testing;
