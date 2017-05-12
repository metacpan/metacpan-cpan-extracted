package IO::Socket::Multicast6;

use strict;
use vars qw(@ISA $VERSION);

use IO::Socket::INET6;
use IO::Interface::Simple;
use Socket::Multicast6 qw/ :all /;
use Socket;
use Socket6;
use Carp 'croak';



@ISA = qw(IO::Socket::INET6);
$VERSION = '0.03';


# Regular expressions to match IP addresses
my $IPv4 = '\d+\.\d+\.\d+\.\d+';
my $IPv6 = '[\da-fA-F:]+';


sub new {
	my $class = shift;
	unshift @_,(Proto => 'udp') unless @_;
	$class->SUPER::new(@_);
}


sub configure {
	my($self,$arg) = @_;
	$arg->{Proto} ||= 'udp';
	$arg->{ReuseAddr} ||= 1;
	$self->SUPER::configure($arg);
}


sub mcast_add {
	my $sock = shift;
	my $group = shift || croak 'usage: $sock->mcast_add($mcast_addr [,$interface])';
	my $interface = shift;
	
	if ($sock->sockdomain() == AF_INET) {
		my $if_addr = _get_if_ipv4addr($interface);
		my $ip_mreq = pack_ip_mreq( inet_pton( AF_INET, $group ),
									inet_pton( AF_INET, $if_addr ) );
		
		setsockopt($sock, IPPROTO_IP, IP_ADD_MEMBERSHIP, $ip_mreq )
		or croak "Could not set IP_ADD_MEMBERSHIP socket option: $!";
	} elsif ($sock->sockdomain() == AF_INET6) {
		my $if_index = _get_if_index($interface);
		my $ipv6_mreq = pack_ipv6_mreq( inet_pton( AF_INET6, $group ),
										$if_index );
		
		setsockopt($sock, IPPROTO_IPV6, IPV6_JOIN_GROUP, $ipv6_mreq )
		or croak "Could not set IPV6_JOIN_GROUP socket option: $!";
	} else {
		croak("mcast_add failed, unsupported socket family." );
	}
	
	# Success
	return 1;
}

sub mcast_add_source {
	my $sock = shift;
	my $group = shift || croak 'usage: $sock->mcast_add_source($mcast_addr, $source_addr [,$interface])';
	my $source = shift || croak 'usage: $sock->mcast_add_source($mcast_addr, $source_addr [,$interface])';
	my $interface = shift;

	if ($sock->sockdomain() == AF_INET) {
		my $if_addr = _get_if_ipv4addr($interface);
		my $ip_mreq = pack_ip_mreq_source(
						inet_pton( AF_INET, $group ),
						inet_pton( AF_INET, $source ),       
						inet_pton( AF_INET, $if_addr ) );
		
		setsockopt($sock, IPPROTO_IP, IP_ADD_SOURCE_MEMBERSHIP, $ip_mreq )
		or croak "Could not set IP_ADD_SOURCE_MEMBERSHIP socket option: $!";
	} elsif ($sock->sockdomain() == AF_INET6) {
		croak("mcast_add_source failed, IPv6 is currently unsupported." );
	} else {
		croak("mcast_add_source failed, unsupported socket family." );
	}
	
	# Success
	return 1;
}


sub mcast_drop {
	my $sock = shift;
	my $group = shift || croak 'usage: $sock->mcast_drop($mcast_addr [,$interface])';
	my $interface = shift;
	
	if ($sock->sockdomain() == AF_INET) {
		my $if_addr = _get_if_ipv4addr($interface);
		my $ip_mreq = pack_ip_mreq( inet_pton( AF_INET, $group ),
									inet_pton( AF_INET, $if_addr ) );
		
		setsockopt($sock, IPPROTO_IP, IP_DROP_MEMBERSHIP, $ip_mreq )
		or croak "Could not set IP_ADD_MEMBERSHIP socket option: $!";
	} elsif ($sock->sockdomain() == AF_INET6) {
		my $if_index = _get_if_index($interface);
		my $ipv6_mreq = pack_ipv6_mreq( inet_pton( AF_INET6, $group ),
										$if_index );
		
		setsockopt($sock, IPPROTO_IPV6, IPV6_LEAVE_GROUP, $ipv6_mreq )
		or croak "Could not set IPV6_LEAVE_GROUP socket option: $!";
	} else {
		croak("mcast_add failed, unsupported socket family." );
	}
	
	# Success
	return 1;
}


sub mcast_ttl {
	my $sock = shift;
	
	my $prev = undef;
	if ($sock->sockdomain() == AF_INET) {
		my $packed = getsockopt($sock, IPPROTO_IP, IP_MULTICAST_TTL)
		or croak "Could not get IP_MULTICAST_TTL socket option: $!";
		$prev=unpack("I", $packed);
		if (my $ttl = shift) {
			setsockopt($sock, IPPROTO_IP, IP_MULTICAST_TTL, pack("I", $ttl ) )
			or croak "Could not set IP_MULTICAST_TTL socket option: $!";
		}
	} elsif ($sock->sockdomain() == AF_INET6) {
		my $packed = getsockopt($sock, IPPROTO_IPV6, IPV6_MULTICAST_HOPS)
		or croak "Could not get IPV6_MULTICAST_HOPS socket option: $!";
		$prev=unpack("I", $packed);
		if (my $ttl = shift) {
			setsockopt($sock, IPPROTO_IPV6, IPV6_MULTICAST_HOPS, pack("I", $ttl ) )
			or croak "Could not set IPV6_MULTICAST_HOPS socket option: $!";
		}
	} else {
		croak("mcast_ttl failed, unsupported socket family." );
	}

	return $prev;
}


sub mcast_loopback {
	my $sock = shift;
	
	my $prev = undef;
	if ($sock->sockdomain() == AF_INET) {
		my $packed = getsockopt($sock, IPPROTO_IP, IP_MULTICAST_LOOP)
		or croak "Could not get IP_MULTICAST_LOOP socket option: $!";
		$prev=unpack("I", $packed);
		if (my $loopback = shift) {
			setsockopt($sock, IPPROTO_IP, IP_MULTICAST_LOOP, pack("I", $loopback ) )
			or croak "Could not set IP_MULTICAST_LOOP socket option: $!";
		}
	} elsif ($sock->sockdomain() == AF_INET6) {
		my $packed = getsockopt($sock, IPPROTO_IPV6, IPV6_MULTICAST_LOOP)
		or croak "Could not get IPV6_MULTICAST_LOOP socket option: $!";
		$prev=unpack("I", $packed);

		if (my $loopback = shift) {
			setsockopt($sock, IPPROTO_IPV6, IPV6_MULTICAST_LOOP, pack("I", $loopback ) )
			or croak "Could not set IPV6_MULTICAST_LOOP socket option: $!";
		}
	} else {
		croak("mcast_loopback failed, unsupported socket family." );
	}

	return $prev;
}


sub mcast_if {
	my $sock = shift;
	
	my $prev = undef;
	if ($sock->sockdomain() == AF_INET) {
		my $packed = getsockopt($sock, IPPROTO_IP, IP_MULTICAST_IF)
		or croak "Could not get IP_MULTICAST_IF socket option: $!";
		$prev=$sock->addr_to_interface( inet_ntop( AF_INET, $packed ) );

		if (my $interface = shift) {
			my $if_addr = _get_if_ipv4addr($interface);
			setsockopt($sock, IPPROTO_IP, IP_MULTICAST_IF, inet_pton( AF_INET, $if_addr ) )
			or croak "Could not set IP_MULTICAST_IF socket option: $!";
		}
	} elsif ($sock->sockdomain() == AF_INET6) {
		my $packed = getsockopt($sock, IPPROTO_IPV6, IPV6_MULTICAST_IF)
		or croak "Could not get IPV6_MULTICAST_IF socket option: $!";
		$prev = unpack("I", $packed);
		if ($prev==0) { $prev='any'; }
		else { $prev = $sock->if_indextoname($prev); }

		if (my $interface = shift) {
			my $if_index = _get_if_index($interface);
			setsockopt($sock, IPPROTO_IPV6, IPV6_MULTICAST_IF, pack("I", $if_index ) )
			or croak "Could not set IPV6_MULTICAST_IF socket option: $!";
		}
	} else {
		croak("mcast_if failed, unsupported socket family." );
	}

	return $prev;
}


sub mcast_dest {
	my $sock = shift;
	my ($addr, $port) = @_;
	
	my $prev = ${*$sock}{'io_socket_mcast_dest'};
	if (defined $addr) {
		if ($sock->sockdomain() == AF_INET) {
			if (!defined $port and $addr =~ /^($IPv4):(\d+)$/) {
				$addr = $1; $port = $2;
			}
			
			$addr = pack_sockaddr_in($port,inet_pton(AF_INET, $addr)) if (defined $port);
			croak "Invalid destination address" if (!defined $addr or length($addr)==0);
			croak "Destination isn't an IPv4 address" unless (sockaddr_family($addr)==AF_INET);
			
		} elsif ($sock->sockdomain() == AF_INET6) {
			if (!defined $port and $addr =~ /^\[($IPv6)\]:(\d+)$/) {
				$addr = $1; $port = $2;
			}
			
			$addr = pack_sockaddr_in6($port,inet_pton(AF_INET6, $addr)) if (defined $port);
			croak "Invalid destination address" if (!defined $addr or length($addr)==0);
			croak "Destination isn't an IPv6 address" unless (sockaddr_family($addr)==AF_INET6);
			
		} else {
			croak("mcast_dest failed, unsupported socket family." );
		}
		
		${*$sock}{'io_socket_mcast_dest'} = $addr;
	}

	return $prev;
}



sub mcast_send {
	my $sock = shift;
	my $data = shift || croak 'usage: $sock->mcast_send($data [,$address[,$port]])';
	$sock->mcast_dest(@_) if @_;
	my $dest = $sock->mcast_dest || croak "no destination specified with mcast_send() or mcast_dest()";
	
	return send($sock,$data,0,$dest);
}


## Returns the IPv4 address of an interface
#
sub _get_if_ipv4addr {
	my ($interface) = @_;
	
	return '0.0.0.0' unless (defined $interface);
	return '0.0.0.0' if ($interface eq 'any');
	return $interface if ($interface =~ /^$IPv4$/);
	
	my $if = new IO::Interface::Simple( $interface );
	croak "Unknown interface $interface" unless (defined $if);
	croak "Interface '$interface' is not multicast capable" unless ($if->is_multicast());
	my $address = $if->address();
	croak "Interface '$interface' does not have an IPv4 address" unless (defined $address);
	return $address;
}


## Returns the index of an interface
#
sub _get_if_index {
	my ($interface) = @_;
	
	return 0 unless defined $interface;
	return $interface if ($interface =~ /^\d+$/);
	return 0 if ($interface =~ /^any$/i);

	my $if = new IO::Interface::Simple( $interface );
	croak "Unknown interface $interface" unless (defined $if);
	croak "Interface '$interface' is not multicast capable" unless ($if->is_multicast());
	my $index = $if->index();
	croak "Can't get index of interface '$interface'." unless (defined $index);
	return $index;
}


1;
__END__

=head1 NAME

IO::Socket::Multicast6 - Send and receive IPv4 and IPv6 multicast messages

=head1 SYNOPSIS

  use IO::Socket::Multicast6;

  # create a new IPv6 UDP socket ready to read datagrams on port 1100
  my $s = IO::Socket::Multicast6->new(
  				Domain=>AF_INET6,
  				LocalPort=>1100);

  # Add an IPv6 multicast group
  $s->mcast_add('FF15::0561');

  # now receive some multicast data
  $s->recv($data,1024);

  # Drop a multicast group
  $s->mcast_drop('FF15::0561');


  # create a new IPv4 UDP socket ready to send datagrams to port 1100
  my $s = IO::Socket::Multicast6->new(
  				Domain=>AF_INET,
  				PeerDest=>'225.0.0.1',
  				PeerPort=>1100);

  # Set outgoing interface to eth0
  $s->mcast_if('eth0');

  # Set time to live on outgoing multicast packets
  $s->mcast_ttl(10);

  # Turn off loopbacking
  $s->mcast_loopback(0);

  # Multicast a message to group
  $s->send( 'hello world!' );



=head1 DESCRIPTION

The IO::Socket::Multicast6 module subclasses IO::Socket::INET6 to enable
you to manipulate multicast groups.  With this module you will be able to
receive incoming multicast transmissions and generate your own
outgoing multicast packets.

This module uses the same API as IO::Socket::Multicast, but with added 
support for IPv6 (IPv4 is still supported). Unlike IO::Socket::Multicast,
this is a pure-perl module.


=head2 DEPENDENCIES

This module depends on a number of other modules:

  Socket6 version 0.19 or higher.
  IO::Socket::INET6 version 2.51 or higher.
  IO::Interface version 1.01 or higher.
  Socket::Multicast6 0.01 or higher.

Your operating system must have IPv6 and Multicast support.


=head2 INTRODUCTION

Multicasting is designed for streaming multimedia applications and for
conferencing systems in which one transmitting machines needs to
distribute data to a large number of clients.

IPv4 addresses in the range 224.0.0.0 and 239.255.255.255 are reserved
for multicasting.  IPv6 multicast addresses start with the prefix FF.
These addresses do not correspond to individual
machines, but to multicast groups.  Messages sent to these addresses
will be delivered to a potentially large number of machines that have
registered their interest in receiving transmissions on these groups.
They work like TV channels.  A program tunes in to a multicast group
to receive transmissions to it, and tunes out when it no longer
wishes to receive the transmissions.

To receive transmissions B<from> a multicast group, you will use
IO::Socket::INET->new() to create a UDP socket and bind it to a local
network port.  You will then subscribe one or more multicast groups
using the mcast_add() method.  Subsequent calls to the standard recv()
method will now receive messages incoming messages transmitted to the
subscribed groups using the selected port number.

To send transmissions B<to> a multicast group, you can use the
standard send() method to send messages to the multicast group and
port of your choice. 

To set the number of hops (routers) that outgoing multicast messages
will cross, call mcast_ttl().  To activate or deactivate the looping
back of multicast messages (in which a copy of the transmitted
messages is received by the local machine), call mcast_loopback().

=head2 CONSTRUCTORS

=over 4

=item $socket = IO::Socket::Multicast6->new([LocalPort=>$port,...])

The new() method is the constructor for the IO::Socket::Multicast6
class.  It takes the same arguments as IO::Socket::INET, except that
the B<Proto> argument, rather than defaulting to "tcp", will default
to "udp", which is more appropriate for multicasting.

To create a UDP socket suitable for sending outgoing multicast
messages, call new() without no arguments (or with
C<Proto=E<gt>'udp'>).  To create a UDP socket that can also receive
incoming multicast transmissions on a specific port, call new() with
the B<LocalPort> argument.

If you plan to run the client and server on the same machine, you may
wish to set the IO::Socket B<ReuseAddr> argument to a true value.
This allows multiple multicast sockets to bind to the same address.

=back

=head2 METHODS

=over 4

=item $success = $socket->mcast_add($multicast_address [,$interface])

The mcast_add() method will add the provided multicast address to the
list of subscribed multicast groups.  The address may be provided
either as a dotted-quad decimal, or as a packed IP address (such as
produced by the inet_aton() function).  On success, the method will
return a true value.

The optional $interface argument can be used to specify on which
network interface to listen for incoming multicast messages.  If the
IO::Interface module is installed, you may use the device name for the
interface (e.g. "tu0").  Otherwise, you must use the IP address of the
desired network interface.  Either dotted quad form or packed IP
address is acceptable.  If no interface is specified, then the
multicast group is joined on INADDR_ANY, meaning that multicast
transmissions received on B<any> of the host's network interfaces will
be forwarded to the socket.

Note that mcast_add() operates on the underlying interface(s) and not
on the socket. If you have multiple sockets listening on a port, and
you mcast_add() a group to one of those sockets, subsequently B<all>
the sockets will receive mcast messages on this group. To filter
messages that can be received by a socket so that only those sent to a
particular multicast address are received, pass the B<LocalAddr>
option to the socket at the time you create it:

  my $socket = IO::Socket::Multicast6->new(LocalPort=>2000,
                                          LocalAddr=>226.1.1.2',
                                          ReuseAddr=>1);
  $socket->mcast_add('226.1.1.2');

By combining this technique with IO::Select, you can write
applications that listen to multiple multicast groups and distinguish
which group a message was addressed to by identifying which socket it
was received on.


=item $success = $socket->mcast_add_source($multicast_add, $source_addr [,$interface])

Same as mcast_add() but for Source Specific Multicast (SSM).


=item $success = $socket->mcast_drop($multicast_address)

This reverses the action of mcast_add(), removing the indicated
multicast address from the list of subscribed groups.

=item $loopback = $socket->mcast_loopback

=item $previous = $socket->mcast_loopback($new)

The mcast_loopback() method controls whether the socket will receive
its own multicast transmissions (default yes).  Called without
arguments, the method returns the current state of the loopback
flag. Called with a boolean argument, the method will set the loopback
flag, and return its previous value.

=item $ttl = $socket->mcast_ttl

=item $previous = $socket->mcast_ttl($new)

The mcast_ttl() method examines or sets the time to live (TTL) for
outgoing multicast messages.  The TTL controls the numbers of routers
the packet can cross before being expired.  The default TTL is 1,
meaning that the message is confined to the local area network.
Values between 0 and 255 are valid.

Called without arguments, this method returns the socket's current
TTL.  Called with a value, this method sets the TTL and returns its
previous value.

=item $interface = $socket->mcast_if

=item $previous = $socket->mcast_if($new)

By default, the OS will pick the network interface to use for outgoing
multicasts automatically.  You can control this process by using the
mcast_if() method to set the outgoing network interface explicitly.
Called without arguments, returns the current interface.  Called with
the name of an interface, sets the outgoing interface and returns its
previous value.

You can use the device name for the interface (e.g. "tu0") if the
IO::Interface module is present.  Otherwise, you must use the
interface's dotted IP address.

B<NOTE>: To set the interface used for B<incoming> multicasts, use the
mcast_add() method.


=item $dest = $socket->mcast_dest

=item $previous = $socket->mcast_dest($address [, $port])

The mcast_dest() method is a convenience function that allows you to
set the default destination group for outgoing multicasts.  Called
without arguments, returns the current destination as a packed binary
sockaddr_in/sockaddr_in6 data structure.  Called with a new destination 
address, the method sets the default destination and returns the previous 
one, if any.

Destination addresses may be provided as packed sockaddr_in/sockaddr_in6
structures, or address and port as strings.

For IPv4 the address can be supplied in the form "XX.XX.XX.XX:YY" where 
the first part is the IPv4 address, and the second the port number.

For IPv6 the address can be supplied in the form 
"[FFXX:XXXX::XXXX]:YY" where the first part is the IPv6 address,
and the second the port number.

Alternatively the port can be supplied as an additional parameter, 
separate to the address.


=item $bytes = $socket->mcast_send($data [,$address [,$port]])

mcast_send() is a convenience function that simplifies the sending of
multicast messages.  C<$data> is the message contents, and C<$dest> is
an optional destination group.  You can use either the dotted IP form
of the destination address and its port number, or a packed
sockaddr_in/sockaddr_in6 structure.  If the destination is not supplied, 
it will default to the most recent value set in mcast_dest() or a previous
call to mcast_send().

The method returns the number of bytes successfully queued for
delivery.

As a side-effect, the method will call mcast_dest() to remember the
destination address.

Example:

  $socket->mcast_send('Hi there group members!','225.0.1.1:1900') || die;
  $socket->mcast_send("How's the weather?") || die;

Note that you may still call IO::Socket::INET6->new() with a
B<PeerAddr>, and IO::Socket::INET6 will perform a connect(), creating a
default destination for calls to send().

=back


=head1 EXAMPLE

The following is an example of a multicast server.  Every 10 seconds
it transmits the current time and the list of logged-in users to the
local network using multicast group FF15::0561, port 2000 (these are
chosen arbitrarily, the FF15:: is a Transient, Site Local prefix).

 #!/usr/bin/perl
 # server (transmitter)
 use strict;
 use IO::Socket::Multicast6;

 use constant GROUP => 'FF15::0561';
 use constant PORT  => '2000';
 
 my $sock = IO::Socket::Multicast6->new(
                    Proto=>'udp',
                    Domain=>AF_INET6,
                    PeerAddr=>GROUP,
                    PeerPort=>PORT);

 while (1) {
    my $message = localtime();
    $sock->send($message) || die "Couldn't send: $!";
 } continue {
    sleep 4;
 }


This is the corresponding client.  It listens for transmissions on
group FF15::0561, port 2000, and echoes the messages to standard
output.

 #!/usr/bin/perl
 # client (receiver)

 use strict;
 use IO::Socket::Multicast6;

 use constant GROUP => 'FF15::0561';
 use constant PORT  => '2000';

 my $sock = IO::Socket::Multicast6->new(
                    Proto=>'udp',
                    Domain=>AF_INET6,
                    LocalAddr=>GROUP,
                    LocalPort=>PORT);
                    
 $sock->mcast_add(GROUP) || die "Couldn't set group: $!\n";

 while (1) {
    my $data;
    next unless $sock->recv($data,1024);
    print "$data\n";
 }


=head2 BUGS

The mcast_if(), mcast_ttl() and mcast_loopback() methods will cause a
crash on versions of Linux earlier than 2.2.0 because of a kernel bug
in the implementation of the multicast socket options.


=head1 SEE ALSO

L<http://www.ietf.org/rfc/rfc2553.txt>

perl(1), IO::Socket(3), Socket::Multicast6(3), IO::Socket::INET6(3).

=head1 AUTHOR

Based on L<IO::Socket::Multicast> by Lincoln Stein, lstein@cshl.org.

IO::Socket::Multicast6 by Nicholas J Humfrey, E<lt>njh@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 Nicholas J Humfrey
Copyright (C) 2000-2005 Lincoln Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
