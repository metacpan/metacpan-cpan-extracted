package Linux::Event::IO::Pipe;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use parent 'Linux::Event::_ByteStream';
use Carp qw(croak);

# Linux fcntl.h: F_LINUX_SPECIFIC_BASE + 8. Linux::Event is Linux-only and
# F_GETPIPE_SZ succeeds only for pipe/FIFO descriptors, so this avoids the
# heavier stat-backed -p file test while preserving the concrete leaf contract.
use constant _F_GETPIPE_SZ => 1032;

sub _is_pipe ($fh) {
    return defined fcntl($fh, _F_GETPIPE_SZ, 0);
}

sub new ($class, %option) {
    if (defined(my $fh = $option{fh})) {
        croak 'new(): fh is not a pipe or FIFO' if !_is_pipe($fh);
    } else {
        croak 'new(): read_fh is not a pipe or FIFO'
            if defined($option{read_fh}) && !_is_pipe($option{read_fh});
        croak 'new(): write_fh is not a pipe or FIFO'
            if defined($option{write_fh}) && !_is_pipe($option{write_fh});
    }
    return $class->SUPER::new(%option);
}

1;

__END__

=head1 NAME

Linux::Event::IO::Pipe - asynchronous ordered-byte I/O for pipes and FIFOs

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::IO::Pipe;

  package LinePipe;
  use parent 'Linux::Event::IO::Pipe';
  use Linux::Event::Framer 'Delimiter', "\n";

  package main;
  pipe(my $read, my $write) or die "pipe: $!";

  my $loop = Linux::Event::Loop->new;
  my $prefix = 'received';
  my $pipe = LinePipe->new(
      loop       => $loop,
      read_fh    => $read,
      on_message => sub ($pipe, $line) {
          say "$prefix: $line";
          $pipe->close;
          $loop->stop;
      },
  );

  syswrite($write, "hello\n") == 6 or die "syswrite: $!";
  $loop->run;
  close $write;

=head1 DESCRIPTION

C<Linux::Event::IO::Pipe> is the public ordered-byte I/O class for anonymous
pipes and FIFOs. It uses the same native buffering, framing, output queue,
backpressure, deadlines, and directional lifecycle as the other ordered-byte
Linux::Event leaves without giving a pipe socket semantics.

A Pipe may be read-only, write-only, or duplex. Duplex operation may use two
different descriptors, which is useful for child stdin/stdout pairs and other
one-way pipe combinations.

=head1 CALLBACKS, SUBCLASSING, AND TUNING

Constructor callbacks let one Pipe capture lexical application state. A
subclass becomes more valuable when many pipes share protocol policy: it can
declare a native L<Linux::Event::Framer>, centralize C<stream_tuning> tuning,
and provide named callbacks. For example, the Synopsis deliberately combines a
delimiter-framing subclass with a lexical C<on_message> closure.

C<stream_tuning> controls read size and fairness, callback batching, buffer
and output limits, watermarks, and established deadlines. Framer and tuning
policy are validated and cached once per subclass. Constructor callbacks
override same-named methods for one Pipe and are cached once per object, so the
hot input path does not perform method lookup or callback-style selection.

TLS does not apply to Pipe; TLS transport policy is specific to
L<Linux::Event::IO::Sock::Stream>.

=head2 stream_tuning

Define C<stream_tuning> as a class method on the Pipe subclass. It returns
key/value pairs, or one hash reference:

  package BulkPipe;
  use parent 'Linux::Event::IO::Pipe';

  sub stream_tuning ($class) {
      return (
          read_size         => 131_072,
          read_budget_bytes => 524_288,
          max_buffer        => 16_777_216,
      );
  }

The complete option set is:

=over 4

=item * C<read_size> (default 65,536)

Maximum bytes requested by one native read; a positive integer.

=item * C<read_budget_bytes> (default 65_536)

Maximum bytes read during one readiness drain. The default bounds one
readiness callback to 65,536 bytes so other Loop resources can run. Zero is an
explicit opt-in to drain until the input would block.

=item * C<read_batch_bytes> (default 0)

For an unframed class, combine successful reads before C<on_data> up to this
non-negative byte target. A partial batch flushes when the current drain ends;
zero preserves normal read callback boundaries. It is invalid on a framed
class.

=item * C<message_batch_size> (default 0)

For a framed class, deliver arrays of at most this many messages to
C<on_messages>. A partial batch flushes when the current drain ends; zero uses
C<on_message>. A positive value requires C<on_messages> and is invalid on an
unframed class.

=item * C<max_buffer> (default 8,388,608)

Positive hard byte bound for retained input, an incomplete frame, and the
aggregate payload retained for one message batch.

=item * C<high_watermark> (default 1,048,576)

Non-negative pending-output byte level at which C<write> or C<send> begins
returning false while still accepting the data.

=item * C<low_watermark> (default 262,144)

Non-negative pending-output byte level at or below which C<on_drain> fires
after high-watermark backpressure. It must not exceed C<high_watermark>.

=item * C<max_pending_bytes> (default 0)

Hard non-negative pending-output byte limit. Zero means unbounded.

=item * C<idle_timeout> (default 0 seconds)

Maximum inactivity interval since successful input or output progress. Zero
disables it.

=item * C<read_timeout> (default 0 seconds)

Maximum interval without inbound progress while reading is active. Pausing
input suspends it; zero disables it.

=item * C<write_timeout> (default 0 seconds)

Maximum interval without output progress while data is queued. Zero disables
it.

=back

Byte counts are integers. Timeout values are finite non-negative seconds and
may be fractional. Constructor timeout values override class defaults for one
Pipe; the other values are class policy.

=head1 CONSTRUCTION

C<new> accepts exactly one of these handle shapes:

  MyPipe->new(fh => $duplex_handle);
  MyPipe->new(read_fh => $input, write_fh => $output);
  MyPipe->new(read_fh => $input);
  MyPipe->new(write_fh => $output);

C<fh> means that one descriptor supplies both directions and cannot be combined
with C<read_fh> or C<write_fh>. Every supplied handle must be a Linux pipe or
FIFO. Linux::Event validates that identity before generic ordered-byte setup,
then makes owned descriptors nonblocking and close-on-exec.

C<loop =E<gt> $loop> attaches immediately. Otherwise construct detached and
pass the object to C<< $loop->add($pipe) >>. C<data> stores arbitrary
application state.

Ordered-byte deadline overrides C<idle_timeout>, C<read_timeout>, and
C<write_timeout>, plus an explicit C<deadline>, are also accepted. See
F<docs/ORDERED-BYTE-DEADLINES.md>.

=head1 INPUT CALLBACKS

A readable unframed Pipe requires, as a subclass method or constructor option:

  sub on_data ($pipe, $bytes) { ... }

With L<Linux::Event::Framer>, a framed Pipe similarly requires:

  sub on_message ($pipe, $message) { ... }

or C<on_messages($pipe, $messages)> when C<message_batch_size> is enabled.
Optional lifecycle callbacks are C<on_drain($pipe)>, C<on_eof($pipe)>,
C<on_error($pipe, $error)>, and C<on_close($pipe)>.

Each callback may instead be supplied as a coderef to C<new>. Constructor
callbacks override class methods for that Pipe and retain ordinary Perl lexical
scope. Input callbacks are cached in the same native ordered-byte state as
method callbacks rather than looked up for each read or message.

=head1 OUTPUT AND LIFECYCLE

C<write($bytes)> queues raw bytes. C<send($payload)> applies the subclass's
framer when one is declared. High/low watermarks provide cooperative
backpressure and C<max_pending_bytes> can impose a hard queue bound.

C<pause_read> and C<resume_read> control input delivery. C<end> drains accepted
output and ends the writable direction. C<close_read> and C<close_write> stop
one direction immediately; C<close> terminates the whole object.

C<detach> requires an empty output queue and transfers the still-open handles
back to the caller as a hash containing C<read_fh> and C<write_fh>. It is a
terminal ownership transfer and does not invoke C<on_close>.

=head1 CLASS POLICY

Subclasses may define C<stream_tuning> for the shared ordered-byte engine.
The complete option contract appears near the top of this document. These
values are cached once per concrete subclass rather than parsed per instance.

Framing is valid for pipes because framing describes ordered application bytes,
not sockets. See L<Linux::Event::Framer> and F<docs/FRAMING.md>.

=head1 SEE ALSO

L<Linux::Event::IO::TTY>, L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::Loop>, F<docs/ORDERED-BYTE-IO-DESIGN.md>.

=cut
