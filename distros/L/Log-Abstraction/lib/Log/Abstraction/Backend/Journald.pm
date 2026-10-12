package Log::Abstraction::Backend::Journald;

# The journald backend: send messages to the systemd journal
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

# Automatically throw exceptions on failed built-ins (socket, close ...)
use autodie qw(:default);

use Carp ();
use POSIX ();
use Readonly ();

# _send is private to this package (see Log::Abstraction)
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private 0.06;

our $VERSION = '0.40';

# Default path to the journald native-protocol socket on systemd systems
Readonly::Scalar my $DEFAULT_SOCKET => '/run/systemd/journal/socket';

# Largest journald datagram sent; the default socket send buffer is ~212KB
# on most Linux systems and bigger datagrams fail, so longer messages are
# truncated to fit.  Some systems have smaller buffers, so on EMSGSIZE the
# limit is halved and the send retried, down to $MIN_PAYLOAD
Readonly::Scalar my $MAX_PAYLOAD => 200_000;
Readonly::Scalar my $MIN_PAYLOAD => 4_096;

# Longest journald field name; journald ignores fields with longer names
Readonly::Scalar my $MAX_FIELD_NAME => 64;

# Marker appended to a message truncated to fit in a datagram
Readonly::Scalar my $TRUNCATED_MARKER => ' [truncated]';

=head1 NAME

Log::Abstraction::Backend::Journald - send messages to the systemd journal

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for the C<journald> key of a C<logger> hash.  Each message is one
datagram in the journald native protocol
(L<https://systemd.io/JOURNAL_NATIVE_PROTOCOL/>), with the fields
C<MESSAGE> (with a C<format>, the formatted line), C<PRIORITY>,
C<SYSLOG_IDENTIFIER>, the hash's other keys upper-cased, and the structured
fields.  A message too big for one datagram is truncated.  A failed send
carps, once until a send succeeds again.  The socket is opened for the
first message and reused for the next ones, until a send fails.

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 new

  my $backend = Log::Abstraction::Backend::Journald->new(
      journald => \%journald, level => $level, format => $format,
  );

=cut

sub new {
	my ($class, %args) = @_;

	# The config hash's other keys are extra journal fields (their names
	# have been checked by Log::Abstraction->new())
	my $config = $args{'journald'};
	my %extra = map { uc($_) => $config->{$_} }
		grep { lc($_) !~ /^(?:socket|identifier|level|format)$/ } keys %{$config};

	return $class->SUPER::new(
		%args,
		socket     => $config->{'socket'} || $DEFAULT_SOCKET,
		identifier => $config->{'identifier'},
		extra      => \%extra,
	);
}

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	# The syslog identifier: the configured one, the script name, or $0
	my $ident = $self->{'identifier'} || $logger->{'script_name'} || do {
		require File::Basename;
		File::Basename::basename($0);
	};

	# Mandatory fields (PRIORITY is 0=emerg ... 7=debug), then the extra
	# fields from the config hash
	my %entry = (
		MESSAGE           => $self->text($event, $event->{'message'}),
		PRIORITY          => $event->{'priority'},
		SYSLOG_IDENTIFIER => $ident,
		%{$self->{'extra'}},
	);

	# Then the structured fields.  These weren't checked by new(), so make
	# each name valid rather than reject it: upper-case, other characters
	# to '_', no leading '_' (journald reserves those for trusted fields)
	# and at most 64 characters
	my $fields = $event->{'fields'} || {};
	for my $key (keys %{$fields}) {
		(my $name = uc($key)) =~ s/[^A-Z0-9_]/_/g;
		$name =~ s/^_+//;
		$name = substr($name, 0, $MAX_FIELD_NAME);
		next if(($name eq '') || $name =~ /^(?:MESSAGE|PRIORITY|SYSLOG_IDENTIFIER)$/);
		$entry{$name} = $event->{'field_string'}->($fields->{$key});
	}

	# Delivery failures are silent; the app must not crash on log errors.
	# Carp only on the first failure, so that a system without journald
	# (FreeBSD, macOS) isn't flooded with warnings; a later success re-arms
	# the warning.
	if(eval { $self->_send($self->{'socket'}, %entry); 1 }) {
		delete $logger->{'_journald_failed'};
	} elsif(!$logger->{'_journald_failed'}++) {
		Carp::carp(ref($logger), ": journald send failed: $@");
	}
}

# ---------------------------------------------------------------------------
# _send -- encode fields and send one datagram to the journald socket
#
# Purpose:      Format key=value fields in the journald native protocol and
#               deliver them as a single Unix-domain SOCK_DGRAM packet.
# Entry:        $self        -- the backend, which keeps the socket in
#                              $self->{_socket} between messages.
#               $socket_path -- filesystem path of the journald socket.
#               %fields      -- FIELD_NAME => value pairs; names must be
#                              uppercase ASCII + digits + underscore.
# Exit:         Returns nothing.  Croaks on socket or send failure (the caller
#               wraps every call in eval{} so failures are silent to the app).
# Side effects: Opens a Unix datagram socket on the first call, and keeps it
#               for the next; closes it after a failed send, so that the
#               next message gets a new one.
# Notes:        Values containing newline or NUL use the binary framing
#               (field-name NL uint64-LE-length value NL) as specified by
#               https://systemd.io/JOURNAL_NATIVE_PROTOCOL/.
#               Values without newlines or NULs use the simpler FIELD=VALUE NL
#               text format.  The send buffer, and so the largest datagram,
#               varies between systems: a send failing with EMSGSIZE is
#               retried with MESSAGE truncated to half the size, down to
#               $MIN_PAYLOAD.  The socket isn't connected: each datagram is
#               addressed to the path, so it still arrives after journald
#               restarts and creates the socket file again.
# ---------------------------------------------------------------------------
sub _send :Private {
	my ($self, $socket_path, %fields) = @_;

	# The protocol carries bytes, and binary framing declares a byte length,
	# so encode character strings to UTF-8 first
	for my $key (keys %fields) {
		my $value = defined($fields{$key}) ? "$fields{$key}" : '';
		utf8::encode($value) if(utf8::is_utf8($value));
		$fields{$key} = $value;
	}

	# Build the datagram payload from all supplied fields
	my $build = sub {
		my $payload = '';
		for my $key (sort keys %fields) {
			my $value = $fields{$key};
			if($value =~ /[\n\0]/) {
				# Binary framing: field-name LF uint64LE-length value LF.
				# The length is packed as two 32-bit little-endian words
				# because pack('Q') dies on perls without 64-bit integers
				my $len = length($value);
				$payload .= $key . "\n"
					. pack('VV', $len % 2**32, int($len / 2**32))
					. $value . "\n";
			} else {
				$payload .= "$key=$value\n";
			}
		}
		return $payload;
	};
	my $full = $build->();
	my $message = $fields{'MESSAGE'};

	# A datagram bigger than the socket send buffer fails outright, so
	# truncate MESSAGE to fit in $limit bytes.  The extra 8 bytes allow for
	# the message switching from text to binary framing.
	my $fit = sub {
		my $limit = shift;
		my $excess = length($full) - $limit;
		return $full if(($excess <= 0) || !defined($message));
		my $keep = length($message) - $excess - length($TRUNCATED_MARKER) - 8;
		my $cut = substr($message, 0, ($keep > 0) ? $keep : 0);
		# Don't leave a partial UTF-8 sequence at the cut
		$cut =~ s/[\xC0-\xFF][\x80-\xBF]*\z//;
		$fields{'MESSAGE'} = $cut . $TRUNCATED_MARKER;
		return $build->();
	};

	# The Unix-domain datagram socket, opened on the first message and then
	# reused
	require Socket;
	my $sock = $self->{_socket} //= do {
		socket(my $new, Socket::AF_UNIX(), Socket::SOCK_DGRAM(), 0);

		# Ask for a send buffer big enough for the largest datagram; the
		# kernel may cap it (net.core.wmem_max), which the retry handles
		no autodie qw(setsockopt);
		setsockopt($new, Socket::SOL_SOCKET(), Socket::SO_SNDBUF(), $MAX_PAYLOAD + 1024);
		$new;
	};
	my $dest = Socket::sockaddr_un($socket_path);

	{
		# send() is checked by hand: EMSGSIZE means retry smaller
		no autodie qw(send);

		my $limit = $MAX_PAYLOAD;
		while(1) {
			last if(defined(send($sock, $fit->($limit), 0, $dest)));
			my $err = $!;
			if(($err == POSIX::EMSGSIZE()) && ($limit > $MIN_PAYLOAD)) {
				$limit = int($limit / 2);
				next;
			}
			# Start again with a new socket next time
			delete $self->{_socket};
			eval { close $sock };
			Carp::croak("Can't send to $socket_path: $err");
		}
	}
	return;
}


=head1 AUTHOR

Nigel Horne C<njh@nigelhorne.com>

=head1 SEE ALSO

L<Log::Abstraction>, L<Log::Abstraction::Backend>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
