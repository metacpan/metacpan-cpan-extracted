# $Id: Message.pm,v 1.14 2009/11/30 14:28:19 dk Exp $

use strict;
use warnings;

package IO::Lambda::Message;

our $CRLF  = "\x0a";
our @EXPORT_OK = qw(message);
our $DEBUG = $IO::Lambda::DEBUG{message} || 0;

use Carp;
use Exporter;
use IO::Lambda qw(:all :dev);

sub _d { "message(" . _o($_[0]) . ")" }

sub new
{
	my ( $class, $r, $w, %opt ) = @_;

	$opt{reader} ||= sysreader;
	$opt{writer} ||= syswriter;
	$opt{buf}    ||= '';
	$opt{async}  ||= 0;

	croak "Invalid read handle" unless $r;
	$w = $r unless $w;

	my $self = bless {
		%opt,
		r     => $r,
		w     => $w,
		queue => [],
	}, $class;
	
	warn "new ", _d($self) . "\n" if $DEBUG;

	return $self;	
}

# () :: (self, msg, deadline) -> error
sub sender
{
	$_[0]->{sender} ||= lambda {
		my ( $self, undef, $deadline) = @_;
		my $msg = sprintf("%08x%s%s%s", length($_[1]), $CRLF, $_[1], $CRLF);
		warn _d($self), "msg > [$msg]\n" if $DEBUG > 1;
	context 
		writebuf($self-> {writer}), $self-> {w},
		\ $msg, undef, 0, $deadline;
	tail {
		$_[1]
	}}
}

# () :: (self, deadline) -> (msg, error)
sub receiver
{
	$_[0]->{receiver} ||= lambda {
		my ( $self, $deadline) = @_;
	context 
		readbuf($self-> {reader}), $self-> {r}, \$self-> {buf}, 9,
		$deadline;
	tail {
		my ( $size, $error) = @_;
		return ( undef, $error) if defined $error;
		$size = substr( $self-> {buf}, 0, 9, '');
		return ( undef, "protocol error: chunk size not set")
			unless $size =~ /^[a-f0-9]+$/i;

		chop $size;
		$size = length($CRLF) + hex $size;

	context
		readbuf($self-> {reader}), $self-> {r}, \$self-> {buf},
		$size, $deadline;
	tail {
		my $error = $_[1];
		return ( undef, $error) if defined $error;
		my $msg = substr( $self-> {buf}, 0, $size, '');
		chop $msg;
		warn _d($self), "msg < [$msg]\n" if $DEBUG > 1;
		return $msg;
	}}}
}

# () :: (self, msg, deadline) -> (response, error)
sub pusher
{
	$_[0]->{pusher} ||= lambda {
		my ( $self, undef, $deadline) = @_;
		context $self-> sender, $self, $_[1], $deadline;
	tail {
		my ( $result, $error) = @_;
		return ( undef, $error) if defined $error;
		context $self-> receiver, $self, $deadline;
		&tail();
	}}
}

# () :: (self, deadline) -> error
sub incoming { die "abstract call" }
sub puller
{
	$_[0]->{puller} ||= lambda {
		my ( $self, $deadline) = @_;
		context $self-> receiver, $self, $deadline;
	tail {
		my ( $msg, $error) = @_;
		return ( undef, $error) if defined $error;
		$msg = $self-> incoming( $msg);

		context $self-> sender, $self, $msg, $deadline;
		&tail();
	}}
}

sub error
{
	return $_[0]-> {error} unless $#_;
	$_[0]-> {error} = $_[1];
}

# lambda that sends all available messages in queue
# () :: self -> error
sub outcoming { $_[1] }
sub queue_pusher
{
	$_[0]->{queue_pusher} ||= lambda {
		my $self = shift;

		warn _d($self) . ": sending msg ",
			length($self-> {queue}-> [0]-> [2]), " bytes ",
			_t($self-> {queue}-> [0]-> [3]),
			"\n" if $DEBUG;
		context $self-> pusher,
			$self,
			$self-> {queue}-> [0]-> [2],
			$self-> {queue}-> [0]-> [3];
	tail {
		my ( $result, $error) = @_;
		if ( defined $error) {
			$self-> error($error);
			warn _d($self) . " > error $error\n" if $DEBUG;
			$self-> cancel_queue( undef, $error);
			return $error;
		}
		
		# signal result to the outer lambda
		my $q = shift @{$self-> {queue}};
		unless ( $q) {
			# cancel_queue was called?
			return;
		}

		my ( $outer, $bind) = @$q;
		$outer-> resolve( $bind);
		$outer-> terminate( $self-> outcoming( $result));
		
		# stop if it's all
		unless ( @{$self-> {queue}}) {
			warn _d($self) . ": push -> listen\n" if $DEBUG;
			$self-> listen;
			return;
		}
		$q = $self-> {queue}-> [0];

		# fire up the next request
		warn _d($self) . ": sending msg ",
			length($q->[2]), " bytes ",
			_t($q->[3]),
			"\n" if $DEBUG;
		context $self-> pusher, $self, $q->[2], $q->[3];
		again;
	}}
}

# () :: self -> error
sub listener
{
	$_[0]->{listener} ||= lambda {
		my $self = shift;
		context $self-> puller, $self;
	tail {
		my ( $result, $error) = @_;
		if ( defined $error) {
			$self-> error($error);
			warn _d($self) . " > error $error\n" if $DEBUG;
			$self-> cancel_queue( undef, $error);	
			return $error;
		}

		# enough listening, now push
		if ( @{$self-> {queue}}) {
			warn _d($self) . ": listen -> push\n" if $DEBUG;
			$self-> push;
			return;
		}

		again;
	}}
}

sub is_pushing   { $_[0]-> {queue_pusher} and $_[0]-> {queue_pusher}-> is_waiting }
sub is_listening { $_[0]-> {listener}     and $_[0]-> {listener}->     is_waiting }

sub push
{
	my ( $self) = @_;

	croak "won't start, have errors: $self->{error}" if $self-> {error};
	croak "won't start, already pushing"   if $self-> is_pushing;
	croak "won't start, already listening" if $self-> is_listening;
	warn _d($self) . ": start push\n" if $DEBUG;

	my $q = $self-> queue_pusher;
	$q-> reset;
	$q-> call($self);
	$q-> start;
}

sub listen
{
	my ( $self) = @_;

	# need explicit consent
	return unless $self-> {async};

	croak "won't listen, have errors: $self->{error}" if $self-> {error};
	croak "won't listen, already pushing"   if $self-> is_pushing;
	croak "won't listen, already listening" if $self-> is_listening;
	warn _d($self) . ": start listen\n" if $DEBUG;

	my $q = $self-> listener;
	$q-> reset;
	$q-> call($self);
	$q-> start;
}

# cancel all messages, store error on all of them
sub cancel_queue
{
	my ( $self, @reason) = @_;
	return unless $self-> {queue};
	for my $q ( @{ $self-> {queue}}) {
		my ( $outer, $bind) = @$q;
		$outer-> resolve( $bind);
		$outer-> terminate( @reason);
	}
	@{ $self-> {queue} } = ();
}

# (msg,deadline) :: () -> (result,error)
sub new_message
{
	my ( $self, $msg, $deadline) = @_;
 
	return lambda { $self-> error } if $self-> error;

	warn _d($self) . " > msg ", _t($deadline), " ", length($msg), " bytes\n" if $DEBUG;
	
	# won't end until we call resolve
	my $outer = IO::Lambda-> new;
	my $bind  = $outer-> bind;
	CORE::push @{ $self-> {queue} }, [ $outer, $bind, $msg, $deadline ];

	$self-> push if 1 == @{$self-> {queue}} and not $self-> is_listening;

	return $outer;
}

sub message(&) { new_message(context)-> condition( shift, \&message, 'message') }

package IO::Lambda::Message::Simple;

my $debug = $IO::Lambda::DEBUG{message} || 0;

sub _d { "simple_msg($_[0])" }

sub new
{
	my ( $class, $r, $w) = @_;
	$w = $r unless $w;
	my $self = bless {
		r => $r,
		w => $w,
	}, $class;
	warn "new ", _d($self) . "\n" if $debug;
	return $self;
}

sub read
{
	my $self = $_[0];

	my $size = readline($self-> {r});
	die "bad size" unless defined($size) and $size =~ /^[0-9a-f]+\n$/i;
	chop $size;
	$size = 1 + hex $size;

	my $buf = '';
	while ( $size > 0) {
		my $b = readline($self-> {r});
		die "can't read from socket: $!"
			unless defined $b;
		$size -= length($b);
		$buf .= $b;
	}

	chop $buf;

	warn _d($self) . ": ", length($buf), " bytes read\n" if $debug > 1;

	return $buf;
}

sub write
{
	my ( $self, $msg) = @_;
	printf( { $self-> {w} } "%08x\x0a%s\x0a", length($msg), $msg)
		or die "can't write to socket: $!";
	warn _d($self) . ": ", length($msg), " bytes written\n" if $debug > 1;
}

sub quit { $_[0]-> {run} = 0 }

sub run
{
	my $self = $_[0];

	$self-> {run} = 1;
	$self-> {w}-> autoflush(1);

	while ( $self-> {run} ) {
		my ( $msg, $error) = $self-> read;
		die "bad message: $error" if defined $error;
		( $msg, $error) = $self-> decode( $msg);

		my $response;
		if ( defined $error) {
			$response = [0, "bad message: $error"];
			warn _d($self) . ": bad message: $error\n" if $debug;
			goto SEND;
		}
		unless ( $msg and ref($msg) and ref($msg) eq 'ARRAY' and @$msg > 0) {
			$response = [0, "bad message"];
			warn _d($self) . ": bad message\n" if $debug;
			goto SEND;
		}

		my $method = shift @$msg;

		if ( $self-> can($method)) {
			my $wantarray = shift @$msg;
			my @r;
			eval {
				if ( $wantarray) {
					@r    = $self-> $method(@$msg);
				} else {
					$r[0] = $self-> $method(@$msg);
				}
			};
			if ( $@) {
				warn _d($self) . ": $method / died $@\n" if $debug;
				$response = [0, $@];
				$self-> quit;
			} else {
				warn _d($self) . ": $method / ok\n" if $debug;
				$response = [1, @r];
			}
		} else {
			warn _d($self) . ": no such method: $method\n" if $debug;
			$response = [0, 'no such method'];
		};
	SEND:
		( $msg, $error) = $self-> encode($response);
		if ( defined $error) {
			warn _d($self) . ": encode error $error\n" if $debug;
			( $msg, $error) = $self-> encode([0, $error]);
			die $error if $error;
		}
		$self-> write($msg);
	}

	warn _d($self) . " quit\n" if $debug;
}

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::Message - message passing queue

=head1 DESCRIPTION

The module implements a generic message passing protocol, and two generic
classes that implement the server and the client functionality. The server code
is implemented in a simple, blocking fashion, and is expected to be executed
remotely. The client API is written in lambda style, where message completion
can be asynchronously awaited for. The communication between server and client
is done through two file handles of any type ( stream sockets, pipes, etc ).

=head1 SYNOPSIS

    use IO::Lambda::Message qw(message);

    lambda {
       my $messenger = IO::Lambda::Message-> new( \*READER, \*WRITER);
       context $messenger-> new_message('hello world');
    tail {
       print "response1: @_, "\n";
       context $messenger, 'same thing';
    message {
       print "response2: @_, "\n";
       undef $messenger;
    }}}

=head1 Message protocol

The message passing protocol featured here is synchronous, which means that any
message initiated either by server or client is expected to be replied to.
Both server and client can wait for the message reply, but they cannot
communicate while waiting.

Messages are prepended with simple header, that is a 8-digit hexadecimal length
of the message, and 1 byte with value 0x0A (newline).  After the message
another 0x0A byte is followed.

=head1 IO::Lambda::Message

The class implements a generic message passing queue, that allows adding
asynchronous messages to the queue, and wait for the response.

=over

=item new $class, $reader, $writer, %options

Constructs a new object of C<IO::Lambda::Message> class, and attaches to
C<$reader> and C<$writer> file handles ( which can be the same object, and in
which case C<$writer> can be omitted, but only if C<%options> is empty too).
Accepted options:

=over

=item reader :: ($fh, $buf, $cond, $deadline) -> ioresult

Custom reader, C<sysreader> by default.

=item writer :: ($fh, $buf, $length, $offset, $deadline) -> ioresult

Custom writer, C<syswriter> by default.

=item buf :: string

If C<$reader> handle was used (or will be needed to be used) in buffered I/O,
its buffer can be passed along to the object.

=item async :: boolean

If set, the object will listen for incoming messages from the server, otherwise
it will only initiate outcoming messages. By default set to 0, and the method
C<incoming> that handles incoming messages, dies. This functionality is
designed for derived classes, not for the caller.

=back

=item new_message($message, $deadline = undef) :: () -> ($response, $error)

Registers a new message in the queue. The message must be delivered and replied
to no later than C<$deadline>, and returns a lambda that will be ready when the
message is responded to. The lambda returns the response or the error.

Upon communication error, all queued messages are discarded.  Timeout is regarded
as a protocol error too, so use the C<$deadline> option with care. That means, as soon
the deadline error is fired, communication is no longer possible; the remote will wait
for its eventual response to be read by your program, which no longer listens. And if
it tries to write to the socket again, the whole thing will deadlock. Consider using
other means to wait for the message with a timeout.

=item message ($message, $deadline = undef) :: () -> ($response, $error)

Condition version of C<new_message>.

=item cancel_queue(@reason)

Cancels all pending messages, stores C<@reason> in the associated lambdas.

=item error

Returns the last protocol handling error. If set, no new messages are allowed
to be registered, and listening will fail too.

=item is_listening

If set, object is listening for asynchronous events from server.

=item is_pushing

If set, object is sending messages to the server.

=back

=head1 IO::Lambda::Message::Simple

The class implements a simple generic protocol dispatcher, that
executes methods of its own class, and returns the results back
to the client. The methods have to be defined in a derived class.

=over

=item new $reader [$writer = $reader]

Creates a new object that will communicate with clients using 
given handles, in a blocking fashion.

=item run

Starts the message loop

=item quit

Signals the loop to stop

=back

=head1 SEE ALSO

L<IO::Lambda::DBI>.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
