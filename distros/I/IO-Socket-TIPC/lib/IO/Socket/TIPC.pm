package IO::Socket::TIPC;
use IO::Socket::TIPC::Sockaddr ':all';
use strict;
use Carp;
use IO::Socket;
use Scalar::Util qw(looks_like_number);
use AutoLoader;
use Exporter;

our @ISA = qw(Exporter IO::Socket);

our $VERSION = '1.08';

=head1 NAME

IO::Socket::TIPC - TIPC sockets for Perl

=head1 SYNOPSIS

	use IO::Socket::TIPC;
	my $sock = IO::Socket::TIPC->new(
		SocketType => "stream",
		Peer       => "{1000, 100}"
	);
	die "Could not connect to {1000, 100}: $!\n" unless $sock;

More in-depth examples are available in the B<EXAMPLES> section, below.


=head1 DESCRIPTION

TIPC stands for Transparent Inter-Process Communication.  See
http://tipc.sf.net/ for details.

This perl module subclasses IO::Socket, in order to use TIPC sockets
in the customary (and convenient) Perl fashion.

TIPC supports 4 types of socket: I<SOCK_STREAM>, I<SOCK_SEQPACKET>,
I<SOCK_RDM> and I<SOCK_DGRAM>.  These are all available through this
perl API, though the usage varies depending on which kind of socket
you use.

I<SOCK_STREAM> and I<SOCK_SEQPACKET> are connection-based sockets.
These sockets are strictly client/server.  For servers, B<new>() will
call B<bind>() for you, to bind to a I<Local>* name, and you then
B<accept>() connections from clients, each of which get their own
socket (returned from B<accept>).  For clients, B<new>() will call
B<connect>() for you, to connect to the specified I<Peer>* name, and
once that succeeds, you can do I/O on the socket directly.  In this
respect, usage details are very similar to I<TCP> over I<IPv4>.

See the B<EXAMPLES> section, for an example of connection-based socket
use.

I<SOCK_RDM> and I<SOCK_DGRAM> are connectionless sockets.  You cannot
use the normal send/recv/print/getline methods on them, because the
network stack will not know which host on the network to send or
receive from.  Instead, once you have called B<new>() to create the
socket, you use B<sendto> and B<recvfrom> to send and receive
individual packets to/from a specified peer, indicated using an
IO::Socket::TIPC::Sockaddr class object.

Connectionless sockets (I<SOCK_RDM> and I<SOCK_DGRAM>) are often
bind()ed to a particular I<Name> or I<Nameseq> address, in order to
allow them to listen for packets sent to a well-known destination
(the I<Name>).  You can use I<LocalName> or I<LocalNameseq> parameters
to B<new>(), to select a name or name-sequence to bind to.  As above,
these parameters internally become I<Name> and I<Nameseq> arguments to
IO::Socket::TIPC::Sockaddr->B<new>(), and the result is passed to
B<bind>().  This is very similar to typical uses of I<UDP> over
I<IPv4>.

Since connectionless sockets are not linked to a particular peer, you
can use B<sendto> to send a packet to some peer with a given Name in
the network, and B<recvfrom> to receive replies from a peer in the
network who sends a packet to your I<Name> (or I<Nameseq>).  You can
also use I<Nameseq> addressses to send multicast packets to *every*
peer with a given name.  Please see the I<Programmers_Guide.txt>
document (linked in B<REFERENCES>) for more details.

See the B<EXAMPLES> section, for an example of connection-less socket
use.

=cut


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&IO::Socket::TIPC::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { $val = undef; } # undefined constants just return undef.
    {
	no strict 'refs';
	    *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

=head1 CONSTRUCTOR

B<new> returns a TIPC socket object.  This object inherits from
IO::Socket, and thus inherits all the methods of that class.  

This module was modeled specifically after I<IO::Socket::INET>, and
shares some things in common with that class.  Specifically, the
I<Listen> parameter, the I<Peer>* and I<Loca>l* nomenclature, and the
behind-the-scenes calls to B<socket>(), B<bind>(), B<listen>(),
B<connect>(), and so on.

Connection-based sockets (I<SOCK_STREAM> and I<SOCK_SEQPACKET>) come
in "server" and "client" varieties.  To create a server socket,
specify the I<Listen> argument to B<new>().  You can bind a
name to the socket, thus making your server easier to find, by
providing one or more I<Local>* parameters.  To create a client
socket, do B<NOT> provide the I<Listen> argument.  Instead, provide
one or more I<Peer>* parameters, and B<new> will call B<connect>()
for you.

All I<Local>* parameters are passed directly to
IO::Socket::TIPC::Sockaddr->B<new>(), minus the "Local" prefix, and the
resulting sockaddr is passed to B<bind>().  Similarly, all I<Peer>*
parameters are passed directly to IO::Socket::TIPC::Sockaddr->B<new>(),
minus the "Peer" prefix, and the result is passed to B<connect>().  The
keywords I<Local> and I<Peer> themselves become the first string
parameter to IO::Socket::TIPC::Sockaddr->B<new>(); see the
IO::Socket::TIPC::Sockaddr documentation for details.

=head2 ARGUMENTS to new()

=head2 SocketType

This field is B<required>.  It tells the system what type of socket
to use.  The following constants will work, if they were imported:
I<SOCK_STREAM>, I<SOCK_SEQPACKET>, I<SOCK_RDM>, or I<SOCK_DGRAM>.
Otherwise, you can just use the following text strings: "stream",
"seqpacket", "rdm", or "dgram".

=head2 Listen

This field is only valid for connection-based B<SocketType>s.  Its
existence specifies that this is a server socket.  It is common to
also specify some I<Local>* arguments, so B<new>() can B<bind> your
shiny new server socket to a well-known name.

=head2 Importance

This field informs the TIPC network stack  of what priority it should
consider delivering your messages to be.  It corresponds to the 
I<TIPC_IMPORTANCE> option, from B<setsockopt>.  If you provide this
field, ->B<new>() will call B<setsockopt> for you to set the value.

Default is I<TIPC_LOW_IMPORTANCE>.  Valid arguments are any of:

  TIPC_LOW_IMPORTANCE
  TIPC_MEDIUM_IMPORTANCE
  TIPC_HIGH_IMPORTANCE
  TIPC_CRITICAL_IMPORTANCE

See I<Programmers_Guide.txt> (linked in B<REFERENCES>) for details.


=head2 ConnectTimeout

This field specifies the B<connect>() timeout, in milliseconds.  If
you provide this field, ->B<new>() will call B<setsockopt> to set
the I<TIPC_CONN_TIMEOUT> value on your socket.

See I<Programmers_Guide.txt> (linked in B<REFERENCES>) for details.

B<Careful>: I<ConnectTimeout> should not be confused with I<Timeout>,
which is handled internally by IO::Socket and means something else.


=head2 Local*

This field is valid (and recommended) for all connectionless socket
types, and for all servers using connection-type sockets.  The
I<Local>* parameter(s) determine which address your socket will get
B<bind>()ed to.

Any arguments prefixed with "Local" will be passed to
IO::Socket::TIPC::Sockaddr->B<new>(), with the "Local" prefix
removed.  If you specify the word I<Local>, itself, the argument
will be passed as the first string parameter to
IO::Socket::TIPC::Sockaddr->B<new>(); all other I<Local>* arguments
end up in the hash parameter list.  See the documentation for
IO::Socket::TIPC::Sockaddr, for details.  Also, skip to the
B<EXAMPLES> section to see what this stuff looks like.

=head2 Peer*

This field is only valid for B<clients> (as opposed to B<servers>)
using connection-type sockets, and is required for this case.  The
I<Peer>* parameter(s) determine which address your socket will get
B<connect>()ed to.

Any arguments prefixed with "Peer" will be passed to
IO::Socket::TIPC::Sockaddr->B<new>(), with the "Peer" prefix
removed.  If you specify the word I<Peer>, itself, the argument
will be passed as the first string parameter to
IO::Socket::TIPC::Sockaddr->B<new>(); all other I<Peer>* arguments
end up in the hash parameter list.  See the documentation for
IO::Socket::TIPC::Sockaddr, for details.  Also, skip to the
B<EXAMPLES> section to see what this stuff looks like.

=cut

sub new {
	# pass it down to IO::Socket
	my $class = shift;
	return IO::Socket::new($class,@_);
}

sub configure {
	# IO::Socket calls us back via this method call, from IO::Socket->new().
	my($socket, $args) = @_;
	my (%local, %peer, $local, $peer);
	# move Local* args into %local, Peer* args into %peer.
	# keys "Local" and "Peer" themselves go into $local and $peer.
	# These become arguments to IO::Socket::TIPC::Sockaddr->new().
	foreach my $key (sort keys %$args) {
		if($key =~ /^local/i) {
			my $newkey = substr($key,5);
			if(length($newkey)) {
				$local{$newkey} = $$args{$key};
			} else {
				$local = $$args{$key};
			}
			delete($$args{$key});
		}
		if($key =~ /^peer/i) {
			my $newkey = substr($key,4);
			if(length($newkey)) {
				$peer{$newkey} = $$args{$key};
			} else {
				$peer = $$args{$key};
			}
			delete($$args{$key});
		}
	}
	return undef unless fixup_args($args);
	return undef unless enforce_required_args($args);
	my $connectionless = 0;
	my $listener       = 0;
	my $connector      = (scalar keys %peer)  || (defined $peer);
	my $binder         = (scalar keys %local) || (defined $local);
	$listener = 1 if(exists($$args{Listen}) && $$args{Listen});
	unless(looks_like_number($$args{SocketType})) {
		my %socket_types = (
			stream    => SOCK_STREAM,
			seqpacket => SOCK_SEQPACKET,
			rdm       => SOCK_RDM,
			dgram     => SOCK_DGRAM,
		);
		if(exists($socket_types{lc($$args{SocketType})})) {
			$$args{SocketType} = $socket_types{lc($$args{SocketType})};
		} else {
			croak "unknown SocketType $$args{SocketType}!";
		}
		$connectionless = 1 if $$args{SocketType} == SOCK_RDM;
		$connectionless = 1 if $$args{SocketType} == SOCK_DGRAM;
	}
	croak "Connectionless socket types cannot listen(), but you've told me to Listen."
		if($connectionless && $listener);
	croak "Connectionless socket types cannot connect(), but you've given me a Peer address."
		if($connectionless && $connector);
	croak "Listener sockets cannot connect, but you've given me a Peer address."
		if($listener && $connector);
	croak "Connect()ing sockets cannot bind, but you've given me a Local address."
		if($connector && $binder);

	# If we've gotten this far, I figure everything is ok.
	# unless Sockaddr barfs, of course.
	$socket->socket(PF_TIPC(), $$args{SocketType}, 0)
		or croak "Could not create socket: $!";

	# setsockopt/fcntl stuff goes here.
	if(exists $$args{ConnectTimeout}) {
		$socket->setsockopt(SOL_TIPC(), TIPC_CONN_TIMEOUT(), $$args{ConnectTimeout})
			or croak "TIPC_CONN_TIMEOUT: $!";
	}
	if(exists $$args{Importance}) {
		$socket->setsockopt(SOL_TIPC(), TIPC_IMPORTANCE()  , $$args{Importance})
			or croak "TIPC_IMPORTANCE: $!";
	}
	if($binder) {
		my $baddr;
		if(defined($local)) {
			if(ref($local) && ref($local) eq "IO::Socket::TIPC::Sockaddr") {
				$baddr = $local;
			} else {
				$baddr = IO::Socket::TIPC::Sockaddr->new($local, %local);
			}
		} else {
			$baddr = IO::Socket::TIPC::Sockaddr->new(%local);
		}
		$socket->bind($baddr)
			or croak "Could not bind socket: $!";
	}
	if($connector) {
		my $caddr;
		if(defined($peer)) {
			if(ref($peer) && ref($peer) eq "IO::Socket::TIPC::Sockaddr") {
				$caddr = $peer;
			} else {
				$caddr = IO::Socket::TIPC::Sockaddr->new($peer, %peer);
			}
		} else {
			$caddr = IO::Socket::TIPC::Sockaddr->new(%peer);
		}
		$socket->connect($caddr)
			or croak "Could not connect socket: $!";
	}
	if($listener) {
		$socket->listen()
			or croak "Could not listen: $!";
	}
	return $socket;
}

# a "0" denotes an optional value.  a "1" is required.
my %valid_args = (
	Listen     => 0,
	SocketType => 1,
	Importance => 0,
	ConnectTimeout    => 0,
);

sub enforce_required_args {
	my $args = shift;
	foreach my $key (sort keys %$args) {
		if($valid_args{$key}) {
			# argument is required.
			unless(exists($$args{$key})) {
				# argument not provided!
				croak "argument $key is REQUIRED.";
			}
		}
	}
	return 1;
}

sub fixup_args {
	my $args = shift;
	# Validate hash-key arguments to IO::Socket::TIPC->new()
	foreach my $key (sort keys %$args) {
		if(!exists($valid_args{$key})) {
			# This key needs to be fixed up.  Search for it.
			my $lckey = lc($key);
			my $fixed = 0;
			foreach my $goodkey (sort keys %valid_args) {
				if($lckey eq lc($goodkey)) {
					# Found it.  Fix it up.
					$$args{$goodkey} = $$args{$key};
					delete($$args{$key});
					$fixed = 1;
					last;
				}
			}
			croak("unknown argument $key")
				unless $fixed;
		}
	}
	return 1;
}


=head1 METHODS

=head2 sendto(addr, message [, flags])

B<sendto> is used with connectionless sockets, to send a message to a
given address.  The addr parameter should be an
IO::Socket::TIPC::Sockaddr object.

	my $addr = IO::Socket::TIPC::Sockaddr->new("{4242, 100}");
	$sock->sendto($addr, "Hello there!\n");

The third parameter, I<flags>, defaults to 0 when not specified.  The
TIPC I<Programmers_Guide.txt> says: "TIPC supports the I<MSG_DONTWAIT>
flag when sending; all other flags are ignored."

You may have noticed that B<sendto> and the B<send> builtin do more
or less the same thing with the order of arguments changed.  The main
reason to use B<sendto> is because you can pass it a
IO::Socket::TIPC::Sockaddr object directly, where B<send> requires you
to dereference the blessed reference to get at the raw binary "struct
sockaddr_tipc" bits.  So, B<sendto> is just a matter of convenience.

Ironically, this B<sendto> method calls the B<send> builtin, which in
turn calls the C B<sendto> function.

=cut

sub sendto {
	my ($self, $addr, $message, $flags) = @_;
	croak "sendto given an undef message" unless defined $message;
	croak "sendto given a non-address?"
		unless ref($addr) eq "IO::Socket::TIPC::Sockaddr";
	$flags = 0 unless defined $flags;
	return $self->send($message, $flags, $$addr);
}


=head2 recvfrom(buffer [, length [, flags]])

B<recvfrom> is used with connectionless sockets, to receive a message
from a peer.  It returns a IO::Socket::TIPC::Sockaddr object,
containing the address of whoever sent the message.  It will write
the received packet (up to $length bytes) in $buffer.

	my $buffer;
	my $sender = $sock->recvfrom($buffer, 30);
	$sock->sendto($sender, "I got your message.");

The second parameter, I<length>, defaults to I<TIPC_MAX_USER_MSG_SIZE>
when not specified.  The third parameter, I<flags>, defaults to 0 when
not specified.

The TIPC I<Programmers_Guide.txt> says: "TIPC supports the I<MSG_PEEK>
flag when receiving, as well as the I<MSG_WAITALL> flag when receiving
on a I<SOCK_STREAM> socket; all other flags are ignored."

You may have noticed that B<recvfrom> and the B<recv> builtin do
more or less the same thing with the order of arguments changed.
The main reason to use B<recvfrom> is because it will return a
IO::Socket::TIPC::Sockaddr object, where B<recv> just returns a
binary blob containing the C "struct sockaddr_tipc" data, which, by
itself, cannot be inspected or modified.  So, B<recvfrom> is just a
matter of convenience.

Ironically, this B<recvfrom> method calls the B<recv> builtin, which
in turn calls the C B<recvfrom> function.

=cut

sub recvfrom {
	# note: the $buffer argument is written to by recv().
	my ($self, $buffer, $length, $flags) = @_;
	$flags = 0 unless defined $flags;
	$length = TIPC_MAX_USER_MSG_SIZE() unless defined $length;
	croak "how am I supposed to recvfrom() a packet of length 0?"
		unless $length > 0;
	my $rv = $self->recv($_[1], $length, $flags);
	return IO::Socket::TIPC::Sockaddr->new_from_data($rv);
}


=head2 bind(addr)

B<bind> attaches a well-known "name" to an otherwise random (and hard
to find) socket port.  It is possible to bind more than one name to a
socket.  B<bind> is useful for all connectionless sockets, and for 
"server" sockets (the one you get from B<new>(I<Listen> => 1), not the
ones returned from B<accept>).

This method is really just a wrapper around the Perl B<bind> builtin,
which dereferences IO::Socket::TIPC::Sockaddr class instances when
necessary.

=cut

sub bind {
	my ($sock, $addr) = @_;
	$addr = $$addr while ref $addr;
	return $sock->SUPER::bind($addr);
}


=head2 connect(addr)

B<connect> seeks out a server socket (which was B<bind>ed to a 
well-known "name") and connects to it.  B<connect> is only valid for
connection-type sockets which have not already had B<listen> or
B<bind> called on them.  In practice, you should not ever need this
method; B<new> calls it for you when you specify one or more
I<Peer> arguments.

This method is really just a wrapper around the Perl B<connect>
builtin, which dereferences IO::Socket::TIPC::Sockaddr class
instances when necessary.

=cut

sub connect {
	my ($sock, $addr) = @_;
	$addr = $$addr while ref $addr;
	return $sock->SUPER::connect($addr);
}


=head2 getpeername

B<getpeername> returns the sockaddr of the peer you're connected
to.  Compare B<getsockname>.  Use this if you've just B<accept>()ed
a new connection, and you're curious who you're talking to.

	my $client = $server->accept();
	my $caddr = $client->getpeername();
	print("Got connection from ", $caddr->stringify(), "\n");

B<getpeername> doesn't actually return a I<name> sockaddr, it returns
an I<id>.  Thus, B<getpeerid> is an alias for B<getpeername>, to aid
readability.  I<Programmers_Guide.txt> has the following comment: The
use of "name" in getpeername() can be confusing, as the routine does
not actually return the TIPC names or name sequences that have been
bound to the peer socket.

This method is really just a wrapper around the Perl B<getpeername>
builtin, to wrap return values into IO::Socket::TIPC::Sockaddr class
instances for you.


=cut

sub getpeername {
	my ($self) = @_;
	my $rv = CORE::getpeername($self);
	return $rv unless defined $rv;
	return IO::Socket::TIPC::Sockaddr->new_from_data($rv);
}
sub getpeerid { my $self = shift; return $self->getpeername(@_) };

=head2 getsockname

B<getsockname> returns the sockaddr of your own socket, this is the
address your peer sees you coming from.  Compare B<getpeername>.

	my $client = $server->accept();
	my $caddr = $client->getsockname();
	print("The client connected to me as ", $caddr->stringify(), "\n");

B<getsockname> doesn't actually return a I<name> sockaddr, it returns
an I<id>.  Thus, B<getsockid> is an alias for B<getsockname>, to aid
readability.  I<Programmers_Guide.txt> has the following comment: The
use of "name" in getsockname() can be confusing, as the routine does
not actually return the TIPC names or name sequences that have been
bound to the peer socket.

This method is really just a wrapper around the Perl B<getsockname>
builtin, to wrap return values into IO::Socket::TIPC::Sockaddr class
instances for you.


=cut

sub getsockname {
	my ($self) = @_;
	my $rv = CORE::getsockname($self);
	return $rv unless defined $rv;
	return IO::Socket::TIPC::Sockaddr->new_from_data($rv);
}
sub getsockid { my $self = shift; return $self->getsockname(@_) };


=head2 listen

B<listen> tells the operating system that this is a server socket,
and that you will be B<accept>()ing client connections on it.  It is
only valid for connection-type sockets, and only if B<connect> has
not been called on it.  It is much more useful if you have B<bind>ed
the socket to a well-known name; otherwise, most clients will have
difficulty knowing what to B<connect> to.

This module does not actually implement a B<listen> method; when you
call it, you are really just calling the Perl builtin.  See the
perlfunc manpage for more details.

=head2 accept

B<accept> asks the operating system to return a session socket, for
communicating with a client which has just B<connect>ed to you.  It is
only valid for connection-type sockets, which you have previously
called B<listen> on.

This module does not actually implement an B<accept> method; when you
call it, you are really just calling the Perl builtin.  See the
perlfunc manpage for more details.


=head2 getsockopt(level, optname)

Query a socket option.  For TIPC-level stuff, I<level> should be
I<SOL_TIPC>.

The TIPC I<Programmers_Guide.txt> (linked in B<REFERENCES>) says:
	- TIPC does not currently support socket options for level
	  SOL_SOCKET, such as SO_SNDBUF.
	- TIPC does not currently support socket options for level
	  IPPROTO_TCP, such	as TCP_MAXSEG.  Attempting to get the value
	  of these options on a SOCK_STREAM	socket returns the value 0.

See B<setsockopt>(), below, for a list of I<SOL_TIPC> options.

This module does not actually implement a B<getsockopt> method; when
you call it, you are really just calling the Perl builtin.  See the
perlfunc manpage for more details.


=head2 setsockopt(level, optname, optval)

Set a socket option.  For TIPC-level stuff, I<level> should be
I<SOL_TIPC>.

The TIPC I<Programmers_Guide.txt> (linked in B<REFERENCES>) says:
	- TIPC does not currently support socket options for level
	  SOL_SOCKET, such as SO_SNDBUF.
	- TIPC does not currently support socket options for level
	  IPPROTO_TCP, such	as TCP_MAXSEG.  Attempting to get the value
	  of these options on a SOCK_STREAM	socket returns the value 0.

For level I<SOL_TIPC>, the following options are available:

	TIPC_IMPORTANCE
	TIPC_SRC_DROPPABLE
	TIPC_DEST_DROPPABLE
	TIPC_CONN_TIMEOUT

These are documented in detail in I<Programmers_Guide.txt>.  See also,
->B<new>()'s I<Importance> and I<ConnectTimeout> options.

This module does not actually implement a B<setsockopt> method; when
you call it, you are really just calling the Perl builtin.  See the
perlfunc manpage for more details.


=head2 detect()

B<detect> determines whether TIPC is usable on your system.  It will
return a true value if it detects TIPC support has been loaded into
your operating system kernel, and will return 0 otherwise.

=cut

sub detect {
    if($^O eq 'linux') {
        return 1 if `grep -c ^TIPC /proc/net/protocols` == 1;
    }
    elsif($^O eq 'solaris') {
        return 1 if `modinfo -c | grep -w tipc | grep -cv UNLOADED` == 1;
    }
    return 0;
}


=head1 EXAMPLES

Examples of connection-based socket use:

	# SERVER PROCESS
	# create a server listening on Name {4242, 100}.
	$sock1 = IO::Socket::TIPC->new(
		SocketType => "seqpacket",
		Listen => 1,
		Local => "{4242, 100}",
		LocalScope => "zone",
	);
	$client = $sock1->accept();
	# Wait for the client to say something intelligent
	$something_intelligent = $client->getline();


	# CLIENT PROCESS
	# connect to the above server
	$sock2 = IO::Socket::TIPC->new(
		SocketType => "seqpacket",
		Peer => "{4242, 100}",
	);
	# Say something intelligent
	$sock2->print("Dah, he is Olle, you are Sven.\n");
	
Examples of connectionless socket use:

	# NODE 1
	# Create a server listening on Name {4242, 101}.
	$sock1 = IO::Socket::TIPC->new(
		SocketType => "rdm",
		Local => "{4242, 101}",
		LocalScope => "zone",
	);
	$data = "TAG!  You are \"it\".\n";
	# send a hello packet from sock1 to sock2
	$addr2 = IO::Socket::TIPC::Sockaddr->new("{4242, 102}");
	$sock1->sendto($addr2, $data);


	# NODE 2
	# Create another server listening on Name {4242, 102}.
	$sock2 = IO::Socket::TIPC->new(
		SocketType => "rdm",
		Local => "{4242, 102}",
		LocalScope => "zone",
	);
	# receive that first hello packet
	$sender = $sock2->recvfrom($rxdata, 256);
	# Reply
	$sock2->sendto($sender, "Me too.\n");
	
	# send a multicast packet to all sock1s in the world
	$maddr1 = IO::Socket::TIPC::Sockaddr->new("{4242,101,101}");
	$sock2->sendto($maddr2, "My brain hurts!\n");


=head1 EXPORT

None by default.

=head2 Exportable constants and macros

  ":tipc" tag (defines from tipc.h, loosely grouped by function):
  AF_TIPC, PF_TIPC, SOL_TIPC
  TIPC_ADDR_ID, TIPC_ADDR_MCAST, TIPC_ADDR_NAME, TIPC_ADDR_NAMESEQ
  TIPC_ZONE_SCOPE, TIPC_CLUSTER_SCOPE, TIPC_NODE_SCOPE
  TIPC_ERRINFO, TIPC_RETDATA, TIPC_DESTNAME
  TIPC_IMPORTANCE, TIPC_SRC_DROPPABLE, TIPC_DEST_DROPPABLE,
  TIPC_CONN_TIMEOUT
  TIPC_LOW_IMPORTANCE, TIPC_MEDIUM_IMPORTANCE, TIPC_HIGH_IMPORTANCE,
  TIPC_CRITICAL_IMPORTANCE
  TIPC_MAX_USER_MSG_SIZE
  TIPC_OK, TIPC_ERR_NO_NAME, TIPC_ERR_NO_NODE, TIPC_ERR_NO_PORT,
  TIPC_ERR_OVERLOAD, TIPC_CONN_SHUTDOWN  
  TIPC_PUBLISHED, TIPC_WITHDRAWN, TIPC_SUBSCR_TIMEOUT
  TIPC_SUB_NO_BIND_EVTS, TIPC_SUB_NO_UNBIND_EVTS,
  TIPC_SUB_PORTS, TIPC_SUB_SERVICE, TIPC_SUB_SINGLE_EVT
  TIPC_CFG_SRV, TIPC_TOP_SRV, TIPC_RESERVED_TYPES
  TIPC_WAIT_FOREVER
  tipc_addr, tipc_zone, tipc_cluster, tipc_node

(Those last 4 are re-exports from the Sockaddr module.  See the
IO::Socket::TIPC::Sockaddr documentation.)

  ":sock" tag (re-exports from IO::Socket):
  SOCK_STREAM, SOCK_DGRAM, SOCK_SEQPACKET, SOCK_RDM
  MSG_DONTWAIT, MSG_PEEK, MSG_WAITALL, MSG_CTRUNC

To get all of the above constants, say:

  use IO::Socket::TIPC ":all";

To get all of the tipc stuff, say:

  use IO::Socket::TIPC ":tipc";

To get only the socket stuff, say:

  use IO::Socket::TIPC ":sock";

To get only the constants you plan to use, say something like:

  use IO::Socket::TIPC qw(SOCK_RDM TIPC_NODE_SCOPE TIPC_ADDR_NAMESEQ);

Despite supporting all the above constants, please note that some
effort was made so normal users will never actually need any of
them.  For instance, in place of the I<SOCK_>* socktypes, you can
just specify "stream", "dgram", "seqpacket" or "rdm".  In place
of the I<TIPC_>*I<_SCOPE> defines, given to
IO::Socket::TIPC::Sockaddr->B<new>() as the I<Scope> parameter, you
can simply say I<"zone">, I<"cluster"> or I<"node">.

=cut



use XSLoader;
XSLoader::load('IO::Socket::TIPC', $VERSION);

IO::Socket::TIPC->register_domain(PF_TIPC());

my @TIPC_STUFF = ( qw(
	AF_TIPC PF_TIPC SOL_TIPC TIPC_ADDR_ID TIPC_ADDR_MCAST TIPC_ADDR_NAME
	TIPC_ADDR_NAMESEQ TIPC_CFG_SRV TIPC_CLUSTER_SCOPE TIPC_CONN_SHUTDOWN
	TIPC_CONN_TIMEOUT TIPC_CRITICAL_IMPORTANCE TIPC_DESTNAME
	TIPC_DEST_DROPPABLE TIPC_ERRINFO TIPC_ERR_NO_NAME TIPC_ERR_NO_NODE
	TIPC_ERR_NO_PORT TIPC_ERR_OVERLOAD TIPC_HIGH_IMPORTANCE TIPC_IMPORTANCE
	TIPC_LOW_IMPORTANCE TIPC_MAX_USER_MSG_SIZE TIPC_MEDIUM_IMPORTANCE
	TIPC_NODE_SCOPE TIPC_OK TIPC_PUBLISHED TIPC_RESERVED_TYPES TIPC_RETDATA
	TIPC_SRC_DROPPABLE TIPC_SUBSCR_TIMEOUT TIPC_SUB_NO_BIND_EVTS
	TIPC_SUB_NO_UNBIND_EVTS TIPC_SUB_PORTS TIPC_SUB_SERVICE TIPC_SUB_SINGLE_EVT
	TIPC_TOP_SRV TIPC_WAIT_FOREVER TIPC_WITHDRAWN TIPC_ZONE_SCOPE
	tipc_addr tipc_zone tipc_cluster tipc_node
) );
my @SOCK_STUFF = ( qw(
	SOCK_STREAM SOCK_DGRAM SOCK_SEQPACKET SOCK_RDM
	MSG_DONTWAIT MSG_PEEK MSG_WAITALL MSG_CTRUNC
) );

our @EXPORT    = qw();
our @EXPORT_OK = qw();

our %EXPORT_TAGS = ( 
	'all'  => [ @TIPC_STUFF, @SOCK_STUFF ],
	'tipc' => [ @TIPC_STUFF ],
	'sock' => [ @SOCK_STUFF ],
);
Exporter::export_ok_tags('all');

1;
__END__

=head1 BUGS

Probably many.  Please report any bugs you find to the author.  A TODO file
exists, which lists known unimplemented and broken stuff.


=head1 REFERENCES

See also:

IO::Socket, IO::Socket::TIPC::Sockaddr, http://tipc.sf.net/.

The I<Programmers_Guide.txt> is particularly helpful, and is available
off the SourceForge site.  See http://tipc.sf.net/doc/Programmers_Guide.txt,
or http://tipc.sf.net/documentation.html.


=head1 AUTHOR

Mark Glines <mark-tipc@glines.org>


=head1 ACKNOWLEDGEMENTS

Thanks to Ericcson and Wind River, of course, for open-sourcing their (very
useful!) network code, and performing the enormous maintenance task of getting
it into the stock Linux kernel.  Respect.

More specifically, thanks to the TIPC maintainers, for doing all the work
bringing TIPC to linux, and making all of this possible.  And thanks
especially to Allan Stephens for patiently testing all of my pathetic, 
bug-ridden alpha releases. :)

Thanks to Renaud Metrich and Sun Microsystems for bringing TIPC to Solaris,
and testing even more of my pathetic, bug-ridden patches.


=head1 COPYRIGHT AND LICENSE

This module is licensed under a dual BSD/GPL license, the same terms as TIPC
itself.

=cut
