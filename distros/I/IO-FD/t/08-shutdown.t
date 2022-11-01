use Test::More;

use Socket ":all";
use IO::FD;

die "Could not create socket: $!" unless
	IO::FD::socketpair(my $fd1, my $fd2, AF_UNIX,SOCK_STREAM,0);

#Do shutdown.. should succeed
ok defined IO::FD::shutdown($fd1, SHUT_RD);

#TODO: attempt to read from the socket?

IO::FD::close $fd1;
IO::FD::close $fd2;
done_testing;
