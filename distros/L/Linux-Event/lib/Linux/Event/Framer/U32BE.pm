package Linux::Event::Framer::U32BE;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use Linux::Event::Framer::LengthPrefix ();

sub _build_definition ($class, @args) {
    croak 'U32BE options must be key/value pairs' if @args % 2;
    my %opt = @args;
    croak 'bytes is fixed at 4 for U32BE' if exists $opt{bytes};
    croak 'endian is fixed at big for U32BE' if exists $opt{endian};
    return Linux::Event::Framer::LengthPrefix->_build_definition(
        %opt, bytes => 4, endian => 'big'
    );
}

1;

__END__

=head1 NAME

Linux::Event::Framer::U32BE - Frame messages with a 32-bit big-endian payload length

=head1 SYNOPSIS

  package MessageStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'U32BE',
      max_frame => 16 * 1024 * 1024;

  sub on_message ($self, $message) {
      ...
  }

=head1 DESCRIPTION

C<Linux::Event::Framer::U32BE> is a convenience framer for a very common binary
message format:

  4-byte unsigned big-endian payload length
  followed by
  payload bytes

For example, sending:

  ABC

produces these wire bytes:

  00 00 00 03 41 42 43

The four-byte prefix contains the payload length C<3> in network byte order.

=head1 EQUIVALENT LENGTHPREFIX DECLARATION

C<U32BE> is exactly the convenient form of:

  use Linux::Event::Framer 'LengthPrefix',
      bytes  => 4,
      endian => 'big';

These two declarations use the same wire format.

Use C<U32BE> when the protocol always uses this particular prefix format.

Use L<Linux::Event::Framer::LengthPrefix> when the prefix width or byte order
needs to vary.

=head1 WIDTH AND BYTE ORDER ARE FIXED

U32BE always means:

  bytes  => 4
  endian => 'big'

These options cannot be overridden.

For example, these are invalid:

  use Linux::Event::Framer 'U32BE',
      bytes => 2;

and:

  use Linux::Event::Framer 'U32BE',
      endian => 'little';

If the protocol requires either of those formats, use C<LengthPrefix> instead.

=head1 RECEIVING

Linux::Event waits until all four prefix bytes are available, decodes the
unsigned big-endian payload length, then waits for that many payload bytes.

For example, Linux might receive:

  first read:   00 00
  second read:  00 05 48 45
  third read:   4c 4c 4f

Linux::Event still delivers exactly one message:

  HELLO

Partial prefix and payload bytes are retained automatically.

=head1 MULTIPLE MESSAGES MAY ARRIVE AT ONCE

One kernel read may contain several complete U32BE frames.

For example:

  00 00 00 03 foo
  00 00 00 03 bar
  00 00 00 03 baz

produces three messages:

  foo
  bar
  baz

Kernel read boundaries do not determine message boundaries.

=head1 ZERO-LENGTH MESSAGES

A four-byte zero prefix:

  00 00 00 00

represents one empty message.

Likewise:

  $self->send('');

produces exactly that four-byte prefix and no payload bytes.

=head1 INCLUDING THE PREFIX

=head2 include_prefix

By default, C<on_message> receives only the payload.

For example:

  use Linux::Event::Framer 'U32BE';

wire bytes:

  00 00 00 03 41 42 43

produce:

  ABC

To include the four-byte prefix in the inbound message:

  use Linux::Event::Framer 'U32BE',
      include_prefix => 1;

the callback receives all seven bytes:

  00 00 00 03 41 42 43

C<include_prefix> affects inbound delivery only.

=head1 LIMITING PAYLOAD SIZE

=head2 max_frame

The four-byte prefix can theoretically represent payload lengths through:

  4_294_967_295

bytes.

Applications will normally want a much smaller practical limit.

For example:

  use Linux::Event::Framer 'U32BE',
      max_frame => 16 * 1024 * 1024;

limits messages to 16 MiB.

If an inbound prefix declares a payload larger than C<max_frame>, Linux::Event
reports a framing error instead of accepting the frame.

C<send> also rejects payloads larger than C<max_frame>.

=head1 SENDING

C<send> calculates the payload byte length and prepends the four-byte big-endian
prefix automatically.

For example:

  $self->send("hello");

writes:

  00 00 00 05 68 65 6c 6c 6f

The application supplies only the payload.

=head1 RAW WRITE

C<write> bypasses framing:

  $self->write($bytes);

For example:

  $self->write("\x00\x00\x00\x03abc");

writes those bytes exactly as supplied.

Ordinary protocol output should normally use C<send> so Linux::Event generates
the correct length automatically.

=head1 INCLUDE_PREFIX DOES NOT CHANGE SENDING

C<include_prefix> affects only inbound callback delivery.

Even with:

  include_prefix => 1

this:

  $self->send("abc");

still produces:

  00 00 00 03 61 62 63

The application should not prepend the length itself before calling C<send>.

=head1 BYTE LENGTH

The prefix represents payload bytes.

U32BE framing does not know or care whether those bytes contain text, encoded
objects, compressed data, or arbitrary binary content.

Applications are responsible for any character encoding or serialization that
exists above the framing layer.

=head1 WHEN TO USE U32BE

Use U32BE when the protocol specifies a four-byte unsigned network-order payload
length.

It is a good fit for many binary protocols because:

=over 4

=item *

the message boundary is explicit

=item *

payloads may contain arbitrary byte values

=item *

the format is easy to generate and parse

=item *

network byte order is widely used across binary protocols

=back

If the protocol uses a different binary prefix width or little-endian encoding,
use C<LengthPrefix> instead.

=head1 ERROR BEHAVIOR

Inbound messages larger than C<max_frame> produce the normal ordered-byte
framing error.

The resulting L<Linux::Event::Error> has type:

  framing

Outbound C<send> rejects payloads that exceed C<max_frame> or the fixed
four-byte unsigned prefix capacity.

Linux::Event does not silently truncate payloads or length values.

=head1 PERFORMANCE MODEL

U32BE uses the same native length-prefix parser as C<LengthPrefix>, with its
width and byte order resolved permanently as:

  4-byte
  big-endian

Partial prefixes and payloads remain in native ordered-byte storage until a
complete message is available.

Outbound C<send> encodes one network-order 32-bit payload length and then places
the resulting frame into the normal native write path.

=head1 SEE ALSO

L<Linux::Event::Framer>,
L<Linux::Event::Framer::LengthPrefix>,
L<Linux::Event::Framer::Fixed>,
L<Linux::Event::Framer::Delimiter>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>,
F<docs/FRAMING.md>,
F<docs/CHOOSING-A-FRAMER.md>.

=cut
