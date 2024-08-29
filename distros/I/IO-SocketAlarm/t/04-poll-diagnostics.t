use IO::SocketAlarm;
my $have_rdhup;
BEGIN {
   *$_= IO::SocketAlarm::Util->can($_)
      for qw( _poll POLLIN POLLPRI POLLOUT POLLERR POLLHUP POLLNVAL );
   $have_rdhup= !!IO::SocketAlarm::Util->can('POLLRDHUP');
   *POLLRDHUP= IO::SocketAlarm::Util->can('POLLRDHUP') || sub {};
}
use Test2::V0;
use POSIX 'EPIPE';
use Socket ':all';
use IO::Socket;

sub extract_poll_flags {
   map +($_[0] & $_? ($_):()),
      POLLIN, POLLPRI, POLLOUT, POLLRDHUP, POLLERR, POLLHUP, POLLNVAL
}

socket my $s, AF_INET, SOCK_STREAM, 0
   or die "socket: $!";
setsockopt($s, IPPROTO_TCP, TCP_NODELAY, 1);

sub poll_sock {
   my ($ret, $revents)= _poll(fileno $_[0], $_[1], 0);
   if ($ret < 1) {
      note "poll: ret=$ret".($ret < 0? ", errno = $!" : "");
   }
   $ret == 1? [ extract_poll_flags($revents) ] : undef
}

todo "Linux does, FreeBSD does not" => sub {
   is( poll_sock($s, 0), [ POLLHUP ], 'initial state gives POLLHUP' );
};

listen $s, 10
   or die "listen: $!";
is( poll_sock($s, 0), undef,       'listening socket does not POLLHUP' );

socket my $client, AF_INET, SOCK_STREAM, 0
   or die "socket: $!";
setsockopt($client, IPPROTO_TCP, TCP_NODELAY, 1);

$s->blocking(0);
$client->blocking(0);
connect($client, getsockname($s)) or $!{EINPROGRESS} or die "connect: $!";

accept my $server, $s or $!{EAGAIN} or $!{EWOULDBLOCK} or die "accept: $!";
$server->blocking(0);

my $allbits= POLLIN|POLLPRI|POLLOUT|($have_rdhup? POLLRDHUP : 0);
is( poll_sock($server, $allbits), [POLLOUT], 'new connection can write' );

$client->syswrite("Test");
is( poll_sock($server, $allbits), [POLLIN,POLLOUT], 'server readable' );

shutdown($client, 0);
is( poll_sock($server, $allbits), [POLLIN,POLLOUT],
   'seems wrong, but no hup or error on server when client SHUT_RD' );

#recv($server, my $buf, 256, MSG_DONTWAIT);
#is( $buf, "Test", 'received data' );
#$buf= '';
#recv($server, $buf, 256, MSG_DONTWAIT);
#is( $buf, "", 'EOF' );
#
#shutdown($client, 0);
#is( poll_sock($server, $allbits), [POLLIN,POLLOUT],
#	'seems wrong, but no hup or error on server when client SHUT_RD' );

if ($have_rdhup) {
   shutdown($client, 1);
   is( poll_sock($server, $allbits), [POLLIN,POLLOUT,POLLRDHUP], 'POLLRDHUP when client SHUT_RDWR' );

   close($client);
   is( poll_sock($server, $allbits), [POLLIN,POLLOUT,POLLRDHUP], 'POLLRDHUP when client closes connection' );
}

done_testing;
