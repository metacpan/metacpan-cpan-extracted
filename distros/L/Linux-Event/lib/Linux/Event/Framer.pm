package Linux::Event::Framer;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use Linux::Event::_ByteStream::Descriptor ();

sub _byte_stream_base ($target) {
    return 'Linux::Event::_ByteStream'
        if $target->isa('Linux::Event::_ByteStream');
    return undef;
}

sub import ($class, $keyword = undef, @args) {
    return if !defined($keyword) && !@args;

    my $target = caller;
    croak "use $class requires a built-in framer name"
        if !defined($keyword) || $keyword eq '';
    croak "invalid framer name '$keyword'"
        if $keyword !~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;

    my $base = _byte_stream_base($target);
    croak "$target must be a Linux::Event byte-stream subclass before declaring a framer"
        if !defined $base;

    my $package = "${class}::${keyword}";
    (my $file = "$package.pm") =~ s{::}{/}g;
    eval { require $file; 1 } or do {
        my $error = $@ || "unable to load $package";
        $error =~ s/\s+\z//;
        croak "cannot declare framer '$keyword': $error";
    };

    my $builder = $package->can('_build_definition')
        or croak "$package is not a Linux::Event built-in framer";
    my $definition = $builder->($package, @args);
    croak "$package returned an invalid framer definition"
        if ref($definition) ne 'HASH'
        || ref($definition->{native}) ne 'HASH'
        || ref($definition->{frame}) ne 'CODE';

    $definition->{package} = $package;
    Linux::Event::_ByteStream::Descriptor::declare_framer(
        $base, $target, $definition,
    );
    return;
}

sub declare_native_consumer ($class, $target, $definition) {
    croak 'declare_native_consumer(): must be called as a class method'
        if ref $class;
    croak 'declare_native_consumer(): target class is required'
        if !defined($target) || ref($target) || $target eq '';

    my $base = _byte_stream_base($target);
    croak "$target must be a Linux::Event byte-stream subclass before declaring a native consumer"
        if !defined $base;

    Linux::Event::_ByteStream::Descriptor::declare_consumer(
        $base, $target, $definition,
    );
    return;
}

1;

__END__

=head1 NAME

Linux::Event::Framer - Define message boundaries for ordered byte streams

=head1 SYNOPSIS

  package LineStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      say "received: $message";
      $self->send($message);
  }

=head1 DESCRIPTION

Stream sockets, pipes, and terminals carry bytes.

They do not inherently know where one application message ends and the next
begins.

C<Linux::Event::Framer> lets an ordered-byte subclass declare that message
boundary once.

For example:

  use Linux::Event::Framer 'Delimiter', "\n";

means:

  each message ends at "\n"

while:

  use Linux::Event::Framer 'Fixed', 32;

means:

  every message is exactly 32 bytes

and:

  use Linux::Event::Framer 'U32BE';

means:

  each message starts with a four-byte big-endian payload length

Linux::Event performs built-in framing in native code.

=head1 FRAMING IS CLASS POLICY

A framer is declared on a subclass:

  package LineStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

The declaration must come after C<use parent>.

The framer belongs to the class.

Linux::Event does B<not> create a separate Perl framer object for every
connection.

Therefore every C<LineStream> object uses the same wire format.

This is intentional: framing describes a protocol, not per-connection
application state.

=head1 CALLBACKS CAN STILL BE PER OBJECT

Although framing is class policy, application callbacks may still be supplied
at construction time.

For example:

  my $stream = LineStream->new(
      fh => $fh,

      on_message => sub ($self, $message) {
          handle_message($application, $message);
      },
  );

The framing remains:

  Delimiter "\n"

for every C<LineStream>.

Only that object's application callback changes.

A constructor callback overrides a same-named subclass callback for that
object.

=head1 FRAMERS WORK WITH MORE THAN SOCKETS

Framing belongs to ordered bytes, not specifically TCP.

The same framer system works with subclasses of:

  Linux::Event::IO::Sock::Stream
  Linux::Event::IO::Pipe
  Linux::Event::IO::TTY

For example, terminal lines can be framed exactly like socket lines:

  package Console;

  use parent 'Linux::Event::IO::TTY';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $line) {
      $self->write("You typed: $line\n");
  }

A pipe can use the same policy:

  package LinePipe;

  use parent 'Linux::Event::IO::Pipe';
  use Linux::Event::Framer 'Delimiter', "\n";

=head1 CHOOSING A FRAMER

Linux::Event currently provides these built-in framing families:

=over 4

=item C<Delimiter>

A byte sequence terminates each message.

Typical examples are newline or CRLF protocols.

=item C<Fixed>

Every message has exactly the same byte length.

=item C<LengthPrefix>

A one-, two-, or four-byte unsigned integer gives the payload length.

=item C<U32BE>

A convenient four-byte big-endian payload-length prefix.

=item C<Netstring>

Canonical:

  length:payload,

framing.

=item C<Varint>

An unsigned LEB128 integer gives the payload length.

=item C<DecimalLength>

ASCII decimal digits followed by one separator byte give the payload length.

This includes RFC 6587 octet-counted syslog style.

=back

If none of these matches the protocol, do not force the protocol into an
incorrect framing model.

Use raw C<on_data> parsing instead.

=head1 DELIMITER

Use C<Delimiter> when a specific byte sequence ends each message:

  package LineStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

The delimiter can contain more than one byte:

  use Linux::Event::Framer 'Delimiter', "\r\n";

Linux::Event correctly handles delimiters that cross kernel read boundaries.

For example, one read may end with:

  "\r"

and the next may begin with:

  "\n"

without confusing the framing parser.

=head2 include_delimiter

By default, the delimiter is consumed but not included in the message delivered
to C<on_message>.

To include it:

  use Linux::Event::Framer 'Delimiter', "\r\n",
      include_delimiter => 1;

=head2 max_frame

Optionally limit the payload size:

  use Linux::Event::Framer 'Delimiter', "\n",
      max_frame => 1_048_576;

The limit is measured in bytes before the delimiter.

=head2 Sending

C<send> appends the configured delimiter automatically:

  $self->send("hello");

With a newline delimiter, the wire bytes become:

  hello\n

Use C<write> instead when raw bytes should be sent without framing.

=head1 FIXED-SIZE MESSAGES

Use C<Fixed> when every message has exactly the same byte length:

  package RecordStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Fixed', 32;

The equivalent explicit form is:

  use Linux::Event::Framer 'Fixed',
      size => 32;

Each C<on_message> callback receives exactly 32 bytes.

C<send> requires exactly 32 payload bytes.

For example:

  $self->send($record);

fails if C<$record> is not exactly the configured size.

=head1 BINARY LENGTH PREFIX

Use C<LengthPrefix> when a binary integer before each message states the payload
length:

  package MessageStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'LengthPrefix',
      bytes     => 2,
      endian    => 'big',
      max_frame => 1_048_576;

=head2 bytes

C<bytes> may be:

  1
  2
  4

The default is:

  4

=head2 endian

C<endian> may be:

  big
  little

The default is:

  big

=head2 include_prefix

By default, the length prefix is not included in the delivered message.

To include it:

  include_prefix => 1

=head2 max_frame

Optionally limit the payload byte length:

  max_frame => 1_048_576

=head2 Sending

C<send($payload)> calculates the payload length and prepends the correctly
encoded prefix.

The encoded length is the payload length, not the combined prefix-plus-payload
length.

=head1 U32BE

C<U32BE> is a convenience framer for a common binary format:

  package BinaryStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'U32BE',
      max_frame => 16 * 1024 * 1024;

It means exactly:

  four-byte unsigned big-endian payload length

It is equivalent on the wire to:

  use Linux::Event::Framer 'LengthPrefix',
      bytes  => 4,
      endian => 'big';

C<U32BE> also supports C<include_prefix> and C<max_frame>.

The width and byte order cannot be changed.

=head1 NETSTRING

Use C<Netstring> for canonical netstrings:

  package NetstringStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Netstring',
      max_frame => 1_048_576;

Sending:

  $self->send("hello");

produces:

  5:hello,

Linux::Event validates the netstring format while parsing.

Malformed or noncanonical netstrings are framing errors.

=head1 VARINT LENGTH PREFIX

Use C<Varint> when the payload length is encoded as unsigned LEB128:

  package CompactStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Varint',
      max_frame => 1_048_576;

Small payload lengths require fewer prefix bytes.

C<Varint> supports:

  include_prefix
  max_frame

C<send> produces the canonical variable-width prefix automatically.

Malformed, overlong, or overflowing prefixes are rejected.

=head1 DECIMAL LENGTH

Use C<DecimalLength> when the wire format begins with ASCII decimal payload
length:

  package SyslogStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'DecimalLength',
      separator => ' ',
      max_frame => 1_048_576;

For example:

  $self->send("HELLO");

produces:

  5 HELLO

The default separator is one space.

The separator must be exactly one byte and must not be an ASCII digit.

This framing style matches RFC 6587 octet-counted syslog when the default space
separator is used.

C<DecimalLength> also supports C<include_prefix>.

=head1 RECEIVING MESSAGES

A framed class normally supplies C<on_message>:

  sub on_message ($self, $message) {
      ...
  }

or receives one during construction:

  my $stream = MessageStream->new(
      fh => $fh,

      on_message => sub ($self, $message) {
          ...
      },
  );

C<$message> is one complete framed application message.

Linux::Event retains incomplete input until enough bytes arrive to form a
complete message.

One kernel read may produce:

=over 4

=item *

no complete messages

=item *

one complete message

=item *

many complete messages

=back

Application code does not need to reconstruct frames across read boundaries.

=head1 SENDING MESSAGES

For a framed resource:

  $self->send($payload);

applies that class's outbound framing rule.

For example:

  Delimiter
      payload + delimiter

  LengthPrefix
      encoded length + payload

  Netstring
      decimal length + ":" + payload + ","

C<write> remains the raw-byte operation:

  $self->write($bytes);

C<write> does not apply framing.

This distinction is useful for protocol handshakes, debugging, or cases where
the application intentionally needs direct wire control.

=head1 RAW INPUT WITHOUT A FRAMER

A readable ordered-byte object does not have to use a built-in framer.

Without a framer, use C<on_data>:

  my $buffer = '';

  my $stream = Linux::Event::IO::Sock::Stream->new(
      fh => $fh,

      on_data => sub ($self, $bytes) {
          $buffer .= $bytes;

          while (my $record = extract_record(\$buffer)) {
              process_record($record);
          }
      },
  );

C<on_data> receives read chunks, not application messages.

A chunk may contain:

=over 4

=item *

part of one protocol message

=item *

exactly one message

=item *

several messages

=back

The application parser must retain partial state itself.

Use raw mode when the protocol does not match a built-in framing family.

=head1 FRAME SIZE LIMITS

For untrusted input, use C<max_frame> where the chosen framer supports it.

For example:

  use Linux::Event::Framer 'U32BE',
      max_frame => 1_048_576;

This prevents a peer from declaring an unexpectedly large application frame.

The ordered-byte resource also has its independent C<max_buffer> input-storage
limit.

C<max_frame> and C<max_buffer> solve different problems:

=over 4

=item C<max_frame>

Maximum allowed protocol message payload.

=item C<max_buffer>

Maximum allowed ordered-byte input storage.

=back

A framing violation produces a L<Linux::Event::Error> with type C<framing> and
closes through the normal ordered-byte error lifecycle.

=head1 MESSAGE BATCHING

Ordinary framed delivery calls:

  on_message($self, $message)

once for each complete message.

A high-throughput pipelined protocol may instead explicitly enable message
batching through the ordered-byte class tuning:

  sub stream_tuning ($class) {
      return message_batch_size => 32;
  }

and receive:

  sub on_messages ($self, $messages) {
      process_message($self, $_) for @$messages;
  }

C<$messages> is an array reference of complete framed messages.

C<on_message> and C<on_messages> are mutually exclusive for one effective
descriptor.

A positive C<message_batch_size> requires C<on_messages>.

Batching changes callback delivery shape.

It does B<not> change the wire format.

Linux::Event does not wait for a later readiness event merely to fill a batch.
A partial batch is flushed when the current native read drain finishes.

=head1 INHERITANCE

A subclass inherits the nearest framer declaration in its Perl inheritance
chain.

For example:

  package MessageStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'U32BE';

  package LoggedMessageStream;

  use parent 'MessageStream';

  sub on_message ($self, $message) {
      log_message($message);
  }

C<LoggedMessageStream> still uses U32BE framing.

A concrete class has one effective framing policy.

A class cannot combine framed delivery with raw C<on_data> delivery.

=head1 CHANGING PROTOCOLS

Some protocols change their wire format after a handshake.

Linux::Event supports changing between loaded ordered-byte subclasses with
C<transition_to>.

For example:

  $self->transition_to('BinaryProtocol');

The underlying Linux resource does not change.

A stream socket remains the same connected socket.

Only the protocol descriptor changes.

Unread native input is preserved and interpreted using the target class's
policy.

This is useful for transitions such as:

  negotiation protocol
      ->
  framed binary protocol

or higher-level protocol upgrades implemented above the reactor.

Queued output that already exists is not reframed.

Future C<send> calls use the new target framing rule.

See the ordered-byte resource documentation for the complete
C<transition_to> contract.

=head1 FRAMER NAMES

The declaration:

  use Linux::Event::Framer 'Delimiter', "\n";

loads:

  Linux::Event::Framer::Delimiter

The name is case-sensitive.

There is no separate alias table.

A misspelled or unknown framer name fails while the class is being compiled.

=head1 THERE IS NO PER-CONNECTION FRAMER OBJECT

A declaration such as:

  use Linux::Event::Framer 'Delimiter', "\n";

records immutable class-level framing configuration.

Linux::Event does not perform:

  my $framer = Delimiter->new(...);

for every connection.

Per-object state still exists where required, such as:

=over 4

=item *

partial input bytes

=item *

current length-prefix parser progress

=item *

output queues

=item *

lifecycle state

=back

but the framing definition itself is shared class policy.

This avoids unnecessary Perl objects and repeated dynamic dispatch in the
message path.

=head1 NATIVE CONSUMERS

This section is for XS extension authors.

Most application code should not use this interface.

A native extension may register a consumer for an ordered-byte subclass:

  Linux::Event::Framer->declare_native_consumer(
      'My::ProtocolStream',
      {
          provider           => $provider,
          abi_version        => $abi_version,
          operations_address => $native_table_address,
      },
  );

Native consumers can integrate protocol parsers that should consume input
before ordinary Perl message callbacks.

Depending on the provider contract, they may receive complete framed messages
or use the raw native-input ABI to inspect the ordered-byte input buffer
directly before those bytes are converted into Perl scalars.

This is the extension boundary used for specialized high-performance protocol
engines.

It is not a second public Perl framing API.

See F<docs/ORDERED-BYTE-CONSUMER-ABI.md> for the ABI and provider-lifetime
contract.

=head1 PERFORMANCE MODEL

Built-in inbound framing runs in native code.

Linux::Event keeps parser configuration as cached class policy and maintains
only changing parser state per resource.

Complete messages cross into Perl only when semantic application delivery is
required.

Outbound C<send> applies the selected built-in framing rule and places the
resulting bytes into the normal native write queue.

Optional message batching can reduce Perl callback crossings further for
suitable pipelined protocols.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>,
L<Linux::Event::Framer::Delimiter>,
L<Linux::Event::Framer::Fixed>,
L<Linux::Event::Framer::LengthPrefix>,
L<Linux::Event::Framer::U32BE>,
L<Linux::Event::Framer::Netstring>,
L<Linux::Event::Framer::Varint>,
L<Linux::Event::Framer::DecimalLength>,
F<docs/FRAMING.md>,
F<docs/CHOOSING-A-FRAMER.md>.

=cut
