package Linux::Event::IO::TTY;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use parent 'Linux::Event::_ByteStream';
use Carp qw(croak);

sub new ($class, %option) {
    if (defined(my $fh = $option{fh})) {
        croak 'new(): fh is not a TTY or PTY' if !-t $fh;
    } else {
        croak 'new(): read_fh is not a TTY or PTY'
            if defined($option{read_fh}) && !-t $option{read_fh};
        croak 'new(): write_fh is not a TTY or PTY'
            if defined($option{write_fh}) && !-t $option{write_fh};
    }
    return $class->SUPER::new(%option);
}

1;

__END__

=head1 NAME

Linux::Event::IO::TTY - asynchronous ordered-byte I/O for terminals and PTYs

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::IO::TTY;

  package Console;
  use parent 'Linux::Event::IO::TTY';
  use Linux::Event::Framer 'Delimiter', "\n";

  package main;
  my $loop = Linux::Event::Loop->new;
  my $console = Console->new(
      loop     => $loop,
      read_fh  => \*STDIN,
      write_fh => \*STDOUT,
      on_message => sub ($tty, $line) {
          $tty->write("You typed: $line\n");
      },
  );
  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::IO::TTY> is the public ordered-byte I/O class for terminals and
pseudo-terminals. It is appropriate for interactive standard input/output,
PTY-backed subprocess interfaces, and other terminal handles that should use
Linux::Event's native buffering and readiness machinery.

TTY owns asynchronous byte movement; it does not configure terminal modes,
echo, canonical input, baud rates, or other termios policy. Applications that
need those settings configure the terminal separately.

=head1 CALLBACKS, SUBCLASSING, AND TUNING

Constructor callbacks give each TTY ordinary lexical scope. A subclass is the
right place for reusable terminal protocol policy: it can declare a native
L<Linux::Event::Framer>, define named callbacks, and centralize
C<stream_tuning> tuning. The Synopsis combines a delimiter-framing subclass
with a per-object C<on_message> closure.

C<stream_tuning> controls read size and fairness, callback batching, buffer
and output limits, watermarks, and established deadlines. Linux::Event
validates and caches framer, tuning, and method policy once per subclass.
Constructor callbacks override same-named methods for one TTY and are retained
once per object; input delivery adds no repeated method lookup or
method-versus-closure branch.

TLS does not apply to TTY; TLS transport policy is specific to
L<Linux::Event::IO::Sock::Stream>.

=head2 stream_tuning

Define C<stream_tuning> as a class method on the TTY subclass. It returns
key/value pairs, or one hash reference:

  package InteractiveTTY;
  use parent 'Linux::Event::IO::TTY';

  sub stream_tuning ($class) {
      return (
          read_size        => 16_384,
          read_batch_bytes => 4_096,
          max_buffer       => 1_048_576,
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
TTY; the other values are class policy.

=head1 CONSTRUCTION

C<new> accepts a shared C<fh>, separate C<read_fh> and C<write_fh>, or either
direction alone. Every supplied handle must be a TTY or PTY according to Perl's
C<-t> test. Separate input and output handles are intentionally supported, so
C<STDIN> and C<STDOUT> can form one logical terminal object.

C<loop =E<gt> $loop> attaches immediately; detached objects may instead be
passed to C<< $loop->add($tty) >>. C<data> stores application state. Owned
handles are made nonblocking and close-on-exec.

Established C<idle_timeout>, C<read_timeout>, C<write_timeout>, and explicit
C<deadline> options use the common ordered-byte deadline model.

=head1 CALLBACKS AND FRAMING

A raw readable TTY requires C<on_data($tty, $bytes)> as a method or constructor
callback. A class that uses L<Linux::Event::Framer> requires
C<on_message($tty, $message)> or, with explicit batching,
C<on_messages($tty, $messages)>; either may be supplied by the class or
constructor.

Delimiter framing is especially useful for line-oriented interactive input:

  use Linux::Event::Framer 'Delimiter', "\n";

Framing operates on the bytes Linux supplies after the terminal's own line
discipline. Linux::Event does not change canonical/raw terminal mode merely
because a framer is declared.

Optional lifecycle callbacks are C<on_drain($tty)>, C<on_eof($tty)>,
C<on_error($tty, $error)>, and C<on_close($tty)>.

The same callback names may be passed as coderefs to C<new>. A constructor
callback overrides the corresponding class method for that TTY and can capture
normal Perl lexical state. Linux::Event resolves the effective callback once;
it does not select between a method and closure for each input event.

=head1 OUTPUT AND LIFECYCLE

C<write> submits raw bytes; C<send> applies the declared framer. Native output
queues preserve ordering and provide high/low-watermark backpressure.

C<pause_read> and C<resume_read> control application input. C<end> drains the
writable side, while C<close_read>, C<close_write>, and C<close> provide
immediate directional or whole-object termination.

C<detach> transfers still-open directional handles to the caller when no output
is queued. It is terminal and does not call C<on_close>.

=head1 CLASS POLICY

C<stream_tuning> configures the common ordered-byte engine. The complete
option contract appears near the top of this document. Policy is cached per
subclass so ordinary readiness does not parse options or look up callbacks.

=head1 SEE ALSO

L<Linux::Event::IO::Pipe>, L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::Framer>, F<docs/ORDERED-BYTE-IO-DESIGN.md>.

=cut
