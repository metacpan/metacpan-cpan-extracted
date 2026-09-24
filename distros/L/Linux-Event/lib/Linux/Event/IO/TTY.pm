package Linux::Event::IO::TTY;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use parent 'Linux::Event::_ByteStream';
use Carp qw(croak);

sub new ($class, %option) {
    my $owns_handles = exists($option{owns_handles})
        ? delete($option{owns_handles}) : 0;
    croak 'new(): owns_handles must be zero or one'
        if !defined($owns_handles) || ref($owns_handles)
        || $owns_handles !~ /\A[01]\z/;

    if (defined(my $fh = $option{fh})) {
        croak 'new(): fh is not a TTY or PTY' if !-t $fh;
    } else {
        croak 'new(): read_fh is not a TTY or PTY'
            if defined($option{read_fh}) && !-t $option{read_fh};
        croak 'new(): write_fh is not a TTY or PTY'
            if defined($option{write_fh}) && !-t $option{write_fh};
    }

    $option{_owns_handles} = $owns_handles ? 1 : 0;
    return $class->SUPER::new(%option);
}

sub owns_handles ($self) { !!$self->{owns_handles} }

1;

__END__

=head1 NAME

Linux::Event::IO::TTY - Asynchronous terminal and pseudo-terminal I/O

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::IO::TTY;

  my $loop = Linux::Event::Loop->new;

  my $tty = Linux::Event::IO::TTY->new(
      loop     => $loop,
      read_fh  => \*STDIN,
      write_fh => \*STDOUT,

      on_data => sub ($self, $bytes) {
          $self->write("You typed: $bytes");
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::IO::TTY> provides asynchronous byte I/O for terminals and
pseudo-terminals.

It can be used for things such as:

=over 4

=item *

interactive terminal input and output

=item *

C<STDIN> and C<STDOUT>

=item *

pseudo-terminals used to communicate with subprocesses

=item *

terminal devices opened by an application

=back

TTY uses the same ordered-byte I/O engine as
L<Linux::Event::IO::Pipe> and L<Linux::Event::IO::Sock::Stream>.

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

=head1 LINUX::EVENT DOES NOT CONFIGURE TERMINAL MODE

C<Linux::Event::IO::TTY> handles asynchronous I/O.

It does B<not> automatically change terminal behavior.

In particular, creating a TTY object does not automatically:

=over 4

=item *

enable or disable canonical mode

=item *

enable or disable echo

=item *

put the terminal into raw mode

=item *

change baud rates

=item *

change character-processing flags

=item *

restore previous terminal settings later

=back

Those settings are controlled separately through the terminal's termios
configuration.

For example, if C<STDIN> is still in normal canonical terminal mode, the kernel
may continue collecting input until the user presses Enter before Linux::Event
receives it.

If an application wants individual key presses, raw mode, disabled echo, or
other terminal behavior, it must configure those settings separately.

Linux::Event then asynchronously reads and writes whatever byte behavior that
terminal mode provides.

=head1 CREATING A TERMINAL OBJECT

A common interactive terminal uses separate input and output handles:

  my $tty = Linux::Event::IO::TTY->new(
      loop     => $loop,
      read_fh  => \*STDIN,
      write_fh => \*STDOUT,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

Both supplied handles must be terminals or pseudo-terminals according to
Perl's C<-t> test.

=head1 HANDLE OWNERSHIP

TTY handles are B<borrowed by default>.

This is deliberate because the most common terminal handles are often the
program's own C<STDIN> and C<STDOUT>:

  my $tty = Linux::Event::IO::TTY->new(
      read_fh  => \*STDIN,
      write_fh => \*STDOUT,
      ...
  );

Linux::Event temporarily makes borrowed handles nonblocking and close-on-exec
while the TTY is managing them.

When the TTY becomes terminal through C<close>, Linux::Event stops using the
borrowed handles, leaves them open, and restores the file status and descriptor
flags that were present when the TTY was constructed.

Therefore this is valid:

  my $tty = Linux::Event::IO::TTY->new(
      loop     => $loop,
      read_fh  => \*STDIN,
      write_fh => \*STDOUT,
      ...
  );

  ...

  $tty->close;

  say "ordinary STDOUT still works";

Closing the TTY does not close C<STDIN> or C<STDOUT> in the default borrowed
mode.

=head2 While borrowed handles are active

While Linux::Event is managing a borrowed terminal handle, that descriptor is
nonblocking.

On Linux, C<O_NONBLOCK> belongs to the underlying open-file description. Other
file descriptors duplicated from the same terminal open-file description may
therefore observe the nonblocking setting while the TTY is active.

For example, ordinary buffered C<print> to C<STDOUT> should not be mixed
casually with asynchronous C<< $tty->write(...) >> output while Linux::Event is
actively managing that same terminal.

Use the TTY's C<write> or C<send> methods for output during the managed
lifetime. After the borrowed TTY closes or detaches, Linux::Event restores the
captured descriptor flags and ordinary Perl I/O can resume normally.

=head2 owns_handles

An application may explicitly transfer handle ownership to the TTY:

  my $tty = Linux::Event::IO::TTY->new(
      fh           => $terminal,
      owns_handles => 1,
      ...
  );

With C<owns_handles =E<gt> 1>, normal TTY close operations own and close the
supplied handles.

The default is:

  owns_handles => 0

Use owning mode for terminal handles whose lifetime should be controlled
entirely by the TTY object rather than by the surrounding application.

=head2 owns_handles()

  if ($tty->owns_handles) {
      ...
  }

Return true when the TTY was constructed with C<owns_handles =E<gt> 1>.

=head1 READ-ONLY TERMINALS

Supply only C<read_fh> when Linux::Event should read from a terminal:

  my $tty = Linux::Event::IO::TTY->new(
      loop    => $loop,
      read_fh => \*STDIN,

      on_data => sub ($self, $bytes) {
          print "Received: $bytes";
      },
  );

The TTY has no writable direction in this form.

=head1 WRITE-ONLY TERMINALS

Supply only C<write_fh> when Linux::Event should write to a terminal:

  my $tty = Linux::Event::IO::TTY->new(
      loop     => $loop,
      write_fh => \*STDOUT,
  );

Then:

  $tty->write("hello\n");

sends output asynchronously.

No input callback is required because there is no readable side.

=head1 SEPARATE READ AND WRITE HANDLES

A TTY may combine two different terminal handles into one logical object:

  my $tty = Linux::Event::IO::TTY->new(
      loop     => $loop,
      read_fh  => $input,
      write_fh => $output,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

This is useful with C<STDIN>/C<STDOUT> and with PTY arrangements where input and
output use different descriptors.

=head1 ONE HANDLE FOR BOTH DIRECTIONS

If one terminal handle is both readable and writable, use C<fh>:

  my $tty = Linux::Event::IO::TTY->new(
      loop => $loop,
      fh   => $terminal,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

C<fh> cannot be combined with C<read_fh> or C<write_fh>.

=head1 ATTACHING TO A LOOP

A TTY may be attached during construction:

  my $tty = Linux::Event::IO::TTY->new(
      loop    => $loop,
      read_fh => \*STDIN,
      ...
  );

or constructed first:

  my $tty = Linux::Event::IO::TTY->new(
      read_fh => \*STDIN,
      ...
  );

and attached later:

  $loop->add($tty);

=head1 RECEIVING INPUT

=head2 on_data

An unframed readable TTY receives bytes through C<on_data>:

  on_data => sub ($self, $bytes) {
      ...
  }

C<$bytes> contains the next available part of the terminal byte stream.

The exact shape of that input depends partly on the terminal mode.

For example, a terminal in canonical mode commonly performs line discipline
before Linux::Event sees the data.

A terminal in raw mode may make individual bytes available much sooner.

Linux::Event does not assume either behavior.

=head1 LINE-ORIENTED INPUT

A terminal protocol can use L<Linux::Event::Framer> just like a Stream or Pipe.

For example:

  package Console;

  use parent 'Linux::Event::IO::TTY';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $line) {
      $self->write("You typed: $line\n");
  }

Then:

  my $console = Console->new(
      loop     => $loop,
      read_fh  => \*STDIN,
      write_fh => \*STDOUT,
  );

The framer operates on the bytes delivered by the terminal.

It does not alter the terminal's own line discipline.

=head2 Constructor callback with framing

A framed subclass may still receive its message callback through the
constructor:

  my $prefix = 'input';

  my $console = Console->new(
      loop     => $loop,
      read_fh  => \*STDIN,
      write_fh => \*STDOUT,

      on_message => sub ($self, $line) {
          say "$prefix: $line";
      },
  );

The constructor callback overrides a same-named subclass method for that TTY.

=head1 WRITING OUTPUT

=head2 write($bytes)

  $tty->write("hello\n");

Send raw bytes to the writable terminal handle.

Linux::Event first attempts to write immediately.

If the terminal cannot accept all the data at once, remaining bytes are queued
and written later.

Output order is preserved.

=head2 send($payload)

For a framed TTY:

  $tty->send($payload);

C<send> applies the subclass's L<Linux::Event::Framer> before writing.

For an unframed TTY, use C<write>.

=head1 BACKPRESSURE

TTY output uses the same high- and low-watermark backpressure system as other
ordered-byte resources.

When queued output grows past the high watermark, C<write> or C<send> begins
returning false.

The data is still accepted unless a hard output limit would be exceeded.

When queued data later falls to the low watermark, C<on_drain> is called:

  on_drain => sub ($self) {
      # Producing more output is safe again.
  }

=head1 EOF

=head2 on_eof

  on_eof => sub ($self) {
      say "Terminal input reached EOF";
  }

Called when the readable direction reaches EOF.

For an interactive terminal this may happen, for example, when the terminal or
PTY peer is closed or when terminal input produces an EOF condition.

The writable direction may still exist independently.

=head1 PAUSING INPUT

=head2 pause_read

  $tty->pause_read;

Temporarily stop application input delivery.

=head2 resume_read

  $tty->resume_read;

Resume input delivery.

A configured read timeout is suspended while input is deliberately paused.

=head1 CALLBACKS

TTY callbacks may be constructor coderefs or subclass methods.

The normal callbacks are:

=over 4

=item C<on_data($tty, $bytes)>

Raw unframed input arrived.

=item C<on_message($tty, $message)>

One complete framed message arrived.

=item C<on_messages($tty, $messages)>

A batch of framed messages arrived when message batching is enabled.

=item C<on_drain($tty)>

Queued output fell to the low watermark after backpressure.

=item C<on_eof($tty)>

The readable direction reached EOF.

=item C<on_error($tty, $error)>

An asynchronous I/O, framing, timeout, or queue-limit error occurred.

=item C<on_close($tty)>

The TTY closed.

=back

A constructor callback overrides a same-named subclass method for that object.

=head1 APPLICATION DATA

Arbitrary application state may be attached to the TTY:

  my $tty = Linux::Event::IO::TTY->new(
      read_fh => \*STDIN,
      data    => $state,
      ...
  );

and retrieved through:

  my $state = $tty->data;

=head1 CLOSING DIRECTIONS

A TTY with separate read and write directions can control them independently.

In the default borrowed-handle mode, directional close stops Linux::Event from
using that direction but does not close the caller's terminal handle.

If another direction remains active, restoration of borrowed descriptor flags
is deferred until the complete TTY becomes terminal. This avoids changing
descriptor state out from under the still-active direction.

With C<owns_handles =E<gt> 1>, released distinct directional handles are closed
as part of the owning lifecycle.

=head2 close_read

  $tty->close_read;

Stop the readable direction immediately.

The writable direction may remain active.

=head2 close_write

  $tty->close_write;

Stop the writable direction immediately.

The readable direction may remain active.

=head2 end

  $tty->end;

Allow already accepted output to drain and then end the writable direction.

Use this when pending output should finish before the writable side ends.

=head2 close

  $tty->close;

Make the whole TTY terminal immediately.

For the default borrowed TTY, C<close> leaves the supplied handles open and
restores their captured file status and descriptor flags.

For C<owns_handles =E<gt> 1>, C<close> closes the owned handles.

=head1 DETACHING TERMINAL HANDLES

=head2 detach

  my $handles = $tty->detach;

Stop Linux::Event management and return the still-open terminal handles.

The return value is a hash reference containing:

  read_fh
  write_fh

as applicable.

For example:

  my $handles = $tty->detach;

  my $input  = $handles->{read_fh};
  my $output = $handles->{write_fh};

Detachment requires the output queue to be empty.

It is terminal for the TTY object and does not call C<on_close>.

For the default borrowed TTY, C<detach> restores the file status and descriptor
flags captured at construction before returning the handles.

For C<owns_handles =E<gt> 1>, C<detach> transfers ownership of the still-open
handles to the caller. Those owned handles retain their current nonblocking and
close-on-exec descriptor configuration.

Neither C<close> nor C<detach> changes terminal mode or restores termios state,
because Linux::Event did not configure termios state in the first place.

=head1 SUBCLASSING

Subclassing is optional.

Constructor callbacks are often simplest for one terminal:

  my $tty = Linux::Event::IO::TTY->new(
      read_fh => \*STDIN,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

A subclass is useful when many TTY objects share framing, callbacks, or tuning:

  package CommandConsole;

  use parent 'Linux::Event::IO::TTY';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $command) {
      ...
  }

=head1 STREAM TUNING

TTY uses the common ordered-byte tuning model.

Most applications should leave the defaults unchanged.

Reusable defaults may be declared by a subclass with C<stream_tuning>:

  package InteractiveTTY;

  use parent 'Linux::Event::IO::TTY';

  sub stream_tuning ($class) {
      return (
          read_size         => 16_384,
          read_budget_bytes => 65_536,
          max_buffer        => 1_048_576,
      );
  }

C<stream_tuning> is subclass policy.

The values below do not go inside a constructor C<tuning> hash.

The timeout values C<idle_timeout>, C<read_timeout>, and C<write_timeout> may
also be overridden directly for one TTY in C<new>.

=head2 read_size

Default: 65,536 bytes.

Maximum number of bytes requested by one native read.

=head2 read_budget_bytes

Default: 65,536 bytes.

Maximum amount of input processed during one readiness turn before yielding to
other Loop resources.

This is a fairness control.

A value of zero means to continue reading until the descriptor would block.

=head2 read_batch_bytes

Default: 0.

For an unframed TTY, successful reads may be combined before C<on_data> is
called.

Zero preserves normal read callback boundaries.

This option cannot be used with framing.

=head2 message_batch_size

Default: 0.

For a framed TTY, deliver up to this many complete messages together through
C<on_messages>.

Zero uses normal C<on_message> delivery.

A positive value requires framing and an C<on_messages> callback.

=head2 max_buffer

Default: 8,388,608 bytes.

Hard limit for retained input, incomplete framing data, and retained message
batch data.

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

Hard limit on queued output bytes.

Zero means no hard output-queue limit.

=head2 idle_timeout

Default: 0.

Maximum number of seconds without successful input or output progress.

Zero disables the timeout.

=head2 read_timeout

Default: 0.

Maximum number of seconds without inbound progress while reading is active.

C<pause_read> suspends this timeout.

Zero disables it.

=head2 write_timeout

Default: 0.

Maximum number of seconds without output progress while data remains queued.

Zero disables it.

=head1 PER-OBJECT TIMEOUTS AND DEADLINES

Timeout overrides for one TTY are top-level constructor options:

  my $tty = Linux::Event::IO::TTY->new(
      loop    => $loop,
      read_fh => \*STDIN,

      idle_timeout => 300,
      read_timeout => 60,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

An explicit operation deadline is also a top-level C<new> option, but its value
is a hash describing the deadline:

  my $tty = Linux::Event::IO::TTY->new(
      loop    => $loop,
      read_fh => \*STDIN,

      deadline => {
          after     => 30,
          operation => 'initial_input',
      },

      on_data => sub ($self, $bytes) {
          ...
      },
  );

A deadline requires exactly one of C<after> or C<at>, plus a non-empty
C<operation> name.

These settings do not go inside a nested C<tuning> hash.

See F<docs/ORDERED-BYTE-DEADLINES.md> for the full deadline model.

=head1 CHANGING TUNING AT RUNTIME

=head2 tune

A live TTY may change its mutable ordered-byte policy:

  $tty->tune(
      read_budget_bytes => 131_072,
      idle_timeout      => 120,
  );

C<tune> supports the same mutable ordered-byte settings used by Stream and
Pipe.

It returns the TTY object.

Tuning does not change terminal mode or termios configuration.

=head1 INFORMATION METHODS

=head2 fh

Return the shared handle when the same descriptor supplies both reading and
writing.

If separate descriptors are used, C<fh> returns undef.

=head2 read_fh

Return the readable terminal handle when present.

=head2 write_fh

Return the writable terminal handle when present.

=head2 read_fd

Return the readable file descriptor when present.

=head2 write_fd

Return the writable file descriptor when present.

=head2 has_read

Return true when the TTY has a readable direction.

=head2 has_write

Return true when the TTY has a writable direction.

=head2 pending_bytes

Return the number of bytes currently queued for output.

=head2 state

Return the current TTY lifecycle state.

=head2 is_read_paused

Return true while application reading is paused.

=head2 is_read_eof

Return true after the readable direction reaches EOF.

=head2 is_read_closed

Return true after the readable direction has been closed.

=head2 is_write_ended

Return true after the writable direction has ended.

=head2 last_error

Return the most recently stored L<Linux::Event::Error>, when one exists.

=head1 PERFORMANCE MODEL

TTY uses Linux::Event's native ordered-byte engine.

Callbacks and reusable subclass policy are resolved when the object is created,
rather than repeatedly looked up for every terminal readiness event.

Framing, buffering, output queuing, and backpressure are handled before control
returns to application callbacks.

These details normally require no application action.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::Framer>,
L<Linux::Event::Error>,
F<docs/ORDERED-BYTE-IO-DESIGN.md>,
F<docs/ORDERED-BYTE-DEADLINES.md>.

=cut
