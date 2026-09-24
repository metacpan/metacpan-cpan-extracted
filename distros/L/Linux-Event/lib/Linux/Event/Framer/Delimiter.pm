package Linux::Event::Framer::Delimiter;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, $delimiter = undef, @args) {
    croak 'Delimiter requires a delimiter byte string' if !defined $delimiter;
    croak 'Delimiter must not be empty' if $delimiter eq '';
    croak 'Delimiter options must be key/value pairs' if @args % 2;
    my %opt = @args;
    my $include_delimiter = delete $opt{include_delimiter} // 0;
    my $max_frame = delete $opt{max_frame};
    croak 'max_frame must be a non-negative integer'
        if defined($max_frame) && ($max_frame !~ /\A\d+\z/ || $max_frame < 0);
    croak 'unknown Delimiter options: ' . join(', ', sort keys %opt) if %opt;

    my $native = {
        read_mode         => 2,
        delimiter         => $delimiter,
        include_delimiter => $include_delimiter ? 1 : 0,
        max_frame         => $max_frame,
    };
    return { native => $native, frame => \&_frame };
}

sub _frame ($config, $payload) {
    $payload = '' if !defined $payload;
    my $length = bytes::length($payload);
    croak "send(): payload length $length exceeds max_frame=$config->{max_frame}"
        if defined($config->{max_frame}) && $length > $config->{max_frame};
    return $payload . $config->{delimiter};
}

1;

__END__

=head1 NAME

Linux::Event::Framer::Delimiter - Split an ordered byte stream at a delimiter

=head1 SYNOPSIS

  package LineStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      say "line: $message";
  }

=head1 DESCRIPTION

C<Linux::Event::Framer::Delimiter> defines messages by a terminating byte
sequence.

For example:

  use Linux::Event::Framer 'Delimiter', "\n";

means that these wire bytes:

  hello\nworld\n

produce two messages:

  hello
  world

Delimiter framing is useful for protocols based on:

  "\n"
  "\r\n"
  "\0"

or any other non-empty byte sequence.

The delimiter may contain arbitrary bytes.

=head1 DECLARING THE FRAMER

Declare the framer after the ordered-byte parent class:

  package LineStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

The same framer can be used with:

  Linux::Event::IO::Sock::Stream
  Linux::Event::IO::Pipe
  Linux::Event::IO::TTY

because delimiter framing operates on ordered bytes rather than on a particular
kind of Linux resource.

=head1 THE DELIMITER IS REQUIRED

The first argument after C<Delimiter> is the delimiter byte string:

  use Linux::Event::Framer 'Delimiter', "\r\n";

The delimiter must not be empty.

This is invalid:

  use Linux::Event::Framer 'Delimiter', '';

An empty delimiter could not define meaningful message boundaries and is
rejected during class setup.

=head1 DELIMITERS MAY CROSS READ BOUNDARIES

Kernel reads are not application message boundaries.

For example, Linux might deliver:

  first read:   "hello\r"
  second read:  "\nworld\r\n"

to a CRLF-framed stream.

Linux::Event preserves the partial delimiter and still emits:

  hello
  world

The application does not need to join read chunks or search for split
delimiters itself.

=head1 MULTIPLE MESSAGES MAY ARRIVE AT ONCE

One kernel read may contain several complete messages:

  one\ntwo\nthree\n

Linux::Event detects all complete frames already present in the ordered-byte
input and delivers them through the configured message callback.

The application should therefore think in terms of messages rather than read
calls.

=head1 RECEIVING MESSAGES

By default, the delimiter itself is removed before delivery:

  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      ...
  }

For wire input:

  hello\n

C<$message> contains:

  hello

not:

  hello\n

=head1 INCLUDING THE DELIMITER

=head2 include_delimiter

Set:

  use Linux::Event::Framer 'Delimiter', "\r\n",
      include_delimiter => 1;

to include the terminating delimiter in the inbound message.

With wire input:

  hello\r\n

the callback receives:

  hello\r\n

This option affects inbound message delivery.

It does not change what bytes are consumed from the underlying stream.

=head1 LIMITING MESSAGE SIZE

=head2 max_frame

An optional C<max_frame> protects against unexpectedly large messages:

  use Linux::Event::Framer 'Delimiter', "\n",
      max_frame => 1_048_576;

The limit is measured in payload bytes before the delimiter.

For example, with:

  max_frame => 1024

a message whose payload grows beyond 1024 bytes without reaching the configured
delimiter is rejected as a framing error.

C<max_frame> must be a non-negative integer.

Omitting it means the Delimiter framer itself does not impose a payload-size
limit.

The ordered-byte resource may still have its separate C<max_buffer> limit.

=head1 SENDING

For a framed resource:

  $self->send($payload);

appends the configured delimiter.

For example:

  use Linux::Event::Framer 'Delimiter', "\r\n";

and:

  $self->send("hello");

produce these wire bytes:

  hello\r\n

The application should normally pass only the payload to C<send>.

Do not manually append the delimiter unless the protocol intentionally requires
an additional delimiter.

=head1 SEND AND INCLUDE_DELIMITER ARE INDEPENDENT

C<include_delimiter> controls only what is delivered B<inbound> to
C<on_message>.

It does not change outbound framing.

For example:

  use Linux::Event::Framer 'Delimiter', "\n",
      include_delimiter => 1;

still causes:

  $self->send("hello");

to emit exactly:

  hello\n

not:

  hello\n\n

=head1 RAW WRITE

Use:

  $self->write($bytes);

when raw bytes should be written without automatically appending the delimiter.

For example:

  $self->write("hello");

writes exactly:

  hello

while:

  $self->send("hello");

writes:

  hello<delimiter>

This distinction is useful when implementing protocol handshakes or other
special wire sequences.

=head1 BINARY DELIMITERS

Delimiter framing is not restricted to text.

For example:

  use Linux::Event::Framer 'Delimiter', "\x00\xff";

is valid.

The delimiter is treated as a byte string.

This makes the framer suitable for binary sentinel-based protocols as well as
line-oriented text protocols.

=head1 EMPTY PAYLOADS

A delimiter may appear with no payload bytes before it.

Conceptually:

  <delimiter>

represents an empty framed message.

This is distinct from an empty delimiter, which is not permitted.

=head1 ERROR BEHAVIOR

Malformed framing caused by exceeding C<max_frame> is reported through the
normal ordered-byte framing error path.

The resulting L<Linux::Event::Error> has type:

  framing

The resource then follows its ordinary framing-error lifecycle.

=head1 PERFORMANCE MODEL

Inbound delimiter search runs in Linux::Event's native ordered-byte framing
engine.

Partial delimiters and incomplete messages remain in native input storage until
a complete boundary is found.

There is no per-connection Perl Delimiter object and no need for application
code to repeatedly scan accumulated Perl strings for the delimiter.

=head1 SEE ALSO

L<Linux::Event::Framer>,
L<Linux::Event::Framer::Fixed>,
L<Linux::Event::Framer::LengthPrefix>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>,
F<docs/FRAMING.md>,
F<docs/CHOOSING-A-FRAMER.md>.

=cut
