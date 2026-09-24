package Linux::Event::Framer::Varint;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, @args) {
    croak 'Varint options must be key/value pairs' if @args % 2;
    my %opt = @args;
    my $include_prefix = delete $opt{include_prefix} // 0;
    my $max_frame = delete $opt{max_frame};
    croak 'max_frame must be a non-negative integer'
        if defined($max_frame) && ($max_frame !~ /\A\d+\z/ || $max_frame < 0);
    croak 'unknown Varint options: ' . join(', ', sort keys %opt) if %opt;

    my $native = {
        read_mode      => 6,
        include_prefix => $include_prefix ? 1 : 0,
        max_frame      => $max_frame,
    };
    return { native => $native, frame => \&_frame };
}

sub _frame ($config, $payload) {
    $payload = '' if !defined $payload;
    my $length = bytes::length($payload);
    croak "send(): payload length $length exceeds max_frame=$config->{max_frame}"
        if defined($config->{max_frame}) && $length > $config->{max_frame};

    return pack('C', $length) . $payload if $length < 128;

    my @octets;
    my $value = $length;
    do {
        my $byte = $value & 0x7f;
        $value >>= 7;
        $byte |= 0x80 if $value;
        push @octets, $byte;
    } while ($value);
    return pack('C*', @octets) . $payload;
}

1;

__END__

=head1 NAME

Linux::Event::Framer::Varint - Frame messages with an unsigned LEB128 payload length

=head1 SYNOPSIS

  package CompactStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Varint',
      max_frame => 1_048_576;

  sub on_message ($self, $message) {
      ...
  }

=head1 DESCRIPTION

C<Linux::Event::Framer::Varint> prefixes every message with its payload length
encoded as canonical unsigned LEB128.

Small lengths use fewer prefix bytes.

For example:

  payload length 0      prefix 00
  payload length 1      prefix 01
  payload length 127    prefix 7f
  payload length 128    prefix 80 01

The encoded number is the payload length in bytes.

The payload follows immediately after the variable-width prefix.

=head1 WHAT IS LEB128?

LEB128 stores an integer in groups of seven data bits.

The high bit of each prefix byte indicates whether another prefix byte follows.

For example, decimal C<128> is encoded as:

  80 01

The first byte has its continuation bit set, so the parser knows another prefix
byte follows.

The second byte completes the length.

Applications normally do not need to encode or decode this themselves.
C<send> and the native inbound parser handle it automatically.

=head1 DECLARING THE FRAMER

Declare Varint after the ordered-byte parent class:

  package CompactStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Varint';

The same framing policy can also be used with ordered-byte Pipe and TTY
subclasses.

=head1 RECEIVING

Linux::Event reads enough prefix bytes to decode one canonical unsigned LEB128
length.

It then waits until the declared number of payload bytes are available.

For example, a 128-byte payload begins with:

  80 01

If Linux receives:

  first read:   80
  second read:  01 <some payload bytes>
  later reads: <remaining payload bytes>

the message is not delivered until all 128 payload bytes are present.

The application does not need to preserve partial prefix or payload state.

=head1 VARIABLE PREFIX WIDTH

Unlike C<LengthPrefix>, the number of prefix bytes is not fixed.

Smaller values require less wire space.

For example:

  5       05
  127     7f
  128     80 01
  256     80 02
  16_383  ff 7f
  16_384  80 80 01

This makes Varint useful for protocols where small messages are common and a
fixed four-byte length prefix would be unnecessarily large.

=head1 ZERO-LENGTH MESSAGES

The canonical encoding of zero is one byte:

  00

Therefore:

  $self->send('');

produces:

  00

with no payload bytes following it.

Inbound C<00> likewise represents one empty message.

=head1 CANONICAL ENCODING

Linux::Event accepts only the canonical unsigned LEB128 representation of a
length.

For example, zero must be encoded as:

  00

An overlong representation such as:

  80 00

is rejected even though it could mathematically decode to the same numeric
value.

This gives every payload length one normal wire representation.

=head1 PREFIX LENGTH AND OVERFLOW

Linux::Event bounds the Varint prefix parser.

The native parser accepts an unsigned LEB128 wire value of at most 64 bits and
uses no more than ten prefix bytes.

Malformed prefixes that:

=over 4

=item *

continue for too many bytes

=item *

overflow the supported unsigned value

=item *

exceed the native Perl unsigned integer range

=item *

use a noncanonical overlong representation

=back

are rejected as framing errors.

The parser does not continue consuming an arbitrary number of continuation
bytes.

=head1 INCLUDING THE PREFIX

=head2 include_prefix

By default, C<on_message> receives only the payload.

For example, a 128-byte payload beginning on the wire with:

  80 01

is delivered as exactly those 128 payload bytes.

To include the encoded Varint prefix in the inbound message:

  use Linux::Event::Framer 'Varint',
      include_prefix => 1;

the callback receives:

  prefix bytes + payload bytes

For a 128-byte payload, the delivered message therefore begins with:

  80 01

and has a total size of 130 bytes.

C<include_prefix> affects inbound delivery only.

=head1 LIMITING PAYLOAD SIZE

=head2 max_frame

An optional C<max_frame> limits the decoded payload length:

  use Linux::Event::Framer 'Varint',
      max_frame => 1_048_576;

When the prefix has been decoded, Linux::Event checks the declared payload
length immediately.

If it exceeds C<max_frame>, a framing error is reported without waiting for the
oversized payload to arrive.

C<send> also rejects payloads larger than C<max_frame>.

C<max_frame> must be a non-negative integer.

=head1 MAX_FRAME AND MAX_BUFFER

C<max_frame> limits the protocol payload.

The ordered-byte resource's C<max_buffer> separately limits native input
storage.

A complete Varint frame includes:

  variable-width prefix
  payload

so the resource buffer limit also protects the complete framed representation.

=head1 SENDING

C<send> calculates the payload byte length and prepends its canonical unsigned
LEB128 encoding.

For example:

  $self->send('x' x 127);

starts the wire frame with:

  7f

while:

  $self->send('x' x 128);

starts it with:

  80 01

The application supplies only the payload.

=head1 RAW WRITE

C<write> bypasses framing:

  $self->write($bytes);

For example:

  $self->write("\x80\x01" . ('x' x 128));

writes that exact wire representation.

Ordinary Varint protocol output should normally use C<send> so the length prefix
is guaranteed to match the payload.

=head1 INCLUDE_PREFIX DOES NOT CHANGE SENDING

C<include_prefix> affects only inbound delivery.

For example:

  use Linux::Event::Framer 'Varint',
      include_prefix => 1;

still means:

  $self->send('x' x 128);

creates:

  80 01 <128 payload bytes>

The application should not prepend the Varint itself before calling C<send>.

=head1 BYTE LENGTH, NOT CHARACTER COUNT

The Varint represents payload bytes.

This framer does not define text encoding or serialization.

If the application sends text, it is responsible for converting that text into
the protocol's intended byte encoding before calling C<send>.

=head1 MULTIPLE MESSAGES MAY ARRIVE AT ONCE

One kernel read may contain several complete Varint-framed messages.

For example, conceptually:

  <length><payload><length><payload><length><payload>

can produce several consecutive C<on_message> callbacks from one native input
drain.

Kernel read boundaries do not become application message boundaries.

=head1 MALFORMED INPUT

Linux::Event rejects malformed Varint prefixes rather than attempting to repair
them.

Examples include:

=over 4

=item *

an overlong encoding such as C<80 00> for zero

=item *

a prefix that continues beyond the supported maximum width

=item *

a numeric overflow

=item *

a decoded length larger than C<max_frame>

=item *

a complete frame that violates the ordered-byte buffer limit

=back

These use the normal ordered-byte framing error path.

=head1 ERROR BEHAVIOR

Malformed or oversized inbound framing produces a
L<Linux::Event::Error> with type:

  framing

The resource then follows its ordinary framing-error lifecycle.

Outbound C<send> rejects a payload that violates C<max_frame> rather than
emitting an invalid frame.

=head1 WHEN TO USE VARINT

Varint framing is useful when:

=over 4

=item *

the protocol specifies unsigned LEB128 lengths

=item *

message sizes vary substantially

=item *

small messages are common

=item *

saving prefix bytes on small messages is useful

=item *

payload contents must remain binary-safe

=back

If the protocol uses a fixed one-, two-, or four-byte integer length instead,
use L<Linux::Event::Framer::LengthPrefix>.

If it specifically uses a four-byte network-order length, use
L<Linux::Event::Framer::U32BE>.

=head1 PERFORMANCE MODEL

Inbound Varint decoding runs in Linux::Event's native ordered-byte parser.

The parser maintains partial prefix and payload state without repeatedly
crossing into Perl.

Canonical-form validation, overflow checks, C<max_frame> enforcement, and frame
boundary detection happen before semantic message delivery.

Outbound C<send> has a one-byte fast path for payload lengths below 128 and
generates additional LEB128 bytes only when required.

=head1 SEE ALSO

L<Linux::Event::Framer>,
L<Linux::Event::Framer::LengthPrefix>,
L<Linux::Event::Framer::U32BE>,
L<Linux::Event::Framer::Netstring>,
L<Linux::Event::Framer::DecimalLength>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>,
F<docs/FRAMING.md>,
F<docs/CHOOSING-A-FRAMER.md>.

=cut
