use Test::More;

use Socket ":all";
use IO::FD;
use Errno ":POSIX";

die "Could not create socket: $!" unless
	IO::FD::socketpair(my $fd1, my $fd2, AF_UNIX,SOCK_STREAM,0);

#Do shutdown.. should succeed
ok defined IO::FD::shutdown($fd1, SHUT_RD);

#TODO: attempt to read from the socket?

IO::FD::close $fd1;
IO::FD::close $fd2;


{
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::shutdown called with something other than a file descriptor/, "Got warning";
  };
  my $ret=IO::FD::shutdown "", 3;
  ok !defined($ret), "Undef for bad fd";
  ok $! == EBADF,"bad fd";
  
}
{
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::sockatmark called with something other than a file descriptor/, "Got warning";
  };
  my $ret=IO::FD::sockatmark "";
  ok !defined($ret), "Undef for bad fd";
  ok $! == EBADF,"bad fd";
  
}



done_testing;
