package Linux::Event::Framer::Fixed;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use bytes ();

sub _build_definition ($class, @args) {
    croak 'Fixed options must be key/value pairs' if @args != 1 && @args % 2;
    my %opt = @args == 1 ? (size => $args[0]) : @args;
    my $size = delete $opt{size};
    croak 'Fixed requires size' if !defined $size;
    croak 'size must be a positive integer'
        if $size !~ /\A\d+\z/ || $size <= 0;
    croak 'unknown Fixed options: ' . join(', ', sort keys %opt) if %opt;

    my $native = { read_mode => 3, fixed_size => 0 + $size };
    return { native => $native, frame => \&_frame };
}

sub _frame ($config, $payload) {
    $payload = '' if !defined $payload;
    my $length = bytes::length($payload);
    croak "send(): payload length $length does not equal fixed size $config->{fixed_size}"
        if $length != $config->{fixed_size};
    return $payload;
}

1;

__END__

=head1 NAME

Linux::Event::Framer::Fixed - Split an ordered byte stream into fixed-size messages

=head1 SYNOPSIS

  package RecordStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Fixed', 32;

  sub on_message ($self, $record) {
      say "received a 32-byte record";
  }

=head1 DESCRIPTION

C<Linux::Event::Framer::Fixed> is for protocols where every message has exactly
the same number of bytes.

For example:

  use Linux::Event::Framer 'Fixed', 4;

means that these wire bytes:

  ABCDEFGHIJKL

are delivered as:

  ABCD
  EFGH
  IJKL

Every complete message is exactly four bytes.

No delimiter or length prefix exists on the wire.

=head1 DECLARING THE SIZE

The compact form is:

  use Linux::Event::Framer 'Fixed', 32;

The equivalent named form is:

  use Linux::Event::Framer 'Fixed',
      size => 32;

C<size> is required.

It must be a positive integer.

For example:

  size => 0

is invalid.

=head1 RECEIVING

Linux::Event retains input until at least C<size> bytes are available.

For:

  use Linux::Event::Framer 'Fixed', 8;

a first read containing only:

  ABC

does not produce a message yet.

If a later read supplies:

  DEFGH

the callback receives:

  ABCDEFGH

as one complete eight-byte message.

Application code therefore does not need to join partial reads itself.

=head1 MULTIPLE RECORDS MAY ARRIVE AT ONCE

A single kernel read can contain several complete fixed-size messages.

For example, with:

  use Linux::Event::Framer 'Fixed', 4;

wire input:

  AAAABBBBCCCC

produces:

  AAAA
  BBBB
  CCCC

as three separate messages.

Kernel read boundaries do not affect the application record boundaries.

=head1 SENDING

C<send> requires a payload whose byte length exactly matches the configured
size.

For example:

  use Linux::Event::Framer 'Fixed', 4;

then:

  $self->send("ABCD");

is valid.

These are not:

  $self->send("ABC");
  $self->send("ABCDE");

Linux::Event rejects them because their byte lengths do not equal the declared
fixed record size.

=head1 NO EXTRA WIRE BYTES ARE ADDED

Unlike delimiter or length-prefixed framing, Fixed framing adds nothing to the
payload.

For example:

  $self->send("ABCD");

with:

  use Linux::Event::Framer 'Fixed', 4;

writes exactly:

  ABCD

The message boundary is known only because every record is exactly four bytes.

=head1 RAW WRITE

C<write> remains the raw-byte operation:

  $self->write($bytes);

Unlike C<send>, C<write> does not verify that the supplied byte string is one
complete fixed-size record.

For example:

  $self->write("AB");

can write two raw bytes even when the class uses:

  use Linux::Event::Framer 'Fixed', 4;

Use C<send> when you want Linux::Event to enforce the protocol's fixed message
size.

Use C<write> only when intentionally writing raw wire bytes.

=head1 BYTE LENGTH, NOT CHARACTER COUNT

C<size> is measured in bytes.

Likewise, C<send> validates the payload's byte length.

Fixed framing is a wire-level byte protocol and does not interpret character
encoding.

Applications using textual data are responsible for encoding it into bytes
before sending when necessary.

=head1 PARTIAL FINAL INPUT

If the peer closes after sending fewer than C<size> bytes of the next record,
those bytes do not form a complete fixed-size message.

For example, with:

  size => 8

a trailing:

  ABC

cannot be delivered as an ordinary complete message.

Fixed framing never invents a shorter final record.

=head1 WHEN TO USE FIXED FRAMING

Fixed framing is appropriate when the protocol genuinely defines records of one
constant size.

Examples might include:

=over 4

=item *

fixed binary telemetry records

=item *

fixed-width hardware messages

=item *

constant-size identifiers or blocks

=item *

simple binary protocols whose record size is defined externally

=back

Do not use Fixed merely because messages are usually similar in size.

If message lengths vary, use a delimiter, length prefix, or another appropriate
framing family instead.

=head1 FRAMING IS CLASS POLICY

As with all built-in Linux::Event framers, the fixed size belongs to the
ordered-byte subclass:

  package RecordStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Fixed', 32;

Every C<RecordStream> object therefore uses 32-byte messages.

There is no separate per-connection Fixed framer object.

Application callbacks may still be constructor callbacks if desired.

=head1 PERFORMANCE MODEL

Inbound fixed-size framing runs in Linux::Event's native ordered-byte parser.

The parser only needs to determine whether at least C<size> bytes are available
for the next complete record.

Incomplete input remains in native storage until enough bytes arrive.

Outbound C<send> performs one byte-length check and then places the unchanged
payload into the ordinary native write path.

=head1 SEE ALSO

L<Linux::Event::Framer>,
L<Linux::Event::Framer::Delimiter>,
L<Linux::Event::Framer::LengthPrefix>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>,
F<docs/FRAMING.md>,
F<docs/CHOOSING-A-FRAMER.md>.

=cut
