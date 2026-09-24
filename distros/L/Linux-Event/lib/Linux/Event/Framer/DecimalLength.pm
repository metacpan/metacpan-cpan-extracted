package Linux::Event::Framer::DecimalLength;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, @args) {
    croak 'DecimalLength options must be key/value pairs' if @args % 2;
    my %opt = @args;
    my $separator = delete $opt{separator} // ' ';
    croak 'separator must be exactly one byte'
        if bytes::length($separator) != 1;
    croak 'separator must not be an ASCII digit' if $separator =~ /[0-9]/;
    my $include_prefix = delete $opt{include_prefix} // 0;
    my $max_frame = delete $opt{max_frame};
    croak 'max_frame must be a non-negative integer'
        if defined($max_frame) && ($max_frame !~ /\A\d+\z/ || $max_frame < 0);
    croak 'unknown DecimalLength options: ' . join(', ', sort keys %opt) if %opt;

    my $native = {
        read_mode      => 7,
        delimiter      => $separator,
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
    return $length . $config->{delimiter} . $payload;
}

1;

__END__

=head1 NAME

Linux::Event::Framer::DecimalLength - Frame messages with an ASCII decimal payload length

=head1 SYNOPSIS

  package SyslogStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'DecimalLength',
      separator => ' ',
      max_frame => 1_048_576;

  sub on_message ($self, $message) {
      ...
  }

=head1 DESCRIPTION

C<Linux::Event::Framer::DecimalLength> prefixes each payload with its byte
length written as ASCII decimal digits, followed by one separator byte.

The default separator is a space.

For example, the payload:

  HELLO

is sent as:

  5 HELLO

The C<5> says that five payload bytes follow.

This is the framing style used by RFC 6587 octet-counted syslog when the
default space separator is used.

=head1 WIRE FORMAT

The wire format is:

  decimal length
  separator
  payload

For example:

  3 abc

contains:

  length       3
  separator    space
  payload      abc

There is no trailing delimiter.

The declared length tells Linux::Event exactly where the payload ends.

=head1 DECLARING THE FRAMER

A typical declaration is:

  package SyslogStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'DecimalLength';

This uses the default separator:

  ' '

A different separator can be selected:

  use Linux::Event::Framer 'DecimalLength',
      separator => '|';

Then:

  $self->send("abc");

produces:

  3|abc

=head1 THE SEPARATOR

=head2 separator

The separator must be exactly one byte.

The default is:

  separator => ' '

The separator cannot be an ASCII digit because the parser must be able to tell
where the decimal length ends.

For example, this is valid:

  separator => '|'

but this is not:

  separator => '7'

and neither is this:

  separator => '::'

The separator is protocol syntax.

It is not part of the payload length.

=head1 RECEIVING

Linux::Event reads decimal digits until it reaches the configured separator.

It decodes that number as the payload length, then waits for exactly that many
payload bytes.

For example, with the default separator:

  5 HELLO

delivers:

  HELLO

to C<on_message>.

The length digits and separator are removed from ordinary inbound delivery.

=head1 READ BOUNDARIES DO NOT MATTER

The decimal prefix or payload may be split across kernel reads.

For example:

  first read:   12
  second read:  8 <some payload bytes>
  later reads: <remaining payload bytes>

still forms one message whose payload length is 128 bytes.

Linux::Event retains partial framing state until the complete payload is
available.

Application code does not need to reconstruct the prefix or payload itself.

=head1 MULTIPLE MESSAGES MAY ARRIVE AT ONCE

One kernel read may contain several complete DecimalLength frames.

For example:

  3 one3 two5 three

with a space separator represents three messages:

  one
  two
  three

The parser uses each declared byte length to find the next message boundary.

Kernel read boundaries do not become protocol boundaries.

=head1 ZERO-LENGTH MESSAGES

The canonical representation of an empty payload with the default separator is:

  0 

That is:

  digit zero
  followed by one space
  followed by no payload bytes

Therefore:

  $self->send('');

produces exactly:

  0 

With:

  separator => '|'

the empty frame is:

  0|

=head1 CANONICAL DECIMAL LENGTHS

Linux::Event requires the length field to use canonical ASCII decimal form.

For example:

  5 HELLO

is valid.

A longer decimal value may not begin with zero.

For example:

  05 HELLO

is rejected.

The canonical spelling is:

  5 HELLO

Zero itself is valid and is written simply as:

  0

This gives each payload length one normal textual representation.

=head1 AT LEAST ONE DIGIT IS REQUIRED

The separator cannot appear before any decimal length digits.

For example, with a space separator:

   hello

is not a valid DecimalLength frame.

A valid frame must begin with at least one ASCII decimal digit.

=head1 LENGTH PARSING IS BOUNDED

Linux::Event does not scan an unlimited number of decimal digits looking for a
separator.

The native parser bounds the length field and checks for numeric overflow.

An excessively long, overflowing, or otherwise malformed decimal length is
reported as a framing error.

=head1 INCLUDING THE PREFIX

=head2 include_prefix

By default, the callback receives only the payload.

For example:

  use Linux::Event::Framer 'DecimalLength',
      separator => '|';

wire input:

  5|hello

delivers:

  hello

To include the decimal length and separator:

  use Linux::Event::Framer 'DecimalLength',
      separator      => '|',
      include_prefix => 1;

the callback instead receives:

  5|hello

C<include_prefix> therefore includes both:

  decimal length digits
  separator byte

along with the payload.

It affects inbound delivery only.

=head1 LIMITING PAYLOAD SIZE

=head2 max_frame

An optional C<max_frame> limits the decoded payload length:

  use Linux::Event::Framer 'DecimalLength',
      max_frame => 1_048_576;

As soon as the decimal length and separator have been parsed, Linux::Event
checks the declared payload length.

If it exceeds C<max_frame>, a framing error is reported without waiting for the
oversized payload to arrive.

C<send> also rejects payloads larger than C<max_frame>.

C<max_frame> must be a non-negative integer.

=head1 MAX_FRAME AND MAX_BUFFER

C<max_frame> limits payload bytes.

The ordered-byte resource's C<max_buffer> separately limits native input
storage.

A DecimalLength frame occupies:

  decimal length digits
  separator byte
  payload bytes

so the complete framed representation must also fit within the resource's input
buffer policy.

=head1 SENDING

C<send> creates the decimal prefix automatically.

For example:

  $self->send("HELLO");

with the default separator writes:

  5 HELLO

With:

  separator => '|'

the same payload becomes:

  5|HELLO

The application supplies only the payload.

Linux::Event calculates its byte length and emits the canonical decimal form.

=head1 RAW WRITE

C<write> bypasses framing:

  $self->write($bytes);

For example:

  $self->write("5 HELLO");

writes those exact bytes.

Ordinary DecimalLength protocol output should normally use C<send> so the
declared length cannot accidentally disagree with the payload.

=head1 INCLUDE_PREFIX DOES NOT CHANGE SENDING

C<include_prefix> affects inbound delivery only.

For example:

  use Linux::Event::Framer 'DecimalLength',
      include_prefix => 1;

still means:

  $self->send("HELLO");

writes:

  5 HELLO

The application should not prepend the decimal length itself before calling
C<send>.

=head1 BYTE LENGTH, NOT CHARACTER COUNT

The decimal number represents payload bytes.

DecimalLength framing does not define a character encoding.

If an application sends text, it must first encode that text into the bytes
required by the protocol.

Linux::Event then measures those bytes when constructing the length prefix.

=head1 PAYLOAD CONTENT

The payload may contain arbitrary bytes, including the configured separator.

For example, with a space separator, the payload itself may contain spaces.

The parser does not search the payload for another separator.

Once the length is known, exactly that many bytes belong to the payload.

=head1 NO TRAILING TERMINATOR

Unlike Netstring framing, DecimalLength does not require a trailing comma or
other terminator.

For example:

  5 HELLO

is already a complete frame.

The payload length alone tells Linux::Event where the next message begins.

This distinction is important:

  Netstring
      5:HELLO,

  DecimalLength
      5 HELLO

Both use textual lengths, but they are different wire protocols.

=head1 MALFORMED INPUT

Linux::Event rejects malformed DecimalLength input.

Examples include:

=over 4

=item *

a non-digit in the length field

=item *

no length digits before the separator

=item *

a noncanonical leading zero

=item *

an excessively long decimal length

=item *

a numeric overflow

=item *

a declared payload larger than C<max_frame>

=item *

a complete frame that violates the ordered-byte buffer limit

=back

These use the normal ordered-byte framing error path.

=head1 ERROR BEHAVIOR

Malformed or oversized inbound input produces a
L<Linux::Event::Error> with type:

  framing

The resource then follows its ordinary framing-error lifecycle.

Outbound C<send> rejects a payload larger than C<max_frame> rather than emitting
an invalid frame.

=head1 WHEN TO USE DECIMALLENGTH

Use DecimalLength when the protocol specifies:

  ASCII decimal payload length
  one separator byte
  payload

It is particularly useful for RFC 6587 octet-counted syslog:

  5 HELLO

If the protocol instead uses:

  length:payload,

with a trailing comma, use L<Linux::Event::Framer::Netstring>.

If it uses a binary integer prefix, use
L<Linux::Event::Framer::LengthPrefix> or
L<Linux::Event::Framer::U32BE>.

=head1 PERFORMANCE MODEL

Inbound DecimalLength parsing runs in Linux::Event's native ordered-byte parser.

Decimal parsing, canonical-form checks, overflow detection, C<max_frame>
enforcement, and message-boundary detection happen before semantic delivery
crosses into Perl.

Partial prefixes and payloads remain in native storage until a complete message
is available.

Outbound C<send> calculates the payload byte length, converts it to canonical
ASCII decimal form, appends the configured separator, and sends the resulting
frame through the normal native write path.

=head1 SEE ALSO

L<Linux::Event::Framer>,
L<Linux::Event::Framer::Netstring>,
L<Linux::Event::Framer::LengthPrefix>,
L<Linux::Event::Framer::U32BE>,
L<Linux::Event::Framer::Varint>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>,
F<docs/FRAMING.md>,
F<docs/CHOOSING-A-FRAMER.md>.

=cut
