package Linux::Event::Framer::LengthPrefix;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, @args) {
    croak 'LengthPrefix options must be key/value pairs' if @args % 2;
    my %opt = @args;
    my $bytes = delete $opt{bytes} // 4;
    croak 'bytes must be 1, 2, or 4'
        if $bytes != 1 && $bytes != 2 && $bytes != 4;
    my $endian = delete $opt{endian} // 'big';
    croak 'endian must be big or little'
        if $endian ne 'big' && $endian ne 'little';
    my $include_prefix = delete $opt{include_prefix} // 0;
    my $max_frame = delete $opt{max_frame};
    croak 'max_frame must be a non-negative integer'
        if defined($max_frame) && ($max_frame !~ /\A\d+\z/ || $max_frame < 0);
    croak 'unknown LengthPrefix options: ' . join(', ', sort keys %opt) if %opt;

    my $little = $endian eq 'little' ? 1 : 0;
    my $template = $bytes == 1 ? 'C'
        : $bytes == 2 ? ($little ? 'v' : 'n')
        :               ($little ? 'V' : 'N');
    my $native = {
        read_mode       => 4,
        prefix_bytes    => 0 + $bytes,
        prefix_little   => $little,
        include_prefix  => $include_prefix ? 1 : 0,
        max_frame       => $max_frame,
        prefix_template => $template,
        prefix_max      => $bytes == 1 ? 0xff
            : $bytes == 2 ? 0xffff : 0xffff_ffff,
    };
    return { native => $native, frame => \&_frame };
}

sub _frame ($config, $payload) {
    $payload = '' if !defined $payload;
    my $length = bytes::length($payload);
    my $max = $config->{prefix_max};
    croak "send(): payload length $length exceeds prefix capacity $max"
        if $length > $max;
    croak "send(): payload length $length exceeds max_frame=$config->{max_frame}"
        if defined($config->{max_frame}) && $length > $config->{max_frame};

    return pack($config->{prefix_template}, $length) . $payload;
}

1;

__END__

=head1 NAME

Linux::Event::Framer::LengthPrefix - Frame messages with a binary payload length

=head1 SYNOPSIS

  package MessageStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'LengthPrefix',
      bytes     => 2,
      endian    => 'big',
      max_frame => 1_048_576;

  sub on_message ($self, $message) {
      say "received " . length($message) . " bytes";
  }

=head1 DESCRIPTION

C<Linux::Event::Framer::LengthPrefix> is for protocols where every payload is
preceded by a fixed-width unsigned binary length.

For example, with:

  use Linux::Event::Framer 'LengthPrefix',
      bytes  => 2,
      endian => 'big';

the payload:

  ABC

is sent on the wire as:

  00 03 41 42 43

where:

  00 03

is the two-byte big-endian integer C<3>, followed by the three payload bytes.

The encoded number is the B<payload length>.

It does not include the size of the prefix itself.

=head1 DECLARING THE FRAMER

A typical declaration is:

  package MessageStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'LengthPrefix',
      bytes  => 4,
      endian => 'big';

The same framing policy can also be used by ordered-byte Pipe and TTY
subclasses.

=head1 PREFIX WIDTH

=head2 bytes

C<bytes> selects the binary prefix width.

Allowed values are:

  1
  2
  4

The default is:

  4

For example:

  use Linux::Event::Framer 'LengthPrefix',
      bytes => 1;

uses one unsigned byte for the payload length.

=head1 PREFIX CAPACITY

The chosen width places a hard mathematical limit on the payload length that
can be represented.

The maximum payload lengths are:

  bytes => 1      255
  bytes => 2      65_535
  bytes => 4      4_294_967_295

C<send> rejects a payload larger than the selected prefix can represent.

For example, with:

  bytes => 1

this is valid:

  $self->send('x' x 255);

but this is not:

  $self->send('x' x 256);

This prefix-capacity limit exists even when no C<max_frame> option is supplied.

=head1 BYTE ORDER

=head2 endian

C<endian> controls byte order for two- and four-byte prefixes.

Allowed values are:

  big
  little

The default is:

  big

For example, the payload length C<3> with a two-byte prefix becomes:

  big endian:     00 03
  little endian:  03 00

A one-byte prefix has no meaningful byte-order difference, but the same option
validation still applies.

=head1 RECEIVING

Linux::Event first waits until the complete binary prefix is available.

It decodes the payload length, then waits until that many payload bytes are
available.

For example, with:

  bytes => 2

Linux might receive:

  first read:   00
  second read:  05 48 45
  third read:   4c 4c 4f

Linux::Event still delivers one complete message:

  HELLO

The application does not need to preserve partial prefixes or partial payloads
itself.

=head1 MULTIPLE MESSAGES MAY ARRIVE AT ONCE

One kernel read may contain several complete length-prefixed messages.

For example, a one-byte prefix stream containing:

  03foo03bar03baz

produces three messages:

  foo
  bar
  baz

Read boundaries do not affect the protocol boundaries.

=head1 ZERO-LENGTH MESSAGES

A payload length of zero is valid.

For example, with a one-byte prefix:

  00

represents one empty message.

Likewise:

  $self->send('');

produces a zero-length prefix followed by no payload bytes.

The exact prefix width and byte order still follow the class declaration.

=head1 INCLUDING THE PREFIX IN INBOUND MESSAGES

=head2 include_prefix

By default, C<on_message> receives only the payload:

  use Linux::Event::Framer 'LengthPrefix',
      bytes => 2;

Wire bytes:

  00 03 41 42 43

produce a message containing:

  ABC

To include the binary prefix itself in the delivered message:

  use Linux::Event::Framer 'LengthPrefix',
      bytes          => 2,
      include_prefix => 1;

the callback instead receives the complete frame bytes:

  00 03 41 42 43

C<include_prefix> affects inbound delivery only.

The prefix is always consumed from the underlying ordered-byte input.

=head1 LIMITING PAYLOAD SIZE

=head2 max_frame

C<max_frame> provides an application-level payload limit:

  use Linux::Event::Framer 'LengthPrefix',
      bytes     => 4,
      max_frame => 1_048_576;

If an inbound prefix declares a payload larger than C<max_frame>, Linux::Event
reports a framing error rather than buffering the declared payload.

C<send> also rejects an outbound payload larger than C<max_frame>.

C<max_frame> must be a non-negative integer.

=head1 PREFIX CAPACITY AND MAX_FRAME ARE DIFFERENT

There are two independent limits.

For example:

  use Linux::Event::Framer 'LengthPrefix',
      bytes     => 2,
      max_frame => 4096;

has:

  protocol capacity:  65_535 bytes
  application limit:   4_096 bytes

Even though the two-byte prefix can represent values up to 65,535, this class
accepts only payloads of at most 4,096 bytes.

Conversely:

  use Linux::Event::Framer 'LengthPrefix',
      bytes => 1;

can never send more than 255 payload bytes even without C<max_frame>.

The effective outbound limit is therefore whichever restriction is smaller.

=head1 SENDING

C<send> automatically encodes the payload length and prepends it.

For example:

  use Linux::Event::Framer 'LengthPrefix',
      bytes  => 2,
      endian => 'big';

  $self->send("abc");

writes:

  00 03 61 62 63

The application supplies only the payload.

It should not manually add the length prefix before calling C<send>.

=head1 RAW WRITE

C<write> bypasses the framer:

  $self->write($bytes);

It writes exactly the supplied bytes.

For example:

  $self->write("\x00\x03abc");

can be used when the application intentionally wants direct control over the
wire representation.

Normally, C<send> is preferable because it guarantees that the prefix matches
the payload length.

=head1 INCLUDE_PREFIX DOES NOT CHANGE SENDING

C<include_prefix> controls inbound callback delivery only.

For example:

  use Linux::Event::Framer 'LengthPrefix',
      bytes          => 2,
      include_prefix => 1;

still means:

  $self->send("abc");

produces:

  00 03 61 62 63

C<send> does not expect the application to include the prefix itself.

=head1 BYTE LENGTH, NOT CHARACTER COUNT

The prefix describes payload bytes.

Linux::Event therefore calculates the outbound length using byte length.

LengthPrefix framing does not define a character encoding.

If an application wants to send text, it is responsible for encoding that text
into the protocol's required byte representation before calling C<send>.

=head1 WHEN TO USE LENGTHPREFIX

LengthPrefix is appropriate when the protocol explicitly uses a one-, two-, or
four-byte unsigned binary payload length.

It is especially useful for binary protocols where messages may contain any
byte value and therefore cannot safely rely on a delimiter.

If every record has one constant size, C<Fixed> is simpler.

If the protocol specifically uses a four-byte network-order length, C<U32BE> is
a shorter declaration of the same wire format.

=head1 RELATIONSHIP TO U32BE

This declaration:

  use Linux::Event::Framer 'LengthPrefix',
      bytes  => 4,
      endian => 'big';

has the same wire representation as:

  use Linux::Event::Framer 'U32BE';

C<U32BE> exists as a convenience for that common protocol form.

=head1 ERROR BEHAVIOR

An inbound payload length greater than C<max_frame> produces the normal
ordered-byte framing error.

Outbound C<send> rejects payloads that exceed either:

=over 4

=item *

the selected prefix capacity

=item *

the configured C<max_frame>

=back

These are application-visible framing failures rather than silent truncation.

=head1 PERFORMANCE MODEL

Inbound prefix decoding and frame boundary detection run in Linux::Event's
native ordered-byte parser.

Partial prefixes and partial payloads remain in native storage until a complete
message is available.

The prefix width and byte order are resolved as immutable class framing policy
rather than recalculated as dynamic protocol configuration for every message.

Outbound C<send> calculates the payload byte length, encodes the configured
binary prefix, and passes the resulting frame to the ordinary native write
path.

=head1 SEE ALSO

L<Linux::Event::Framer>,
L<Linux::Event::Framer::U32BE>,
L<Linux::Event::Framer::Fixed>,
L<Linux::Event::Framer::Delimiter>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>,
F<docs/FRAMING.md>,
F<docs/CHOOSING-A-FRAMER.md>.

=cut
