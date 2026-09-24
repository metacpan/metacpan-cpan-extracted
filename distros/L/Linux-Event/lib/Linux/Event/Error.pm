package Linux::Event::Error;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use overload '""' => 'as_string', fallback => 1;

sub new ($class, %arg) {
    return bless {
        type      => $arg{type} // 'event',
        operation => $arg{operation},
        option    => $arg{option},
        errno     => $arg{errno},
        message   => $arg{message} // 'Linux::Event error',
        pending_bytes => $arg{pending_bytes},
        pending_datagrams => $arg{pending_datagrams},
        datagram_size => $arg{datagram_size},
        limit         => $arg{limit},
        fatal          => $arg{fatal} ? 1 : 0,
        host           => $arg{host},
        port           => $arg{port},
        path           => $arg{path},
        family         => $arg{family},
        attempts       => $arg{attempts},
        resolver_message => $arg{resolver_message},
        timeout        => $arg{timeout},
        deadline       => $arg{deadline},
    }, $class;
}

sub type      ($self) { $self->{type} }
sub operation ($self) { $self->{operation} }
sub option    ($self) { $self->{option} }
sub errno     ($self) { $self->{errno} }
sub message   ($self) { $self->{message} }
sub pending_bytes ($self) { $self->{pending_bytes} }
sub pending_datagrams ($self) { $self->{pending_datagrams} }
sub datagram_size ($self) { $self->{datagram_size} }
sub limit         ($self) { $self->{limit} }
sub fatal         ($self) { $self->{fatal} }
sub host          ($self) { $self->{host} }
sub port          ($self) { $self->{port} }
sub path          ($self) { $self->{path} }
sub family        ($self) { $self->{family} }
sub attempts      ($self) { $self->{attempts} }
sub resolver_message ($self) { $self->{resolver_message} }
sub timeout       ($self) { $self->{timeout} }
sub deadline      ($self) { $self->{deadline} }

sub as_string ($self, @ignored) {
    my $text = $self->{message};
    $text = "$self->{operation}: $text" if defined $self->{operation};
    $text .= " (errno=$self->{errno})" if defined $self->{errno};
    return $text;
}

1;

__END__

=head1 NAME

Linux::Event::Error - Structured error information from Linux::Event

=head1 SYNOPSIS

  on_error => sub ($self, $error) {
      warn $error->type . ': ' . $error->message . "\n";

      if (defined(my $errno = $error->errno)) {
          warn "errno=$errno\n";
      }
  }

=head1 DESCRIPTION

C<Linux::Event::Error> represents a structured Linux::Event failure.

Instead of forcing application code to parse an error string, it provides
separate fields such as:

  type
  operation
  errno
  message

and additional context when a particular error needs it.

For example, a failed connection might contain:

  type       connect
  operation  connect
  errno      111
  message    Connection refused
  host       127.0.0.1
  port       9
  attempts   2

Applications can therefore make decisions from the structured fields while
still using the object directly as a readable diagnostic.

=head1 WHERE ERROR OBJECTS APPEAR

Linux::Event::Error objects are used in two main ways.

=head2 Error callbacks

Many Linux::Event resources provide an C<on_error> callback:

  on_error => sub ($self, $error) {
      ...
  }

For example, Stream, Listener, Datagram, and Process can report asynchronous
runtime failures this way.

=head2 Thrown errors

Some synchronous setup or API failures throw a C<Linux::Event::Error> directly.

For example:

  my $ok = eval {
      $process->signal($signal);
      1;
  };

  if (!$ok) {
      my $error = $@;

      if (ref($error) && $error->isa('Linux::Event::Error')) {
          say $error->operation;
      }
  }

Whether an error is thrown or delivered through a callback depends on the API
and on when the failure occurs.

The Error object itself uses the same structured model in either case.

=head1 STRINGIFICATION

Error objects stringify automatically.

For example:

  warn "$error\n";

might produce:

  connect: Connection refused (errno=111)

The string form is intended for people.

Do B<not> parse it to make application decisions.

Use accessors instead:

  if ($error->type eq 'timeout') {
      ...
  }

=head1 COMMON FIELDS

The following fields are the most broadly useful.

=head2 type

  my $type = $error->type;

Return the broad category of failure.

Examples currently used by Linux::Event include:

  io
  framing
  output_limit
  resolve
  socket
  socket_configuration
  connect
  timeout
  setup
  accept
  resource
  listener
  callback
  datagram_size
  process
  process_io
  tls

The set may grow as Linux::Event gains capabilities.

Applications should normally handle the error types they care about and keep a
general fallback for unfamiliar values.

For example:

  if ($error->type eq 'timeout') {
      retry_later();
  }
  else {
      warn "$error\n";
  }

=head2 operation

  my $operation = $error->operation;

Return the operation that was being performed when the failure occurred.

Examples include:

  connect
  bind
  setsockopt
  write
  write_stdin
  receive
  waitid
  signal
  idle
  read

C<operation> is more specific than C<type>.

For example, several different socket-configuration failures may all have:

  type => 'socket_configuration'

while C<operation> identifies whether the failing action was C<bind>,
C<setsockopt>, or another configuration step.

C<operation> may be undefined when no useful operation label applies.

=head2 message

  my $message = $error->message;

Return the human-readable description of the failure.

For example:

  Connection refused

or:

  pending output would exceed 16384 bytes

The message is useful for logs and diagnostics.

Application logic should prefer structured fields whenever possible.

=head2 errno

  my $errno = $error->errno;

Return the numeric system C<errno> when the failure corresponds to a system
error.

For example:

  if (defined(my $errno = $error->errno)) {
      say "system errno: $errno";
  }

Not every Linux::Event error originates from a syscall, so C<errno> may be
undefined.

=head1 SOCKET CONFIGURATION DETAILS

=head2 option

  my $option = $error->option;

For C<socket_configuration> errors, this may identify the socket option involved.

For example:

  type      => 'socket_configuration'
  operation => 'setsockopt'
  option    => 'v6only'

For unrelated errors, C<option> is normally undefined.

=head1 ADDRESS CONTEXT

Some connection, listener, or datagram failures include address information.

=head2 host

  my $host = $error->host;

Return the applicable host when one was part of the failing operation.

=head2 port

  my $port = $error->port;

Return the applicable port.

=head2 path

  my $path = $error->path;

Return an applicable Unix-domain socket path.

=head2 family

  my $family = $error->family;

Return applicable socket-family context.

These fields are optional.

An application should test whether a value is defined before using it.

=head1 CONNECTION ATTEMPTS

=head2 attempts

  my $count = $error->attempts;

Outbound Stream connection logic may try several candidate addresses.

C<attempts> records how many connection attempts were made when that information
is available.

For example:

  on_error => sub ($self, $error) {
      if ($error->type eq 'connect') {
          say "attempts: " . ($error->attempts // 0);
      }
  }

For unrelated errors, C<attempts> is undefined.

=head1 RESOLVER DETAILS

=head2 resolver_message

  my $message = $error->resolver_message;

When hostname resolution fails, this field preserves the resolver-specific
diagnostic when one is available.

For example, a connection error can retain both the general Linux::Event
C<message> and the resolver's own explanation.

For errors unrelated to hostname resolution, this field is undefined.

=head1 OUTPUT LIMIT DETAILS

Ordered-byte resources and Process stdin can report hard queue limits using
C<output_limit> errors.

=head2 pending_bytes

  my $bytes = $error->pending_bytes;

Return the amount of queued output that would have existed when the limit was
exceeded.

For example:

  if ($error->type eq 'output_limit') {
      say "pending: " . $error->pending_bytes;
      say "limit:   " . $error->limit;
  }

=head2 limit

  my $limit = $error->limit;

Return the configured hard limit relevant to the error.

C<limit> is also used with some Datagram size or queue errors.

=head1 DATAGRAM QUEUE DETAILS

Datagram output limits may include both byte and packet counts.

=head2 pending_datagrams

  my $count = $error->pending_datagrams;

Return the number of datagrams that would be pending when a Datagram queue limit
is exceeded.

=head2 pending_bytes

The same error may also include the pending byte count.

For example:

  on_error => sub ($self, $error) {
      if ($error->type eq 'output_limit') {
          say "queued datagrams: " . $error->pending_datagrams;
          say "queued bytes:     " . $error->pending_bytes;
      }
  }

These values are undefined when they do not apply.

=head1 OVERSIZED DATAGRAM DETAILS

=head2 datagram_size

  my $size = $error->datagram_size;

A received Datagram that exceeds the configured maximum may produce a
C<datagram_size> error.

C<datagram_size> reports the original packet size when Linux made that
information available.

C<limit> identifies the configured maximum.

For example:

  on_error => sub ($self, $error) {
      if ($error->type eq 'datagram_size') {
          say "packet size: " . $error->datagram_size;
          say "maximum:     " . $error->limit;
      }
  }

Linux::Event does not deliver a truncated packet as though it were complete.

=head1 TIMEOUT DETAILS

Timeout errors use:

  type => 'timeout'

=head2 timeout

  my $seconds = $error->timeout;

For relative inactivity policies, C<timeout> contains the configured duration in
seconds.

Examples include established Stream:

  idle_timeout
  read_timeout
  write_timeout

For an explicitly absolute deadline, C<timeout> may be undefined.

=head2 deadline

  my $deadline = $error->deadline;

Return the absolute monotonic deadline that expired when that information is
available.

The value uses the same monotonic time model as
L<Linux::Event::Kernel::Timer>.

For unrelated errors, C<timeout> and C<deadline> are undefined.

=head1 FATALITY

=head2 fatal

  if ($error->fatal) {
      ...
  }

Return true when the producer of the Error marked the failure as fatal to the
resource or setup operation.

For example, Listener and Datagram setup failures can be marked fatal because
the resource cannot continue using the failed configuration.

Not every runtime error is fatal.

For example, a Listener callback failure may be reported without making the
Listener itself unusable.

C<fatal> should therefore be treated as explicit context supplied by the
resource that created the Error, not inferred solely from C<type>.

=head1 AS_STRING

=head2 as_string

  my $text = $error->as_string;

Return the same concise diagnostic used by string overloading.

The format is approximately:

  operation: message (errno=N)

with the operation or errno portion omitted when that field is unavailable.

For example:

  my $error = Linux::Event::Error->new(
      type      => 'connect',
      operation => 'connect',
      errno     => 111,
      message   => 'Connection refused',
  );

  say $error->as_string;

prints:

  connect: Connection refused (errno=111)

=head1 CONSTRUCTING AN ERROR

Applications may construct compatible Error values directly:

  my $error = Linux::Event::Error->new(
      type      => 'application',
      operation => 'decode',
      message   => 'invalid application record',
  );

The constructor accepts the same fields exposed by the public accessors.

Fields not supplied remain undefined, except:

=over 4

=item C<type>

Defaults to C<event>.

=item C<message>

Defaults to C<Linux::Event error>.

=item C<fatal>

Defaults to false.

=back

This can be useful when application-level components want to use the same error
shape as Linux::Event.

=head1 IMMUTABILITY

Error objects have no public setters.

They are intended to describe a failure that has already occurred.

Application code may keep an Error object, log it, inspect it, or pass it to
another layer without expecting its contents to change.

=head1 DO NOT ASSUME EVERY FIELD EXISTS

C<Linux::Event::Error> is deliberately one common structured error type.

Different failures populate different context fields.

For example:

  connect error
      host
      port
      attempts

  timeout error
      timeout
      deadline

  output limit
      pending_bytes
      limit

  datagram size
      datagram_size
      limit

An accessor that does not apply normally returns C<undef>.

Code should therefore test optional fields rather than assuming they are always
present.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Sock::Listener>,
L<Linux::Event::IO::Sock::Dgram>,
L<Linux::Event::Kernel::Process>,
L<Linux::Event::Kernel::Timer>.

=cut
