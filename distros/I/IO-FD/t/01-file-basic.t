use Test::More;# tests=>11;

use IO::FD;
use Fcntl;
use POSIX "errno_h";

#Test opening a file in different modes

{
	#A temp path
	my $name=IO::FD::mktemp("/tmp/mytempXXXXXXXXX");
	ok defined($name), "Temp file name ok";

	#Open with create and read only
	ok defined(IO::FD::sysopen(my $fd, $name, O_CREAT|O_RDONLY,0)), "Opening $name: $!";

	#Close
	ok defined(IO::FD::close($fd)), "Closing fd";

	#Test for double close
	ok !defined(IO::FD::close($fd)), "Double Closing fd";
}

{
	#Create a tempfile and return fd
	my $fd=IO::FD::mkstemp("/tmp/mytempXXXXXXXXX");
	ok defined($fd), "Temp fd ok";

	ok defined(IO::FD::close($fd)), "Closing fd";
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


{
	my $fd=IO::FD::mkstemp("/tmp/mytempXXXXXXXXX");
  die "Could not create tmp file" unless defined($fd);


  # Test syswrite sanity for undefined buffer. perl does a warning and returns 0
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::syswrite called with use of uninitialized value/, "Got warning";
  };
	my $ret=IO::FD::syswrite($fd,undef);
  ok $ret==0, "Zero byte count for undef buffer write";


  # Test syswrite sanity for non fd. perl does a warning for bad filehandles and returns undef
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::syswrite called with something other than a file descriptor/, "Got warning";
  };
	my $ret=IO::FD::syswrite("asdf","asdf");
  ok !defined($ret), "Zero byte count for undef buffer write";
  ok $!==EBADF;


  # Test syswrite2 sanity for undefined buffer. perl does a warning and returns 0
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::syswrite called with use of uninitialized value/, "Got warning";
  };
	my $ret=IO::FD::syswrite2($fd,undef);
  ok $ret==0, "Zero byte count for undef buffer write";


  # Test syswrite sanity for non fd. perl does a warning for bad filehandles and returns undef
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::syswrite called with something other than a file descriptor/, "Got warning";
  };
	my $ret=IO::FD::syswrite2("asdf","asdf");
  ok !defined($ret), "Zero byte count for undef buffer write";
  ok $!==EBADF;



  # Test syswrite3 sanity for undefined buffer. perl does a warning and returns 0
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::syswrite called with use of uninitialized value/, "Got warning";
  };
	my $ret=IO::FD::syswrite3($fd,undef,3);
  ok $ret==0, "Zero byte count for undef buffer write";


  # Test syswrite sanity for non fd. perl does a warning for bad filehandles and returns undef
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::syswrite called with something other than a file descriptor/, "Got warning";
  };
	my $ret=IO::FD::syswrite3("asdf","asdf",3);
  ok !defined($ret), "Zero byte count for undef buffer write";
  ok $!==EBADF;



  die unless defined IO::FD::syswrite($fd,"x"x100);


  # Reading testing

  # Test sysread sanity for undefined buffer. perl does a warning and returns 0

  eval {
	  my $ret=IO::FD::sysread($fd, "asdf",1);
  };
  #my $tmp=$@;
  ok $@=~ "Modification of a read-only value attempted", "Die on readonly buffer";

  # Test sysread sanity for non fd. perl does a warning for bad filehandles and returns undef
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::sysread called with something other than a file descriptor/, "Got warning";
  };
	my $ret=IO::FD::sysread("asdf",my $buf,3);
  ok !defined($ret), "Undef for bad fd";
  ok $!==EBADF, "Bad fd";



  eval {
          my $ret=IO::FD::sysread3($fd,"",1);
  };
  ok $@ =~ "Modification of a read-only value attempted", "Die on readonly buffer";

  
  # Test sysread sanity for non fd. perl does a warning for bad filehandles and returns undef
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::sysread called with something other than a file descriptor/, "Got warning";
  };
        my $ret=IO::FD::sysread3("asdf","asdf",3);
  ok !defined($ret), "Undef for bad fd";
  ok $!==EBADF;


  eval {
          my $ret=IO::FD::sysread4($fd,undef,1,0);
  };
  ok $@ =~ "Modification of a read-only value attempted", "Die on readonly buffer";

  
  # Test sysread sanity for non fd. perl does a warning for bad filehandles and returns undef
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::sysread called with something other than a file descriptor/, "Got warning";
  };
        my $ret=IO::FD::sysread4("asdf","asdf",3,0);
  ok !defined($ret), "Undef for bad fd";
  ok $!==EBADF, "bad fd";

}
{
  eval {
    my $ret=IO::FD::sysopen "", "sdf",0;
  };
  ok $@=~ "Modification of a read-only value attempted", "Die on readonly sysopen var";

  eval {
    my $ret=IO::FD::sysopen4 "", "sdf",0,0;
  };
  ok $@=~ "Modification of a read-only value attempted", "Die on readonly sysopen var";

  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::close called with something other than a file descriptor/, "Got warning";
  };
        my $ret=IO::FD::close("asdf");
  ok !defined($ret), "Undef for bad fd";
  ok $!==EBADF, "bad fd";
}

done_testing;
