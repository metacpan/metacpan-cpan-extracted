package Linux::Event::Framer::Netstring;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, @args) {
    croak 'Netstring options must be key/value pairs' if @args % 2;
    my %opt = @args;
    my $max_frame = delete $opt{max_frame};
    croak 'max_frame must be a non-negative integer'
        if defined($max_frame) && ($max_frame !~ /\A\d+\z/ || $max_frame < 0);
    croak 'unknown Netstring options: ' . join(', ', sort keys %opt) if %opt;

    my $native = { read_mode => 5, max_frame => $max_frame };
    return { native => $native, frame => \&_frame };
}

sub _frame ($config, $payload) {
    $payload = '' if !defined $payload;
    my $length = bytes::length($payload);
    croak "send(): payload length $length exceeds max_frame=$config->{max_frame}"
        if defined($config->{max_frame}) && $length > $config->{max_frame};
    return $length . ':' . $payload . ',';
}

1;

__END__

=head1 NAME

Linux::Event::Framer::Netstring - Frame messages as canonical netstrings

=head1 SYNOPSIS

  package NetstringStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Netstring',
      max_frame => 1_048_576;

  sub on_message ($self, $message) {
      say "received: $message";
  }

=head1 DESCRIPTION

C<Linux::Event::Framer::Netstring> implements canonical netstring framing.

A netstring has this wire form:

  length:payload,

For example, the payload:

  hello

is represented as:

  5:hello,

The decimal number gives the payload length in bytes.

The colon separates the length from the payload.

The comma terminates the complete netstring.

=head1 DECLARING THE FRAMER

Declare Netstring after the ordered-byte parent class:

  package NetstringStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Netstring';

The same framing policy can also be used with ordered-byte Pipe and TTY
subclasses.

=head1 RECEIVING

Linux::Event parses the decimal length, waits for exactly that many payload
bytes, then requires the trailing comma.

For example, wire input:

  5:hello,

delivers:

  hello

to C<on_message>.

The framing characters are not included in the delivered payload.

=head1 READ BOUNDARIES DO NOT MATTER

A netstring may arrive across several kernel reads.

For example:

  first read:   5:h
  second read:  ell
  third read:   o,

still produces one complete message:

  hello

Linux::Event retains the incomplete netstring until all required bytes are
available.

Application code does not need to rebuild the frame manually.

=head1 MULTIPLE NETSTRINGS MAY ARRIVE AT ONCE

One read may also contain several complete messages:

  3:one,3:two,5:three,

which produces:

  one
  two
  three

Linux::Event continues parsing complete netstrings already available in native
input storage.

=head1 EMPTY MESSAGES

The canonical representation of an empty payload is:

  0:,

Therefore:

  $self->send('');

produces exactly:

  0:,

and an inbound:

  0:,

delivers one empty message.

=head1 CANONICAL LENGTH FORMAT

The length field must contain ASCII decimal digits.

For example:

  5:hello,

is valid.

A non-digit in the length field is invalid.

The canonical zero representation is:

  0

Leading zeroes are not permitted on longer length fields.

For example:

  03:abc,

is rejected.

The canonical form is:

  3:abc,

This avoids several textual encodings representing the same length.

=head1 THE COLON IS REQUIRED

The decimal length must be followed by:

  :

For example:

  5:hello,

is valid.

A malformed length field that never reaches a colon is not treated as a
complete frame.

Invalid characters in that length field cause a framing error.

Linux::Event also bounds the length-field parser so an endlessly growing
decimal prefix cannot consume unbounded parser work.

=head1 THE TRAILING COMMA IS REQUIRED

After exactly the declared number of payload bytes, the next byte must be:

  ,

For example:

  5:hello,

is valid.

This is not:

  5:hello;

and neither is:

  5:hello

as a complete netstring.

A wrong terminator produces a framing error.

=head1 PAYLOAD CONTENT IS ARBITRARY BYTES

The payload itself can contain any byte values.

It may contain:

  :
  ,
  ASCII digits
  NUL bytes
  binary data

because the length field tells Linux::Event exactly how many bytes belong to the
payload.

For example, commas inside the payload do not terminate the netstring early.

Only the comma after the declared payload length is the frame terminator.

=head1 LIMITING PAYLOAD SIZE

=head2 max_frame

An optional C<max_frame> limits payload size:

  use Linux::Event::Framer 'Netstring',
      max_frame => 1_048_576;

If an inbound length declares more than C<max_frame> payload bytes,
Linux::Event reports a framing error immediately.

It does not wait for the oversized payload to arrive first.

C<send> also rejects outbound payloads larger than C<max_frame>.

C<max_frame> must be a non-negative integer.

=head1 MAX_FRAME AND MAX_BUFFER

C<max_frame> limits the netstring payload.

The ordered-byte resource's C<max_buffer> is a separate limit on native input
storage.

A complete netstring requires storage for more than just its payload because
the decimal length, colon, and trailing comma also occupy bytes.

Linux::Event checks the complete framed size against the ordered-byte buffer
limit as well.

=head1 SENDING

C<send> generates the canonical netstring automatically.

For example:

  $self->send("hello");

writes:

  5:hello,

and:

  $self->send("ABC");

writes:

  3:ABC,

The application supplies only the payload.

Linux::Event calculates the byte length and adds the decimal length, colon, and
trailing comma.

=head1 RAW WRITE

C<write> bypasses the framer:

  $self->write($bytes);

For example:

  $self->write("5:hello,");

writes that byte sequence exactly as supplied.

Ordinary Netstring protocol output should normally use C<send> so the declared
length and terminator cannot accidentally disagree with the payload.

=head1 BYTE LENGTH, NOT CHARACTER COUNT

The decimal number represents payload bytes.

Netstring framing does not define character encoding.

Applications that use Unicode text are responsible for encoding it into the
required wire bytes before calling C<send>.

For example, a character whose encoded representation occupies several bytes
contributes those several bytes to the netstring length.

=head1 MALFORMED INPUT

Linux::Event rejects malformed netstrings rather than guessing what the sender
meant.

Examples include:

=over 4

=item *

a non-digit length

=item *

a noncanonical leading zero

=item *

a decimal length that overflows the supported native integer range

=item *

an excessively long length field

=item *

a payload larger than C<max_frame>

=item *

a complete frame larger than the ordered-byte C<max_buffer>

=item *

a missing or incorrect trailing comma

=back

These conditions use the normal ordered-byte framing error path.

=head1 ERROR BEHAVIOR

Malformed or oversized input produces a L<Linux::Event::Error> with type:

  framing

The resource then follows its normal framing-error lifecycle.

Linux::Event does not deliver a partial, truncated, or noncanonical netstring as
though it were valid.

=head1 WHEN TO USE NETSTRING

Netstrings are useful when a protocol wants:

=over 4

=item *

an explicit payload length

=item *

arbitrary binary-safe payload contents

=item *

a human-readable decimal length

=item *

a simple self-delimiting wire format

=item *

canonical encoding

=back

If the protocol instead specifies a fixed-width binary length, use
L<Linux::Event::Framer::LengthPrefix> or
L<Linux::Event::Framer::U32BE>.

=head1 PERFORMANCE MODEL

Inbound netstring parsing runs in Linux::Event's native ordered-byte parser.

Decimal-length parsing, canonical-form validation, payload-boundary detection,
and trailing-comma validation occur before semantic message delivery crosses
into Perl.

Incomplete frames remain in native storage until enough bytes arrive.

Outbound C<send> calculates the payload byte length and creates the canonical:

  length:payload,

wire representation before passing it to the ordinary native write path.

=head1 SEE ALSO

L<Linux::Event::Framer>,
L<Linux::Event::Framer::LengthPrefix>,
L<Linux::Event::Framer::U32BE>,
L<Linux::Event::Framer::Varint>,
L<Linux::Event::Framer::DecimalLength>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>,
F<docs/FRAMING.md>,
F<docs/CHOOSING-A-FRAMER.md>.

=cut
