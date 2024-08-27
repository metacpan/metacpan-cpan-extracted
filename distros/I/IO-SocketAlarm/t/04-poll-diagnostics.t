use IO::SocketAlarm;
BEGIN {
   *$_= IO::SocketAlarm::Util->can($_)
      for qw( _poll POLLIN POLLPRI POLLOUT POLLRDHUP POLLERR POLLHUP POLLNVAL );
}
use Test2::V0;
use POSIX 'EPIPE';
use Socket ':all';

sub extract_poll_flags {
   map +($_[0] & $_? ($_):()),
      POLLIN, POLLPRI, POLLOUT, POLLRDHUP, POLLERR, POLLHUP, POLLNVAL
}

socket my $s, AF_INET, SOCK_STREAM, 0
   or die "socket: $!";
sub poll_sock {
   my ($ret, $revents)= _poll(fileno $_[0], $_[1], 0);
   $ret == 1? [ extract_poll_flags($revents) ] : undef
}

is( poll_sock($s, 0), [ POLLHUP ], 'initial state gives POLLHUP' );

listen $s, 10
   or die "listen: $!";
is( poll_sock($s, 0), undef,       'listening socket does not POLLHUP' );

socket my $client, AF_INET, SOCK_STREAM, 0
   or die "socket: $!";
$s->blocking(0);
$client->blocking(0);
connect($client, getsockname($s)) or $!{EINPROGRESS} or die "connect: $!";

accept my $server, $s or $!{EAGAIN} or $!{EWOULDBLOCK} or die "accept: $!";
$server->blocking(0);

my $allbits= POLLIN|POLLPRI|POLLOUT|POLLRDHUP;
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

shutdown($client, 1);
is( poll_sock($server, $allbits), [POLLIN,POLLOUT,POLLRDHUP], 'POLLRDHUP when client SHUT_RDWR' );

close($client);
is( poll_sock($server, $allbits), [POLLIN,POLLOUT,POLLRDHUP], 'POLLRDHUP when client closes connection' );

done_testing;
