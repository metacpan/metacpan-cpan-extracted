
package IO::Socket::INET::Daemon;

use strict;
use warnings;

our $VERSION = '0.04';

use Carp;

use IO::Socket::INET;
use IO::Select;


sub new {
	my ($class, %rc) = @_;

	croak "Called with no/invalid port.\n" if(!$rc{port} or $rc{port} =~ /\D/);

	return bless {
		port => $rc{port},
		host => $rc{host} || 'localhost',
		callback => $rc{callback} || {},
		timeout => $rc{timeout},
	}, $class;
}


sub callback {
	my ($self, %callback) = @_;

	@{$self->{callback}}{keys %callback} = values %callback;
}


sub run {
	my ($self) = @_;

	# Create server socket.
	my $host = $self->{sck} = new IO::Socket::INET(
		LocalHost => $self->{host},
		LocalPort => $self->{port},
		Proto => 'tcp',
		ReuseAddr => !0,
		Listen => 32,
	) or return;

	$self->{stop} = 0;
	my $select = $self->{select} = new IO::Select($host);

	# The main loop.
	until($self->{stop}) {
		$self->call('tick', undef);

		# Get readable sockets.
		for my $io ($select->can_read($self->{timeout})) {

			# If the server socket is readable, get the pending incoming
			# connection, call the callback and add the peer to our list.
			if($io == $host) {
				my $peer = $io->accept;

				if($self->call('add', $peer)) {
					$select->add($peer);
				}
				else {
					$self->remove($peer);
				}
			}

			# If it's a peer, call the data callback. Remove peer if the
			# callback returns something false or if the connection is dead.
			elsif($io->connected) {
				if(!$self->call('data', $io)) {
					$self->call('remove', $io);
					$self->remove($io);
				}
			}
			else {
				$self->call('remove', $io);
				$self->remove($io);
			}
		}
	}
}

# Call a callback function. For internal use only. Takes the name of the
# callback (add, remove or data) and the socket handle as arguments. Returns
# true if there was no such callback, it returns non-zero by default, otherwise
# the return value of the callback is returned.
sub call {
	my ($self, $callback, $io) = @_;

	my $func = $self->{callback}->{$callback};

	return $func ? &{$func}($io, $self) : !0;
}

# This closes a connection to a peer and removes it from our socket list.
sub remove {
	my ($self, $io) = @_;

	if($io and $io != $self->{sck}) {
		my $select = $self->{select};

		$select->remove($io);

		$io->shutdown(SHUT_RDWR);
		$io->close;
	}
}

# This simply sets a variable to a true value, so the main loop will stop after
# the next cycle.
sub stop {
	my ($self) = @_;
	$self->{stop} = !0;
}

# This closes all connections and the server socket. Can be called to clean up
# manually, but is also called automatically from DESTROY.
sub destroy {
	my ($self) = @_;

	$self->{stop} = !0;

	my $select = $self->{select};

	if($select) {
		$self->remove($_) for($select->handles);
		delete $self->{select};
	}

	my $host = delete $self->{sck};
	if($host) {
		$host->shutdown(SHUT_RDWR);
		$host->close;
	}
}

sub DESTROY {
	my ($self) = @_;
	$self->destroy;
}

!0;


__END__

=head1 NAME

IO::Socket::INET::Daemon - very simple straightforward  TCP server

=head1 SYNOPSIS

	use IO::Socket::INET::Daemon;

	my $host = new IO::Socket::INET::Daemon(
		port => 5000,
		timeout => 20,
		callback => {
			add => \&add,
			remove => \&remove,
			data => \&data,
		},
	);

	$host->run;

	sub add {
		my $io = shift;

		$io->print("Welcome, ", $io->peerhost, ".\n");

		return !0;
	}

	sub remove {
		my $io = shift;

		warn $io->peerhost, " left.\n";
	}

	sub data {
		my ($io, $host) = @_;

		my $line = $io->getline;

		$line =~ s/\r?\n//;

		if($line eq 'quit') {
			$io->print("Bye.\n");
			return 0;
		}
		elsif($line eq 'stop') {
			$host->stop;
		}
		else {
			$io->print("You wrote: $line\n");
			return !0;
		}
	}

=head1 DESCRIPTION

This modules aims to provide a simple TCP server. It will listen on a port you
specify, accept incoming connections and remove them again when they're dead.
It provides three simple callbacks at the moment, but I plan to add a few more.

=head1 METHODS

=over 4

=item B<new>(...)

This is the constructor. It takes all the information the server needs as
parameter. Currently, the following options are supported.

=over 4

=item B<port>

The port to listen on.

=item B<host>

The host to bind to (hostname or IP).

=item B<timeout>

The time to wait for actions in seconds. This is simply passed to
L<IO::Select>.

=item B<callback>

A hash with function references assigned to callback names.  Currently, four
callbacks are supported. "add" is called when a new connection was accepted. If
it returns a false value, the connection is kicked again right away. "remove"
is called when a connection got lost. "data" is called when there's pending
data on a connection. If the callback function returns false, the connection is
removed afterwards. "tick" is called at the beginning of every cycle, that
means at least every B<timeout> seconds, or earlier if the B<select> returned
early because of incoming traffic. All callbacks except "tick" are called with
the peer socket and the daemon object itself as argument (L<IO::Socket::INET>).
Tick get's B<undef> instead of the peer socket.

=back

=item B<callback>(add => \&add, remove => \&remove, data => \&data)

This method overwrites callbacks set up with the constructor.

=item B<run>(no parameters at all)

Enter the main loop. Won't ever return.

=item B<stop>(no parameters here)

This can be called from a callback to stop the server. This simply sets a
variable, so after the next cycle the server breaks out of the main loop. At
the moment, if you B<run> the server again after stopping it, it will
completely start over again, so all connections etc. are lost. This might
probably change in future.

=item B<remove>(peer)

This takes a client connection (L<IO::Socket::INET>) as argument, closes the
connection and removes it from the internal connection list. You can use this
in your callbacks to explicitly kill connections. If you return a false value
from the "data" or "add" callback, this is called automatically.

=item B<destroy>(nothing)

This method closes all client connections and the server socket itself. It is
usually called by the DESTROY descructor, but you probably want to explicitly
call this for sometime.

=back

=head1 BUGS

This module was hacked together within a few minutes, so there are probably
lots of bugs. On the other hand, it's very few code, so there can't be that
much bugs in it. Just try it out and tell me if it's broken.

=head1 TODO

=over 4

=item * Add tests to the package.

=back

=head1 COPYRIGHT

Copyright (C) 2008 by Jonas Kramer <jkramer@cpan.org>. Published under the
terms of the Artistic License 2.0.

=cut

