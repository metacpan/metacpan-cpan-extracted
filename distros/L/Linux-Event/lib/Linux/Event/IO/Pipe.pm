package Linux::Event::IO::Pipe;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

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

Linux::Event::IO::Pipe - Asynchronous pipes and FIFOs

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::IO::Pipe;

  pipe(my $read_fh, my $write_fh)
      or die "pipe: $!";

  my $loop = Linux::Event::Loop->new;

  my $pipe = Linux::Event::IO::Pipe->new(
      loop    => $loop,
      read_fh => $read_fh,

      on_data => sub ($self, $bytes) {
          say "Received: $bytes";
          $self->close;
          $loop->stop;
      },
  );

  syswrite($write_fh, "hello") == 5
      or die "syswrite: $!";

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::IO::Pipe> provides asynchronous I/O for Linux pipes and FIFOs.

A Pipe may be:

=over 4

=item *

read-only

=item *

write-only

=item *

read/write using one handle

=item *

read/write using separate input and output handles

=back

The separate-handle form is particularly useful for things such as child
process stdin and stdout, where reading and writing naturally happen through
different pipe descriptors.

A Pipe uses the same ordered-byte behavior as
L<Linux::Event::IO::Sock::Stream>.

That means it supports:

=over 4

=item *

raw C<on_data> callbacks

=item *

L<Linux::Event::Framer> message framing

=item *

queued asynchronous output

=item *

backpressure

=item *

read pausing

=item *

timeouts and deadlines

=back

TLS does not apply to Pipe objects.

=head1 CREATING A READ-ONLY PIPE

Supply C<read_fh>:

  my $pipe = Linux::Event::IO::Pipe->new(
      loop    => $loop,
      read_fh => $read_fh,

      on_data => sub ($self, $bytes) {
          print $bytes;
      },
  );

The supplied handle must refer to a Linux pipe or FIFO.

The Pipe can receive input but cannot write because no output handle was
supplied.

=head1 CREATING A WRITE-ONLY PIPE

Supply C<write_fh>:

  my $pipe = Linux::Event::IO::Pipe->new(
      loop     => $loop,
      write_fh => $write_fh,
  );

Then write asynchronously with:

  $pipe->write("hello");

No input callback is required because this Pipe has no readable direction.

=head1 USING SEPARATE READ AND WRITE HANDLES

A Pipe may use different handles for input and output:

  my $pipe = Linux::Event::IO::Pipe->new(
      loop     => $loop,
      read_fh  => $stdout_from_child,
      write_fh => $stdin_to_child,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

This is useful when one logical communication channel is built from two
one-way pipes.

For example, a child process may have:

  parent writes -> child stdin

and:

  child stdout -> parent reads

Linux::Event can treat those two descriptors as one Pipe object.

=head1 USING ONE HANDLE FOR BOTH DIRECTIONS

When one handle supplies both readable and writable directions, use C<fh>:

  my $pipe = Linux::Event::IO::Pipe->new(
      loop => $loop,
      fh   => $fh,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

C<fh> cannot be combined with C<read_fh> or C<write_fh>.

The supplied handle must be a Linux pipe or FIFO.

=head1 ATTACHING TO A LOOP

A Pipe can be attached during construction:

  my $pipe = Linux::Event::IO::Pipe->new(
      loop    => $loop,
      read_fh => $read_fh,
      ...
  );

or created detached:

  my $pipe = Linux::Event::IO::Pipe->new(
      read_fh => $read_fh,
      ...
  );

and added later:

  $loop->add($pipe);

Both forms are normal Linux::Event APIs.

=head1 RECEIVING DATA

=head2 on_data

An unframed readable Pipe receives bytes through C<on_data>:

  on_data => sub ($self, $bytes) {
      print $bytes;
  }

C<$bytes> contains the next available part of the ordered byte stream.

A Pipe does not inherently know where your application's messages begin or end.

If the data has message boundaries, use L<Linux::Event::Framer>.

=head1 MESSAGE FRAMING

A Pipe can use the same framing system as a Stream.

For example, a newline-delimited Pipe can be written as:

  package LinePipe;

  use parent 'Linux::Event::IO::Pipe';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      say "Received line: $message";
  }

Then:

  my $pipe = LinePipe->new(
      loop    => $loop,
      read_fh => $read_fh,
  );

Incoming bytes are accumulated until a complete framed message is available.

The application receives C<on_message> rather than having to maintain its own
partial-input buffer.

=head2 Constructor callback with framing

Framing belongs to the subclass, but the message callback may still be supplied
for one object:

  my $prefix = 'received';

  my $pipe = LinePipe->new(
      loop    => $loop,
      read_fh => $read_fh,

      on_message => sub ($self, $message) {
          say "$prefix: $message";
      },
  );

The constructor callback overrides a same-named subclass method for that Pipe.

=head1 SENDING DATA

=head2 write($bytes)

  $pipe->write("hello");

Send raw ordered bytes.

Linux::Event first attempts to write immediately.

If the output descriptor cannot accept all of the data, the remaining bytes are
queued and written later.

Data remains in order.

=head2 send($payload)

For a framed Pipe:

  $pipe->send($payload);

C<send> applies the Pipe subclass's L<Linux::Event::Framer> before queuing the
resulting bytes.

For an unframed Pipe, use C<write>.

=head1 BACKPRESSURE

A writable Pipe has an output queue.

When queued output grows past the high watermark, C<write> or C<send> begins
returning false.

The supplied data is still accepted unless a configured hard queue limit would
be exceeded.

When queued output later falls to the low watermark, C<on_drain> is called:

  on_drain => sub ($self) {
      # Producing more output is safe again.
  }

This allows a producer to slow itself down instead of allowing the output queue
to grow without bound.

=head1 EOF

=head2 on_eof

  on_eof => sub ($self) {
      say "Input reached EOF";
  }

Called when the readable side reaches end-of-file.

For a pipe, this commonly means that all writers for the other end have been
closed.

EOF affects the readable direction and does not necessarily mean that the
Pipe's writable direction has also ended.

=head1 PAUSING INPUT

=head2 pause_read

  $pipe->pause_read;

Temporarily stop delivering input.

=head2 resume_read

  $pipe->resume_read;

Resume input delivery.

Read timeout accounting is suspended while input is deliberately paused.

=head1 CALLBACKS

Pipe callbacks may be supplied directly to C<new> or implemented as subclass
methods.

The normal callbacks are:

=over 4

=item C<on_data($pipe, $bytes)>

Raw unframed input arrived.

=item C<on_message($pipe, $message)>

One complete framed message arrived.

=item C<on_messages($pipe, $messages)>

A batch of framed messages arrived when message batching is enabled.

=item C<on_drain($pipe)>

Queued output fell to the low watermark after backpressure.

=item C<on_eof($pipe)>

The readable direction reached EOF.

=item C<on_error($pipe, $error)>

An asynchronous I/O or policy error occurred.

=item C<on_close($pipe)>

The Pipe closed.

=back

A constructor callback overrides a same-named subclass method for that object.

=head1 APPLICATION DATA

An arbitrary value may be stored with the Pipe:

  my $pipe = Linux::Event::IO::Pipe->new(
      read_fh => $read_fh,
      data    => $state,
      ...
  );

This is useful for associating application state with the Pipe.

=head1 CLOSING DIRECTIONS

Because a Pipe may have separate read and write handles, its two directions can
be controlled independently.

=head2 close_read

  $pipe->close_read;

Close the readable direction immediately.

The writable direction may remain active.

=head2 close_write

  $pipe->close_write;

Close the writable direction immediately.

The readable direction may remain active.

=head2 end

  $pipe->end;

Allow already accepted output to drain, then end the writable direction.

Use C<end> when queued data should be delivered before output is closed.

=head2 close

  $pipe->close;

Close the entire Pipe immediately.

This is terminal for both directions.

=head1 DETACHING PIPE HANDLES

=head2 detach

  my $handles = $pipe->detach;

Detach the Pipe from Linux::Event and return its still-open handles.

The return value is a hash reference containing:

  read_fh
  write_fh

as applicable.

For example:

  my $handles = $pipe->detach;

  my $read_fh  = $handles->{read_fh};
  my $write_fh = $handles->{write_fh};

Detachment requires the output queue to be empty.

It is a terminal ownership transfer and does not invoke C<on_close>.

=head1 SUBCLASSING

Subclassing is optional.

Constructor callbacks are usually simplest for one Pipe:

  my $pipe = Linux::Event::IO::Pipe->new(
      read_fh => $read_fh,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

A subclass is useful when many Pipe objects share framing, callbacks, or tuning:

  package ProtocolPipe;

  use parent 'Linux::Event::IO::Pipe';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      ...
  }

=head1 STREAM TUNING

Pipe uses the same ordered-byte tuning model as Stream.

Most applications should leave the defaults unchanged.

Reusable defaults may be declared in a Pipe subclass with
C<stream_tuning>:

  package BulkPipe;

  use parent 'Linux::Event::IO::Pipe';

  sub stream_tuning ($class) {
      return (
          read_size         => 131_072,
          read_budget_bytes => 524_288,
          max_buffer        => 16_777_216,
      );
  }

C<stream_tuning> is subclass policy.

These values are not placed inside a constructor C<tuning> hash.

Timeout and deadline values that Linux::Event allows as per-object overrides
may be supplied directly to C<new>.

=head2 read_size

Default: 65,536 bytes.

Maximum number of bytes requested by one native read.

=head2 read_budget_bytes

Default: 65,536 bytes.

Maximum amount of input read during one readiness turn before yielding to other
Loop resources.

This is a fairness control.

A value of zero explicitly requests unlimited reading until the descriptor
would block.

=head2 read_batch_bytes

Default: 0.

For an unframed Pipe, successful reads may be combined before C<on_data> is
called.

Zero preserves normal read callback boundaries.

This option cannot be used with framing.

=head2 message_batch_size

Default: 0.

For a framed Pipe, deliver up to this many complete messages together through
C<on_messages>.

Zero uses normal C<on_message> delivery.

A positive value requires framing and an C<on_messages> callback.

=head2 max_buffer

Default: 8,388,608 bytes.

Hard limit for retained input, incomplete framed data, and data retained for one
message batch.

=head2 high_watermark

Default: 1,048,576 bytes.

Queued-output level at which C<write> and C<send> begin returning false to
signal backpressure.

=head2 low_watermark

Default: 262,144 bytes.

After backpressure has occurred, C<on_drain> fires when queued output falls to
or below this level.

The low watermark cannot exceed the high watermark.

=head2 max_pending_bytes

Default: 0.

Hard limit on pending output.

Zero means no hard output-queue limit.

=head2 idle_timeout

Default: 0.

Maximum number of seconds without successful input or output progress.

Zero disables the timeout.

=head2 read_timeout

Default: 0.

Maximum number of seconds without inbound progress while reading is active.

A deliberate C<pause_read> suspends this timeout.

Zero disables it.

=head2 write_timeout

Default: 0.

Maximum number of seconds without output progress while data remains queued.

Zero disables it.

=head1 PER-OBJECT TIMEOUTS AND DEADLINES

Timeout and deadline overrides that apply to one Pipe are supplied directly to
C<new>.

For example:

  my $pipe = Linux::Event::IO::Pipe->new(
      loop    => $loop,
      read_fh => $read_fh,

      idle_timeout => 60,
      read_timeout => 10,
      deadline => {
          after     => 120,
          operation => 'read',
      },

      on_data => sub ($self, $bytes) {
          ...
      },
  );

These options apply to this Pipe object.

They are not placed inside a nested C<tuning> hash.

The supported deadline behavior is described in
F<docs/ORDERED-BYTE-DEADLINES.md>.

=head1 PERFORMANCE MODEL

Pipe uses the same native ordered-byte engine as Stream and TTY.

Callbacks and reusable subclass policy are resolved when the Pipe is created,
rather than rediscovered for every read or write event.

Framing and buffering are handled before application callbacks are invoked.

These details normally require no application action.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::IO::TTY>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::Framer>,
L<Linux::Event::Error>,
F<docs/ORDERED-BYTE-IO-DESIGN.md>,
F<docs/ORDERED-BYTE-DEADLINES.md>.

=cut
