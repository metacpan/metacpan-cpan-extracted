package Linux::Event::Stream::Codec;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.002';

use Carp qw(croak);
use Scalar::Util qw(reftype);

=head1 NAME

Linux::Event::Stream::Codec - Framing/encoding contract for Linux::Event::Stream

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;
  use Linux::Event::Stream;

  # A codec is a (blessed) hashref with two coderefs:
  my $codec = Linux::Event::Stream::Codec::make_codec(
    name => 'MyApp::Codec::Nul',

    decode => sub ($self, $inref, $outref) {
      while (1) {
        my $i = index($$inref, "\0");
        last if $i < 0;

        my $msg = substr($$inref, 0, $i, '');
        substr($$inref, 0, 1, ''); # drop the NUL
        push @$outref, $msg;
      }
      return 1;
    },

    encode => sub ($self, $msg) {
      return $msg . "\0";
    },
  );

  my $s = Linux::Event::Stream->new(
    loop => $loop,
    fh   => $fh,
    codec      => $codec,
    on_message => sub ($stream, $msg, $data) {
      ...
    },
  );

=head1 DESCRIPTION

This module documents the codec interface used by L<Linux::Event::Stream> when
operating in framed/message mode (C<codec> + C<on_message>). A codec answers
exactly one question:

  "Where does one message end and the next begin?"

In other words: this is framing + encoding/decoding, not an application
protocol.

Codecs are intentionally lightweight: they are (blessed) hashrefs containing
two coderefs. L<Linux::Event::Stream> validates these once at construction time
and then calls the coderefs directly in the hot path (no per-message method
dispatch required).

=head1 CODEC CONTRACT

=head2 Structure

A codec is a hashref (or blessed hashref) with the following keys:

  decode => CODE
  encode => CODE

=head2 decode

  my ($ok, $err) = $codec->{decode}->($codec, \$inbuf, \@out);

The C<decode> callback:

=over 4

=item * receives the codec object, a reference to the input buffer string, and
an arrayref to push decoded messages into

=item * consumes complete messages from C<$$inbuf> (modify it in-place)

=item * pushes 0..N decoded messages onto C<@out>

=item * returns C<(1)> on success

=item * returns C<(0, $error_string)> on failure

=back

If a message is incomplete, leave the remaining bytes in C<$$inbuf> and return
C<(1)>. L<Linux::Event::Stream> will append more bytes and call C<decode> again
later.

=head2 encode

  my $bytes = $codec->{encode}->($codec, $msg);

The C<encode> callback returns the bytes to be written to the stream for the
given message.

=head1 HELPERS

This module provides small helpers that are useful when writing your own codec.
They are optional; L<Linux::Event::Stream> does not require you to use them.

=head2 validate

  Linux::Event::Stream::Codec::validate($codec);

Croaks unless C<$codec> is a hashref (or blessed hashref) containing CODE refs
at C<decode> and C<encode>.

=head2 make_codec

  my $codec = Linux::Event::Stream::Codec::make_codec(
    name   => 'My::Codec',
    decode => sub (...) { ...; return 1 },
    encode => sub (...) { ... },
  );

Creates and returns a blessed codec hashref. The C<name> is optional; if
provided, it is used as the blessing package.

=head1 SECURITY AND LIMITS

When framing untrusted input (e.g. TCP servers), always enforce reasonable
limits.

=over 4

=item * Cap buffered undecoded bytes (Stream's C<max_inbuf>)

=item * Cap per-frame size (codec option like C<max_frame> / C<max_line>)

=back

Never allow a peer to grow memory without bound by sending an unterminated
frame.

=cut

sub validate ($codec) {
  croak 'codec is required' if !defined $codec;

  my $rt = reftype($codec);
  croak 'codec must be a hashref (or blessed hashref)'
    if !defined($rt) || $rt ne 'HASH';

  my $dec = $codec->{decode};
  my $enc = $codec->{encode};

  croak 'codec->{decode} must be a CODE ref' if ref($dec) ne 'CODE';
  croak 'codec->{encode} must be a CODE ref' if ref($enc) ne 'CODE';

  return 1;
}

sub make_codec (%args) {
  my $name = delete $args{name};
  my $codec = { %args };

  validate($codec);

  # Blessing is optional; bless only when the caller provides a name.
  return $name ? bless($codec, $name) : $codec;
}

1;
