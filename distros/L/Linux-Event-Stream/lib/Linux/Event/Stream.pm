package Linux::Event::Stream;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.002';

use Carp qw(croak);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Scalar::Util qw(reftype);

use Linux::Event::Stream::Codec::Line ();
use Linux::Event::Stream::Codec::Netstring ();
use Linux::Event::Stream::Codec::U32BE ();

# Watcher callbacks: ($loop, $fh, $watcher)
# The Stream instance is stored in $watcher->data.
sub _watch_read_cb  ($loop, $fh, $watcher) { my $self = $watcher->data or return; _on_read_ready($self, $watcher, $fh) }
sub _watch_write_cb ($loop, $fh, $watcher) { my $self = $watcher->data or return; _on_write_ready($self, $watcher, $fh) }
sub _watch_error_cb ($loop, $fh, $watcher) { my $self = $watcher->data or return; _on_error_ready($self, $watcher, $fh) }

sub new ($class, %opt) {
  my $loop = delete $opt{loop} // croak 'new(): missing loop';
  my $fh   = delete $opt{fh}   // croak 'new(): missing fh';

  my $on_read  = delete $opt{on_read};
  my $on_message = delete $opt{on_message};
  my $on_error = delete $opt{on_error};
  my $on_close = delete $opt{on_close};

  croak 'on_read must be a coderef'  if defined $on_read  && ref($on_read)  ne 'CODE';
  croak 'on_message must be a coderef' if defined $on_message && ref($on_message) ne 'CODE';
  croak 'on_error must be a coderef' if defined $on_error && ref($on_error) ne 'CODE';
  croak 'on_close must be a coderef' if defined $on_close && ref($on_close) ne 'CODE';

  my $codec   = delete $opt{codec};
  my $decoder = delete $opt{decoder};
  my $encoder = delete $opt{encoder};

  croak 'use either codec or decoder/encoder, not both'
    if defined($codec) && (defined($decoder) || defined($encoder));

  # Framed/message mode is enabled by providing on_message.
  my $framed = defined($on_message) ? 1 : 0;
  croak 'on_read is not used when on_message is provided; use on_message + codec'
    if $framed && defined $on_read;

  my $data = delete $opt{data};

  my $high = delete $opt{high_watermark} // 1_048_576;
  my $low  = delete $opt{low_watermark}  //   262_144;
  $low = $high if $low > $high;

  my $read_size = delete $opt{read_size} // 8192;
  my $max_read_per_tick = delete $opt{max_read_per_tick} // 0;

  my $max_inbuf = delete $opt{max_inbuf};
  $max_inbuf //= 1_048_576 if $framed;

  my $close_fh = delete $opt{close_fh} // 0;

  if ($framed) {
    $codec = $decoder // $encoder // $codec;
    croak 'new(): missing codec (required with on_message)' if !defined $codec;

    if (!ref($codec)) {
      $codec =
        $codec eq 'line'      ? Linux::Event::Stream::Codec::Line->new :
        $codec eq 'netstring' ? Linux::Event::Stream::Codec::Netstring->new :
        $codec eq 'u32be'     ? Linux::Event::Stream::Codec::U32BE->new :
        croak "unknown codec alias: $codec";
    }

    croak 'codec must be a hashref (or blessed hashref)'
      if !defined(reftype($codec)) || reftype($codec) ne 'HASH';
    croak 'codec->{decode} must be a coderef' if ref($codec->{decode}) ne 'CODE';
    croak 'codec->{encode} must be a coderef' if ref($codec->{encode}) ne 'CODE';
  }

  croak 'unknown options: ' . join(', ', sort keys %opt) if %opt;

  _set_nonblocking($fh);

  my $self = bless {
    loop => $loop,
    fh   => $fh,

    # raw bytes mode
    on_read  => $on_read,

    # framed/message mode
    on_message => $on_message,
    codec      => $codec,
    rbuf       => '',
    max_inbuf  => $max_inbuf,

    on_error => $on_error,
    on_close => $on_close,
    data     => $data,

    last_error => undef,

    # write buffering
    wbuf => '',
    woff => 0,

    high_watermark => $high,
    low_watermark  => $low,

    read_size         => $read_size,
    max_read_per_tick => $max_read_per_tick,

    # state
    closed        => 0,
    closing       => 0,
    read_paused   => 0,
    write_blocked => 0,
    close_fh      => $close_fh,
    close_cb_fired => 0,

    watcher => undef,
  }, $class;

  my $w = $loop->watch($fh,
    read  => \&_watch_read_cb,
    write => \&_watch_write_cb,
    error => \&_watch_error_cb,
    data  => $self,
  );

  $self->{watcher} = $w;

  # Do not arm write notifications until there is buffered data.
  $w->disable_write;

  return $self;
}

sub fh ($self) { $self->{fh} }

sub is_closed  ($self) { !!$self->{closed} }
sub is_closing ($self) { !!$self->{closing} }

sub buffered_bytes ($self) {
  my $len = length($self->{wbuf} // '');
  my $off = $self->{woff} // 0;
  return $len > $off ? ($len - $off) : 0;
}

sub is_write_blocked ($self) { !!$self->{write_blocked} }

sub last_error ($self) { $self->{last_error} }

sub write ($self, $bytes) {
  return 0 if $self->{closed};
  return 1 if !defined($bytes) || $bytes eq '';

  # Fast path: attempt to write immediately when there is no pending buffer.
  # This reduces latency and avoids reliance on EPOLLOUT notifications to start a drain.
  if ($self->buffered_bytes == 0) {
    my $n = syswrite($self->{fh}, $bytes);
    if (defined $n) {
      return 1 if $n == length($bytes);
      # partial: buffer remainder
      substr($bytes, 0, $n, '');
    } else {
      my $errno = $! + 0;
      # EAGAIN: buffer whole payload
      if ($errno != 11) {
        $self->{last_error} = "io:$errno";
        _fire_on_error($self, $errno);
        _close_now($self);
        return 0;
      }
    }
  }

  # Buffer what remains (or all, if immediate write did not happen).
  my $buf = $self->{wbuf};
  my $off = $self->{woff};

  if ($off && ($off > 65_536 || $off > (length($buf) >> 1))) {
    substr($buf, 0, $off, '');
    $off = 0;
  }

  $buf .= $bytes;

  $self->{wbuf} = $buf;
  $self->{woff} = $off;

  my $pending = length($buf) - $off;
  if (!$self->{write_blocked} && $pending > $self->{high_watermark}) {
    $self->{write_blocked} = 1;
  }

  $self->{watcher}->enable_write;
  return 1;
}

sub write_message ($self, $msg) {
  return 0 if $self->{closed};
  my $codec = $self->{codec} // croak 'write_message() requires a codec (use on_message mode)';
  my $bytes = $codec->{encode}->($codec, $msg);
  return $self->write($bytes);
}

sub pause_read ($self) {
  return $self if $self->{closed} || $self->{read_paused};
  $self->{read_paused} = 1;
  $self->{watcher}->disable_read;
  return $self;
}

sub resume_read ($self) {
  return $self if $self->{closed} || !$self->{read_paused} || $self->{closing};
  $self->{read_paused} = 0;
  $self->{watcher}->enable_read;
  return $self;
}

sub close_after_drain ($self) {
  return $self if $self->{closed};
  $self->{closing} = 1;

  $self->pause_read;

  if ($self->buffered_bytes == 0) {
    _close_now($self);
  } else {
    $self->{watcher}->enable_write;
  }

  return $self;
}

sub close ($self) {
  return $self if $self->{closed};
  _close_now($self);
  return $self;
}

# ---- internals ----

sub _set_nonblocking ($fh) {
  my $flags = fcntl($fh, F_GETFL, 0);
  return if !defined $flags;        # best-effort
  return if ($flags & O_NONBLOCK);
  fcntl($fh, F_SETFL, $flags | O_NONBLOCK);
  return;
}

sub _fire_on_error ($self, $errno) {
  $self->{last_error} //= ($errno ? "io:$errno" : 'error');
  my $cb = $self->{on_error} or return;
  $cb->($self, $errno, $self->{data});
  return;
}

sub _fire_on_close ($self) {
  return if $self->{close_cb_fired}++;
  my $cb = $self->{on_close} or return;
  $cb->($self, $self->{data});
  return;
}

sub _close_now ($self) {
  return if $self->{closed};

  $self->{closed}  = 1;
  $self->{closing} = 0;

  if (my $w = $self->{watcher}) {
    $w->cancel;
  }

  if ($self->{close_fh}) {
    CORE::close($self->{fh});
  }

  _fire_on_close($self);
  return;
}

sub _on_read_ready ($self, $watcher, $fh) {
  return if $self->{closed} || $self->{read_paused} || $self->{closing};

  my $read_size = $self->{read_size};
  my $max_bytes = $self->{max_read_per_tick};

  my $total = 0;

  while (1) {
    my $bytes = '';
    my $n = sysread($fh, $bytes, $read_size);

    if (defined $n) {
      if ($n == 0) {
        _close_now($self);
        return;
      }

      $total += $n;

      if (my $cb = $self->{on_read}) {
        # raw bytes mode
        $cb->($self, $bytes, $self->{data});
      } elsif (my $on_message = $self->{on_message}) {
        # framed/message mode
        my $rbuf = $self->{rbuf};
        $rbuf .= $bytes;

        my $max = $self->{max_inbuf};
        if (defined($max) && length($rbuf) > $max) {
          $self->{last_error} = "codec:max_inbuf_exceeded:$max";
          _fire_on_error($self, 0);
          _close_now($self);
          return;
        }

        my @out;
        my $codec = $self->{codec};
        my ($ok, $err) = $codec->{decode}->($codec, \$rbuf, \@out);
        if (!$ok) {
          $err //= 'decode error';
          $self->{last_error} = "codec:$err";
          _fire_on_error($self, 0);
          _close_now($self);
          return;
        }

        $self->{rbuf} = $rbuf;

        for my $msg (@out) {
          $on_message->($self, $msg, $self->{data});
          last if $self->{closed} || $self->{read_paused} || $self->{closing};
        }
      }

      last if $self->{closed} || $self->{read_paused} || $self->{closing};
      last if $max_bytes && $total >= $max_bytes;

      next;
    }

    my $errno = $! + 0;
    return if $errno == 11; # EAGAIN on Linux

    $self->{last_error} = "io:$errno";
    _fire_on_error($self, $errno);
    _close_now($self);
    return;
  }

  return;
}

sub _on_write_ready ($self, $watcher, $fh) {
  return if $self->{closed};

  my $buf = $self->{wbuf};
  my $off = $self->{woff};

  my $pending = length($buf) - $off;

  if ($pending <= 0) {
    $self->{wbuf} = '';
    $self->{woff} = 0;
    $watcher->disable_write;
    _close_now($self) if $self->{closing};
    return;
  }

  while ($pending > 0) {
    my $n = syswrite($fh, $buf, $pending, $off);

    if (defined $n) {
      $off     += $n;
      $pending -= $n;

      # FIX: persist partial progress so buffered_bytes() and watermark state
      # can advance even when we return on EAGAIN later.
      $self->{woff} = $off;

      if ($self->{write_blocked} && $pending < $self->{low_watermark}) {
        $self->{write_blocked} = 0;
      }

      next;
    }

    my $errno = $! + 0;

    # FIX: also persist offset before returning.
    $self->{woff} = $off;

    return if $errno == 11; # EAGAIN on Linux

    $self->{last_error} = "io:$errno";
    _fire_on_error($self, $errno);
    _close_now($self);
    return;
  }

  # drained
  $self->{wbuf} = '';
  $self->{woff} = 0;
  $watcher->disable_write;

  _close_now($self) if $self->{closing};
  return;
}

sub _on_error_ready ($self, $watcher, $fh) {
  return if $self->{closed};

  my $errno = $! + 0;
  $errno = 5 if !$errno; # EIO fallback

  $self->{last_error} = "io:$errno";
  _fire_on_error($self, $errno);
  _close_now($self);
  return;
}

1;

__END__

=head1 NAME

Linux::Event::Stream - Buffered, backpressure-aware I/O for nonblocking file descriptors

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;
  use Linux::Event::Stream;

  my $loop = Linux::Event->new;

  # Raw bytes mode (TCP/pipes): on_read receives arbitrary chunks.
  my $stream = Linux::Event::Stream->new(
    loop => $loop,
    fh   => $fh,

    on_read  => sub ($stream, $bytes, $data) {
      # Called whenever bytes are received.
      # If you call $stream->close or $stream->close_after_drain here,
      # further callbacks will not be invoked.
    },

    on_error => sub ($stream, $errno, $data) {
      # Called on fatal I/O error. Stream will close immediately after this.
    },

    on_close => sub ($stream, $data) {
      # Called exactly once when the stream closes.
    },

    high_watermark => 1_048_576,  # bytes
    low_watermark  =>   262_144,  # bytes

    read_size         => 8192,
    max_read_per_tick => 0,

    data => $user_data,
  );

  $stream->write("hello\n");
  $loop->run;

  # Framed/message mode: on_message receives complete messages.
  my $framed = Linux::Event::Stream->new(
    loop       => $loop,
    fh         => $fh,
    codec      => 'line',
    on_message => sub ($stream, $line, $data) {
      # Called for each complete line ("\n" removed by the default line codec).
      $stream->write_message("echo: $line");
    },
  );

=head1 DESCRIPTION

B<Linux::Event::Stream> provides buffered, backpressure-aware I/O on top of
L<Linux::Event> watchers.

It wraps a nonblocking file descriptor and adds:

=over 4

=item *

Write buffering

=item *

High/low watermark backpressure tracking (hysteresis latch)

=item *

Graceful close-after-drain support

=item *

Optional read throttling

=back

Stream does not create sockets or modify the event loop. It is a small policy
layer over a file descriptor.

In raw mode, Stream delivers arbitrary byte chunks via C<on_read>.

In framed/message mode, Stream buffers incoming bytes internally and uses a
codec to emit complete messages via C<on_message>.

=head1 CONSTRUCTOR

=head2 new(%args)

Required arguments:

=over 4

=item loop

A L<Linux::Event> loop instance.

=item fh

A filehandle or socket. It will be placed into nonblocking mode.

=back

Optional arguments:

=over 4


=item on_read => sub ($stream, $bytes, $data)

Raw bytes mode.

Called whenever bytes are read.

This callback may call C<close> or C<close_after_drain>.

=item codec

Framed/message mode.

Required when using C<on_message>.

May be either a codec object (a hashref with C<decode> and C<encode> coderefs),
or one of the builtin aliases:

=over 4

=item *

C<line> - newline-delimited messages

=item *

C<netstring> - C<< <len>:<payload>, >>

=item *

C<u32be> - 32-bit big-endian length prefix

=back

=item on_message => sub ($stream, $msg, $data)

Framed/message mode.

Enables internal read buffering and emits complete messages produced by the
codec.

When C<on_message> is provided, C<on_read> is not used.

=item max_inbuf

Framed/message mode.

Maximum buffered undecoded bytes (default 1MB). If exceeded, Stream fires
C<on_error> with errno 0, sets C<last_error>, and closes.

=item on_error => sub ($stream, $errno, $data)

Called when a fatal I/O error occurs.

After firing C<on_error>, the stream closes immediately (buffer is discarded)
and then C<on_close> fires.

=item on_close => sub ($stream, $data)

Called exactly once when the stream closes (for any reason).

=item high_watermark

Defaults to 1MB.

If pending buffered bytes exceed this value, C<is_write_blocked> becomes true.

=item low_watermark

Defaults to 256KB.

When pending buffered bytes drop below this value, C<is_write_blocked> becomes
false.

If low_watermark is greater than high_watermark, it is clamped to high_watermark.

=item read_size

Maximum bytes per sysread() call (default 8192).

=item max_read_per_tick

Limit total bytes read per loop tick. 0 means unlimited.

=item data

Opaque user data passed to callbacks.

=item close_fh

If true, the underlying filehandle is closed when the stream closes.

By default Stream does not assume ownership of the filehandle.

=back

=head1 METHODS

=head2 write($bytes)

Queues bytes for sending and returns true if the bytes were accepted for
buffering.

If there is no pending buffered data, Stream attempts an immediate syswrite()
before buffering the remainder.

A true return value does not imply that the peer has received the bytes; delivery
is asynchronous.

=head2 buffered_bytes

Returns the number of bytes currently buffered and not yet written to the file
descriptor.

=head2 is_write_blocked

Returns true if Stream is in a backpressured state due to the configured
watermarks.

This is a hysteresis latch: it becomes true above C<high_watermark> and becomes
false below C<low_watermark>.

=head2 pause_read

Disables read notifications.

=head2 resume_read

Re-enables read notifications (unless the stream is closing).

=head2 close

Immediately closes the stream.

Buffered data is discarded.

=head2 close_after_drain

Stops reading and closes once all buffered data has been written.

=head2 is_closed

Returns true once closed.

=head2 is_closing

Returns true if C<close_after_drain> has been requested (the stream is closing
but may still have buffered bytes to write).

=head2 write_message($msg)

Framed/message mode.

Encodes C<$msg> using the configured codec and then writes the resulting bytes.

Returns true if the encoded bytes were accepted for buffering.

=head2 last_error

Returns the last non-EOF error recorded by the stream.

For I/O errors, C<on_error> receives a non-zero errno.

For codec/buffer errors in framed mode, C<on_error> receives errno 0 and
C<last_error> contains a string like C<codec:...>.

=head1 CODEC CONTRACT

In framed/message mode, Stream expects a codec object that is a hashref (or a
blessed hashref) with two coderefs:

=over 4

=item *

C<< $codec->{decode}->($codec, \$inbuf, \@out) >>

Consumes from C<$$inbuf> (in place) and pushes zero or more decoded messages
onto C<@out>. Returns true on success, or C<(0, $err)> on failure.

=item *

C<< $codec->{encode}->($codec, $msg) >>

Returns a byte string to write for the given message.

=back

Stream validates the codec once at construction time and calls these coderefs
directly on the hot path to avoid per-message method dispatch overhead.

=head1 BACKPRESSURE SEMANTICS

Watermarks operate on pending buffered bytes (C<buffered_bytes>).

C<is_write_blocked> transitions:

=over 4

=item *

false -> true when buffered_bytes > high_watermark

=item *

true -> false when buffered_bytes < low_watermark

=back

The transition back to false occurs inside the WRITE-ready drain path, not
necessarily during a READ event on the peer.

=head1 INTEGRATION NOTES

Stream is intended to be composed by higher-level modules (for example a future
C<Linux::Event::Listen> connection wrapper) to provide consistent buffered I/O
and backpressure behavior.

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=cut
