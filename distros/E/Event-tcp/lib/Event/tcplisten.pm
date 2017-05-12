use strict;
package Event::tcplisten;
use Carp;
use Symbol;
use Socket;
use Fcntl;
use Event 0.50;
use Event::Watcher qw(R W T);
require Event::io;
use base 'Event::io';
use vars qw($VERSION);
$VERSION = '0.06';

'Event::Watcher'->register;

sub new {
    my $class = shift;
    my %arg = @_;

    my $port = delete $arg{port} || die "port required";
    my $cb = delete $arg{cb} || die "cb required";
    for (qw(fd poll)) { carp "$_ ignored" if delete $arg{$_}; }

    my $proto = getprotobyname('tcp');
    socket(my $sock = gensym, PF_INET, SOCK_STREAM, $proto)
	or die "socket: $!";
    setsockopt($sock, SOL_SOCKET, SO_REUSEADDR, pack('l', 1))
	or die "setsockopt: $!";
    bind($sock, sockaddr_in($port, INADDR_ANY)) or die "bind: $!";
    listen($sock, SOMAXCONN)                    or die "listen: $!";

    $class->SUPER::new(%arg, fd => $sock, poll => R, reentrant => 0,
		       max_cb_tm => 5, cb => sub {
			   my ($e) = @_;
			   my $w=$e->w;
			   my $sock = gensym;
			   accept $sock, $w->fd or return;
			   $cb->($w, $sock);
		       });
}

1;

__END__

callback should be something like this:

    Event->io(e_desc => $w->{e_desc}.' '.fileno($sock),
	      e_fd => $sock, e_prio => $e->{e_prio},
	      e_poll => R, e_reentrant => 0,
	      e_timeout => $timeout, e_max_cb_tm => 30,
	      e_cb => $cb);
