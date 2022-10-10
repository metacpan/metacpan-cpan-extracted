use Test::More tests=>2;

use IO::FD;
use Fcntl;

use Socket ":all";




#Server
my $sock_file="test.sock";
unlink($sock_file);

my $addr=pack_sockaddr_un($sock_file);
ok defined(IO::FD::socket my $listener_fd,AF_UNIX, SOCK_STREAM, 0), "Socket creation";
ok defined(IO::FD::bind($listener_fd, $addr));
my $flags=IO::FD::fcntl $listener_fd, F_GETFL, 0;

##say STDERR "Flags on listener: $flags";
#say STDERR "REad write enabled" if O_RDWR & $flags;
#say STDERR "REad only enabled" if O_RDONLY & $flags;
IO::FD::fcntl $listener_fd, F_SETFL, $flags|O_NONBLOCK;
$flags=IO::FD::fcntl $listener_fd, F_GETFL, 0;
#say STDERR "Flags on listener: $flags";
#say STDERR "NONBLOCKING" if $flags& O_NONBLOCK;


my $ret=IO::FD::getsockopt($listener_fd, SOL_SOCKET, SO_TYPE);
#say STDERR "getsockopt status: $!" unless $ret;
#say STDERR "Socket type ". unpack "i", $ret;

$ret=IO::FD::getsockopt($listener_fd, SOL_SOCKET, SO_SNDBUF);
#say STDERR "getsockopt status: $!" unless $ret;
#say STDERR "send buffer original size". unpack "i", $ret;


$ret=IO::FD::setsockopt($listener_fd, SOL_SOCKET, SO_SNDBUF, 512);#pack "i", 512);
#say STDERR "setsockopt status: $!" unless $ret;


$ret=IO::FD::getsockopt($listener_fd, SOL_SOCKET, SO_SNDBUF);
#say STDERR "getsockopt status: $!" unless $ret;
#say STDERR "send buffer new size". unpack "i", $ret;


