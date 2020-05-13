#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006-2020 -- leonerd@leonerd.org.uk

package IO::Async::Stream;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( IO::Async::Handle );

use Errno qw( EAGAIN EWOULDBLOCK EINTR EPIPE );

use Carp;

use Encode 2.11 qw( find_encoding STOP_AT_PARTIAL );
use Scalar::Util qw( blessed );

use IO::Async::Debug;
use IO::Async::Metrics '$METRICS';

# Tuneable from outside
# Not yet documented
our $READLEN  = 8192;
our $WRITELEN = 8192;

use Struct::Dumb;

# Element of the writequeue
struct Writer => [qw( data writelen on_write on_flush on_error watching )];

# Element of the readqueue
struct Reader => [qw( on_read future )];

# Bitfields in the want flags
use constant WANT_READ_FOR_READ   => 0x01;
use constant WANT_READ_FOR_WRITE  => 0x02;
use constant WANT_WRITE_FOR_READ  => 0x04;
use constant WANT_WRITE_FOR_WRITE => 0x08;
use constant WANT_ANY_READ  => WANT_READ_FOR_READ |WANT_READ_FOR_WRITE;
use constant WANT_ANY_WRITE => WANT_WRITE_FOR_READ|WANT_WRITE_FOR_WRITE;

=head1 NAME

C<IO::Async::Stream> - event callbacks and write bufering for a stream
filehandle

=head1 SYNOPSIS

 use IO::Async::Stream;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $stream = IO::Async::Stream->new(
    read_handle  => \*STDIN,
    write_handle => \*STDOUT,

    on_read => sub {
       my ( $self, $buffref, $eof ) = @_;

       while( $$buffref =~ s/^(.*\n)// ) {
          print "Received a line $1";
       }

       if( $eof ) {
          print "EOF; last partial line is $$buffref\n";
       }

       return 0;
    }
 );

 $loop->add( $stream );

 $stream->write( "An initial line here\n" );

=head1 DESCRIPTION

This subclass of L<IO::Async::Handle> contains a filehandle that represents
a byte-stream. It provides buffering for both incoming and outgoing data. It
invokes the C<on_read> handler when new data is read from the filehandle. Data
may be written to the filehandle by calling the C<write> method.

This class is suitable for any kind of filehandle that provides a
possibly-bidirectional reliable byte stream, such as a pipe, TTY, or
C<SOCK_STREAM> socket (such as TCP or a byte-oriented UNIX local socket). For
datagram or raw message-based sockets (such as UDP) see instead
L<IO::Async::Socket>.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 $ret = on_read \$buffer, $eof

Invoked when more data is available in the internal receiving buffer.

The first argument is a reference to a plain perl string. The code should
inspect and remove any data it likes, but is not required to remove all, or
indeed any of the data. Any data remaining in the buffer will be preserved for
the next call, the next time more data is received from the handle.

In this way, it is easy to implement code that reads records of some form when
completed, but ignores partially-received records, until all the data is
present. If the handler wishes to be immediately invoke a second time, to have
another attempt at consuming more content, it should return C<1>. Otherwise,
it should return C<0>, and the handler will next be invoked when more data has
arrived from the underlying read handle and appended to the buffer. This makes
it easy to implement code that handles multiple incoming records at the same
time. Alternatively, if the handler function already attempts to consume as
much as possible from the buffer, it will have no need to return C<1> at all.
See the examples at the end of this documentation for more detail.

The second argument is a scalar indicating whether the stream has reported an
end-of-file (EOF) condition. A reference to the buffer is passed to the
handler in the usual way, so it may inspect data contained in it. Once the
handler returns a false value, it will not be called again, as the handle is
now at EOF and no more data can arrive.

The C<on_read> code may also dynamically replace itself with a new callback
by returning a CODE reference instead of C<0> or C<1>. The original callback
or method that the object first started with may be restored by returning
C<undef>. Whenever the callback is changed in this way, the new code is called
again; even if the read buffer is currently empty. See the examples at the end
of this documentation for more detail.

The C<push_on_read> method can be used to insert new, temporary handlers that
take precedence over the global C<on_read> handler. This event is only used if
there are no further pending handlers created by C<push_on_read>.

=head2 on_read_eof

Optional. Invoked when the read handle indicates an end-of-file (EOF)
condition. If there is any data in the buffer still to be processed, the
C<on_read> event will be invoked first, before this one.

=head2 on_write_eof

Optional. Invoked when the write handle indicates an end-of-file (EOF)
condition. Note that this condition can only be detected after a C<write>
syscall returns the C<EPIPE> error. If there is no data pending to be written
then it will not be detected yet.

=head2 on_read_error $errno

Optional. Invoked when the C<sysread> method on the read handle fails.

=head2 on_write_error $errno

Optional. Invoked when the C<syswrite> method on the write handle fails.

The C<on_read_error> and C<on_write_error> handlers are passed the value of
C<$!> at the time the error occurred. (The C<$!> variable itself, by its
nature, may have changed from the original error by the time this handler
runs so it should always use the value passed in).

If an error occurs when the corresponding error callback is not supplied, and
there is not a handler for it, then the C<close> method is called instead.

=head2 on_read_high_watermark $length

=head2 on_read_low_watermark $length

Optional. Invoked when the read buffer grows larger than the high watermark
or smaller than the low watermark respectively. These are edge-triggered
events; they will only be triggered once per crossing, not continuously while
the buffer remains above or below the given limit.

If these event handlers are not defined, the default behaviour is to disable
read-ready notifications if the read buffer grows larger than the high
watermark (so as to avoid it growing arbitrarily if nothing is consuming it),
and re-enable notifications again once something has read enough to cause it to
drop. If these events are overridden, the overriding code will have to perform
this behaviour if required, by using

 $self->want_readready_for_read(...)

=head2 on_outgoing_empty

Optional. Invoked when the writing data buffer becomes empty.

=head2 on_writeable_start

=head2 on_writeable_stop

Optional. These two events inform when the filehandle becomes writeable, and
when it stops being writeable. C<on_writeable_start> is invoked by the
C<on_write_ready> event if previously it was known to be not writeable.
C<on_writeable_stop> is invoked after a C<syswrite> operation fails with
C<EAGAIN> or C<EWOULDBLOCK>. These two events track the writeability state,
and ensure that only state change cause events to be invoked. A stream starts
off being presumed writeable, so the first of these events to be observed will
be C<on_writeable_stop>.

=cut

sub _init
{
   my $self = shift;

   $self->{writequeue} = []; # Queue of Writers
   $self->{readqueue} = []; # Queue of Readers
   $self->{writeable} = 1; # "innocent until proven guilty" (by means of EAGAIN)
   $self->{readbuff} = "";

   $self->{reader} = "_sysread";
   $self->{writer} = "_syswrite";

   $self->{read_len}  = $READLEN;
   $self->{write_len} = $WRITELEN;

   $self->{want} = WANT_READ_FOR_READ;

   $self->{close_on_read_eof} = 1;
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 read_handle => IO

The IO handle to read from. Must implement C<fileno> and C<sysread> methods.

=head2 write_handle => IO

The IO handle to write to. Must implement C<fileno> and C<syswrite> methods.

=head2 handle => IO

Shortcut to specifying the same IO handle for both of the above.

=head2 on_read => CODE

=head2 on_read_error => CODE

=head2 on_outgoing_empty => CODE

=head2 on_write_error => CODE

=head2 on_writeable_start => CODE

=head2 on_writeable_stop => CODE

CODE references for event handlers.

=head2 autoflush => BOOL

Optional. If true, the C<write> method will attempt to write data to the
operating system immediately, without waiting for the loop to indicate the
filehandle is write-ready. This is useful, for example, on streams that should
contain up-to-date logging or console information.

It currently defaults to false for any file handle, but future versions of
L<IO::Async> may enable this by default on STDOUT and STDERR.

=head2 read_len => INT

Optional. Sets the buffer size for C<read> calls. Defaults to 8 KiBytes.

=head2 read_all => BOOL

Optional. If true, attempt to read as much data from the kernel as possible
when the handle becomes readable. By default this is turned off, meaning at
most one fixed-size buffer is read. If there is still more data in the
kernel's buffer, the handle will still be readable, and will be read from
again.

This behaviour allows multiple streams and sockets to be multiplexed
simultaneously, meaning that a large bulk transfer on one cannot starve other
filehandles of processing time. Turning this option on may improve bulk data
transfer rate, at the risk of delaying or stalling processing on other
filehandles.

=head2 write_len => INT

Optional. Sets the buffer size for C<write> calls. Defaults to 8 KiBytes.

=head2 write_all => BOOL

Optional. Analogous to the C<read_all> option, but for writing. When
C<autoflush> is enabled, this option only affects deferred writing if the
initial attempt failed due to buffer space.

=head2 read_high_watermark => INT

=head2 read_low_watermark => INT

Optional. If defined, gives a way to implement flow control or other
behaviours that depend on the size of Stream's read buffer.

If after more data is read from the underlying filehandle the read buffer is
now larger than the high watermark, the C<on_read_high_watermark> event is
triggered (which, by default, will disable read-ready notifications and pause
reading from the filehandle).

If after data is consumed by an C<on_read> handler the read buffer is now
smaller than the low watermark, the C<on_read_low_watermark> event is
triggered (which, by default, will re-enable read-ready notifications and
resume reading from the filehandle). For to be possible, the read handler
would have to be one added by the C<push_on_read> method or one of the
Future-returning C<read_*> methods.

By default these options are not defined, so this behaviour will not happen.
C<read_low_watermark> may not be set to a larger value than
C<read_high_watermark>, but it may be set to a smaller value, creating a
hysteresis region. If either option is defined then both must be.

If these options are used with the default event handlers, be careful not to
cause deadlocks by having a high watermark sufficiently low that a single
C<on_read> invocation might not consider it finished yet.

=head2 reader => STRING|CODE

=head2 writer => STRING|CODE

Optional. If defined, gives the name of a method or a CODE reference to use
to implement the actual reading from or writing to the filehandle. These will
be invoked as

 $stream->reader( $read_handle, $buffer, $len )
 $stream->writer( $write_handle, $buffer, $len )

Each is expected to modify the passed buffer; C<reader> by appending to it,
C<writer> by removing a prefix from it. Each is expected to return a true
value on success, zero on EOF, or C<undef> with C<$!> set for errors. If not
provided, they will be substituted by implenentations using C<sysread> and
C<syswrite> on the underlying handle, respectively.

=head2 close_on_read_eof => BOOL

Optional. Usually true, but if set to a false value then the stream will not
be C<close>d when an EOF condition occurs on read. This is normally not useful
as at that point the underlying stream filehandle is no longer useable, but it
may be useful for reading regular files, or interacting with TTY devices.

=head2 encoding => STRING

If supplied, sets the name of encoding of the underlying stream. If an
encoding is set, then the C<write> method will expect to receive Unicode
strings and encodes them into bytes, and incoming bytes will be decoded into
Unicode strings for the C<on_read> event.

If an encoding is not supplied then C<write> and C<on_read> will work in byte
strings.

I<IMPORTANT NOTE:> in order to handle reads of UTF-8 content or other
multibyte encodings, the code implementing the C<on_read> event uses a feature
of L<Encode>; the C<STOP_AT_PARTIAL> flag. While this flag has existed for a
while and is used by the C<:encoding> PerlIO layer itself for similar
purposes, the flag is not officially documented by the C<Encode> module. In
principle this undocumented feature could be subject to change, in practice I
believe it to be reasonably stable.

This note applies only to the C<on_read> event; data written using the
C<write> method does not rely on any undocumented features of C<Encode>.

If a read handle is given, it is required that either an C<on_read> callback
reference is configured, or that the object provides an C<on_read> method. It
is optional whether either is true for C<on_outgoing_empty>; if neither is
supplied then no action will be taken when the writing buffer becomes empty.

An C<on_read> handler may be supplied even if no read handle is yet given, to
be used when a read handle is eventually provided by the C<set_handles>
method.

This condition is checked at the time the object is added to a Loop; it is
allowed to create a C<IO::Async::Stream> object with a read handle but without
a C<on_read> handler, provided that one is later given using C<configure>
before the stream is added to its containing Loop, either directly or by being
a child of another Notifier already in a Loop, or added to one.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   for (qw( on_read on_outgoing_empty on_read_eof on_write_eof on_read_error
            on_write_error on_writeable_start on_writeable_stop autoflush
            read_len read_all write_len write_all on_read_high_watermark
            on_read_low_watermark reader writer close_on_read_eof )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   if( exists $params{read_high_watermark} or exists $params{read_low_watermark} ) {
      my $high = delete $params{read_high_watermark};
      defined $high or $high = $self->{read_high_watermark};

      my $low  = delete $params{read_low_watermark};
      defined $low  or $low  = $self->{read_low_watermark};

      croak "Cannot set read_low_watermark without read_high_watermark" if defined $low and !defined $high;
      croak "Cannot set read_high_watermark without read_low_watermark" if defined $high and !defined $low;

      croak "Cannot set read_low_watermark higher than read_high_watermark" if defined $low and defined $high and $low > $high;

      $self->{read_high_watermark} = $high;
      $self->{read_low_watermark}  = $low;

      # TODO: reassert levels if we've moved them
   }

   if( exists $params{encoding} ) {
      my $encoding = delete $params{encoding};
      my $obj = find_encoding( $encoding );
      defined $obj or croak "Cannot handle an encoding of '$encoding'";
      $self->{encoding} = $obj;
   }

   $self->SUPER::configure( %params );

   if( $self->loop and $self->read_handle ) {
      $self->can_event( "on_read" ) or
         croak 'Expected either an on_read callback or to be able to ->on_read';
   }

   if( $self->{autoflush} and my $write_handle = $self->write_handle ) {
      carp "An IO::Async::Stream with autoflush needs an O_NONBLOCK write handle"
         if $write_handle->blocking;
   }
}

sub _add_to_loop
{
   my $self = shift;

   if( defined $self->read_handle ) {
      $self->can_event( "on_read" ) or
         croak 'Expected either an on_read callback or to be able to ->on_read';
   }

   $self->SUPER::_add_to_loop( @_ );

   if( !$self->_is_empty ) {
      $self->want_writeready_for_write( 1 );
   }
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 want_readready_for_read

=head2 want_readready_for_write

   $stream->want_readready_for_read( $set )

   $stream->want_readready_for_write( $set )

Mutators for the C<want_readready> property on L<IO::Async::Handle>, which
control whether the C<read> or C<write> behaviour should be continued once the
filehandle becomes ready for read.

Normally, C<want_readready_for_read> is always true (though the read watermark
behaviour can modify it), and C<want_readready_for_write> is not used.
However, if a custom C<writer> function is provided, it may find this useful
for being invoked again if it cannot proceed with a write operation until the
filehandle becomes readable (such as during transport negotiation or SSL key
management, for example).

=cut

sub want_readready_for_read
{
   my $self = shift;
   my ( $set ) = @_;
   $set ? ( $self->{want} |= WANT_READ_FOR_READ ) : ( $self->{want} &= ~WANT_READ_FOR_READ );

   $self->want_readready( $self->{want} & WANT_ANY_READ ) if $self->read_handle;
}

sub want_readready_for_write
{
   my $self = shift;
   my ( $set ) = @_;
   $set ? ( $self->{want} |= WANT_READ_FOR_WRITE ) : ( $self->{want} &= ~WANT_READ_FOR_WRITE );

   $self->want_readready( $self->{want} & WANT_ANY_READ ) if $self->read_handle;
}

=head2 want_writeready_for_read

=head2 want_writeready_for_write

   $stream->want_writeready_for_write( $set )

   $stream->want_writeready_for_read( $set )

Mutators for the C<want_writeready> property on L<IO::Async::Handle>, which
control whether the C<write> or C<read> behaviour should be continued once the
filehandle becomes ready for write.

Normally, C<want_writeready_for_write> is managed by the C<write> method and
associated flushing, and C<want_writeready_for_read> is not used. However, if
a custom C<reader> function is provided, it may find this useful for being
invoked again if it cannot proceed with a read operation until the filehandle
becomes writable (such as during transport negotiation or SSL key management,
for example).

=cut

sub want_writeready_for_write
{
   my $self = shift;
   my ( $set ) = @_;
   $set ? ( $self->{want} |= WANT_WRITE_FOR_WRITE ) : ( $self->{want} &= ~WANT_WRITE_FOR_WRITE );

   $self->want_writeready( $self->{want} & WANT_ANY_WRITE ) if $self->write_handle;
}

sub want_writeready_for_read
{
   my $self = shift;
   my ( $set ) = @_;
   $set ? ( $self->{want} |= WANT_WRITE_FOR_READ ) : ( $self->{want} &= ~WANT_WRITE_FOR_READ );

   $self->want_writeready( $self->{want} & WANT_ANY_WRITE ) if $self->write_handle;
}

# FUNCTION not method
sub _nonfatal_error
{
   my ( $errno ) = @_;

   return $errno == EAGAIN ||
          $errno == EWOULDBLOCK ||
          $errno == EINTR;
}

sub _is_empty
{
   my $self = shift;
   return !@{ $self->{writequeue} };
}

=head2 close

   $stream->close

A synonym for C<close_when_empty>. This should not be used when the deferred
wait behaviour is required, as the behaviour of C<close> may change in a
future version of L<IO::Async>. Instead, call C<close_when_empty> directly.

=cut

sub close
{
   my $self = shift;
   $self->close_when_empty;
}

=head2 close_when_empty

   $stream->close_when_empty

If the write buffer is empty, this method calls C<close> on the underlying IO
handles, and removes the stream from its containing loop. If the write buffer
still contains data, then this is deferred until the buffer is empty. This is
intended for "write-then-close" one-shot streams.

 $stream->write( "Here is my final data\n" );
 $stream->close_when_empty;

Because of this deferred nature, it may not be suitable for error handling.
See instead the C<close_now> method.

=cut

sub close_when_empty
{
   my $self = shift;

   return $self->SUPER::close if $self->_is_empty;

   $self->{stream_closing} = 1;
}

=head2 close_now

   $stream->close_now

This method immediately closes the underlying IO handles and removes the
stream from the containing loop. It will not wait to flush the remaining data
in the write buffer.

=cut

sub close_now
{
   my $self = shift;

   foreach ( @{ $self->{writequeue} } ) {
       $_->on_error->( $self, "stream closing" ) if $_->on_error;
   }

   undef @{ $self->{writequeue} };
   undef $self->{stream_closing};

   $self->SUPER::close;
}

=head2 is_read_eof

=head2 is_write_eof

   $eof = $stream->is_read_eof

   $eof = $stream->is_write_eof

Returns true after an EOF condition is reported on either the read or the
write handle, respectively.

=cut

sub is_read_eof
{
   my $self = shift;
   return $self->{read_eof};
}

sub is_write_eof
{
   my $self = shift;
   return $self->{write_eof};
}

=head2 write

   $stream->write( $data, %params )

This method adds data to the outgoing data queue, or writes it immediately,
according to the C<autoflush> parameter.

If the C<autoflush> option is set, this method will try immediately to write
the data to the underlying filehandle. If this completes successfully then it
will have been written by the time this method returns. If it fails to write
completely, then the data is queued as if C<autoflush> were not set, and will
be flushed as normal.

C<$data> can either be a plain string, a L<Future>, or a CODE reference. If it
is a plain string it is written immediately. If it is not, its value will be
used to generate more C<$data> values, eventually leading to strings to be
written.

If C<$data> is a C<Future>, the Stream will wait until it is ready, and take
the single value it yields.

If C<$data> is a CODE reference, it will be repeatedly invoked to generate new
values. Each time the filehandle is ready to write more data to it, the
function is invoked. Once the function has finished generating data it should
return undef. The function is passed the Stream object as its first argument.

It is allowed that C<Future>s yield CODE references, or CODE references return
C<Future>s, as well as plain strings.

For example, to stream the contents of an existing opened filehandle:

 open my $fileh, "<", $path or die "Cannot open $path - $!";

 $stream->write( sub {
    my ( $stream ) = @_;

    sysread $fileh, my $buffer, 8192 or return;
    return $buffer;
 } );

Takes the following optional named parameters in C<%params>:

=over 8

=item write_len => INT

Overrides the C<write_len> parameter for the data written by this call.

=item on_write => CODE

A CODE reference which will be invoked after every successful C<syswrite>
operation on the underlying filehandle. It will be passed the number of bytes
that were written by this call, which may not be the entire length of the
buffer - if it takes more than one C<syscall> operation to empty the buffer
then this callback will be invoked multiple times.

 $on_write->( $stream, $len )

=item on_flush => CODE

A CODE reference which will be invoked once the data queued by this C<write>
call has been flushed. This will be invoked even if the buffer itself is not
yet empty; if more data has been queued since the call.

 $on_flush->( $stream )

=item on_error => CODE

A CODE reference which will be invoked if a C<syswrite> error happens while
performing this write. Invoked as for the C<Stream>'s C<on_write_error> event.

 $on_error->( $stream, $errno )

=back

If the object is not yet a member of a loop and doesn't yet have a
C<write_handle>, then calls to the C<write> method will simply queue the data
and return. It will be flushed when the object is added to the loop.

If C<$data> is a defined but empty string, the write is still queued, and the
C<on_flush> continuation will be invoked, if supplied. This can be used to
obtain a marker, to invoke some code once the output queue has been flushed up
to this point.

=head2 write (scalar)

   $stream->write( ... )->get

If called in non-void context, this method returns a L<Future> which will
complete (with no value) when the write operation has been flushed. This may
be used as an alternative to, or combined with, the C<on_flush> callback.

=cut

sub _syswrite
{
   my $self = shift;
   my ( $handle, undef, $len ) = @_;

   my $written = $handle->syswrite( $_[1], $len );
   return $written if !$written; # zero or undef

   substr( $_[1], 0, $written ) = "";
   return $written;
}

sub _flush_one_write
{
   my $self = shift;

   my $writequeue = $self->{writequeue};

   my $head;
   while( $head = $writequeue->[0] and ref $head->data ) {
      if( ref $head->data eq "CODE" ) {
         my $data = $head->data->( $self );
         if( !defined $data ) {
            $head->on_flush->( $self ) if $head->on_flush;
            shift @$writequeue;
            return 1;
         }
         if( !ref $data and my $encoding = $self->{encoding} ) {
            $data = $encoding->encode( $data );
         }
         unshift @$writequeue, my $new = Writer(
            $data, $head->writelen, $head->on_write, undef, undef, 0
         );
         next;
      }
      elsif( blessed $head->data and $head->data->isa( "Future" ) ) {
         my $f = $head->data;
         if( !$f->is_ready ) {
            return 0 if $head->watching;
            $f->on_ready( sub { $self->_flush_one_write } );
            $head->watching++;
            return 0;
         }
         my $data = $f->get;
         if( !ref $data and my $encoding = $self->{encoding} ) {
            $data = $encoding->encode( $data );
         }
         $head->data = $data;
         next;
      }
      else {
         die "Unsure what to do with reference ".ref($head->data)." in write queue";
      }
   }

   my $second;
   while( $second = $writequeue->[1] and
          !ref $second->data and
          $head->writelen == $second->writelen and
          !$head->on_write and !$second->on_write and
          !$head->on_flush ) {
      $head->data .= $second->data;
      $head->on_write = $second->on_write;
      $head->on_flush = $second->on_flush;
      splice @$writequeue, 1, 1, ();
   }

   die "TODO: head data does not contain a plain string" if ref $head->data;

   if( $IO::Async::Debug::DEBUG > 1 ) {
      my $data = substr $head->data, 0, $head->writelen;
      $self->debug_printf( "WRITE len=%d", length $data );
      IO::Async::Debug::log_hexdump( $data ) if $IO::Async::Debug::DEBUG_FLAGS{Sw};
   }

   my $writer = $self->{writer};
   my $len = $self->$writer( $self->write_handle, $head->data, $head->writelen );

   if( !defined $len ) {
      my $errno = $!;

      if( $errno == EAGAIN or $errno == EWOULDBLOCK ) {
         $self->maybe_invoke_event( on_writeable_stop => ) if $self->{writeable};
         $self->{writeable} = 0;
      }

      return 0 if _nonfatal_error( $errno );

      $self->debug_printf( "WRITE err=%d/%s", $errno, $errno ) if $IO::Async::Debug::DEBUG > 1;

      if( $errno == EPIPE ) {
         $self->debug_printf( "WRITE-EOF" );
         $self->{write_eof} = 1;
         $self->maybe_invoke_event( on_write_eof => );
      }

      $head->on_error->( $self, $errno ) if $head->on_error;
      $self->maybe_invoke_event( on_write_error => $errno )
         or $self->close_now;

      return 0;
   }

   $METRICS and $METRICS->inc_counter_by( stream_written => $len ) if $len;

   if( my $on_write = $head->on_write ) {
      $on_write->( $self, $len );
   }

   if( !length $head->data ) {
      $head->on_flush->( $self ) if $head->on_flush;
      shift @{ $self->{writequeue} };
   }

   return 1;
}

sub write
{
   my $self = shift;
   my ( $data, %params ) = @_;

   carp "Cannot write data to a Stream that is closing" and return if $self->{stream_closing};

   # Allow writes without a filehandle if we're not yet in a Loop, just don't
   # try to flush them
   my $handle = $self->write_handle;

   croak "Cannot write data to a Stream with no write_handle" if !$handle and $self->loop;

   if( !ref $data and my $encoding = $self->{encoding} ) {
      $data = $encoding->encode( $data );
   }

   my $on_write = delete $params{on_write};
   my $on_flush = delete $params{on_flush};
   my $on_error = delete $params{on_error};

   my $f;
   if( defined wantarray ) {
      my $orig_on_flush = $on_flush;
      my $orig_on_error = $on_error;

      my $loop = $self->loop or
         croak "Cannot ->write data returning a Future to a Stream not in a Loop";
      $f = $loop->new_future;
      $on_flush = sub {
         $f->done;
         $orig_on_flush->( @_ ) if $orig_on_flush;
      };
      $on_error = sub {
         my $self = shift;
         my ( $errno ) = @_;

         $f->fail( "write failed: $errno", syswrite => $errno ) unless $f->is_ready;

         $orig_on_error->( $self, @_ ) if $orig_on_error;
      };
   }

   my $write_len = $params{write_len};
   defined $write_len or $write_len = $self->{write_len};

   push @{ $self->{writequeue} }, Writer(
      $data, $write_len, $on_write, $on_flush, $on_error, 0
   );

   keys %params and croak "Unrecognised keys for ->write - " . join( ", ", keys %params );

   return $f unless $handle;

   if( $self->{autoflush} ) {
      1 while !$self->_is_empty and $self->_flush_one_write;

      if( $self->_is_empty ) {
         $self->want_writeready_for_write( 0 );
         return $f;
      }
   }

   $self->want_writeready_for_write( 1 );
   return $f;
}

sub on_write_ready
{
   my $self = shift;

   if( !$self->{writeable} ) {
      $self->maybe_invoke_event( on_writeable_start => );
      $self->{writeable} = 1;
   }

   $self->_do_write if $self->{want} & WANT_WRITE_FOR_WRITE;
   $self->_do_read  if $self->{want} & WANT_WRITE_FOR_READ;
}

sub _do_write
{
   my $self = shift;

   1 while !$self->_is_empty and $self->_flush_one_write and $self->{write_all};

   # All data successfully flushed
   if( $self->_is_empty ) {
      $self->want_writeready_for_write( 0 );

      $self->maybe_invoke_event( on_outgoing_empty => );

      $self->close_now if $self->{stream_closing};
   }
}

sub _flush_one_read
{
   my $self = shift;
   my ( $eof ) = @_;

   local $self->{flushing_read} = 1;

   my $readqueue = $self->{readqueue};

   my $ret;
   if( $readqueue->[0] and my $on_read = $readqueue->[0]->on_read ) {
      $ret = $on_read->( $self, \$self->{readbuff}, $eof );
   }
   else {
      $ret = $self->invoke_event( on_read => \$self->{readbuff}, $eof );
   }

   if( defined $self->{read_low_watermark} and $self->{at_read_high_watermark} and
       length $self->{readbuff} < $self->{read_low_watermark} ) {
      undef $self->{at_read_high_watermark};
      $self->invoke_event( on_read_low_watermark => length $self->{readbuff} );
   }

   if( ref $ret eq "CODE" ) {
      # Replace the top CODE, or add it if there was none
      $readqueue->[0] = Reader( $ret, undef );
      return 1;
   }
   elsif( @$readqueue and !defined $ret ) {
      shift @$readqueue;
      return 1;
   }
   else {
      return $ret && ( length( $self->{readbuff} ) > 0 || $eof );
   }
}

sub _sysread
{
   my $self = shift;
   my ( $handle, undef, $len ) = @_;
   return $handle->sysread( $_[1], $len );
}

sub on_read_ready
{
   my $self = shift;

   $self->_do_read  if $self->{want} & WANT_READ_FOR_READ;
   $self->_do_write if $self->{want} & WANT_READ_FOR_WRITE;
}

sub _do_read
{
   my $self = shift;

   my $handle = $self->read_handle;
   my $reader = $self->{reader};

   while(1) {
      my $data;
      my $len = $self->$reader( $handle, $data, $self->{read_len} );

      if( !defined $len ) {
         my $errno = $!;

         return if _nonfatal_error( $errno );

         $self->debug_printf( "READ err=%d/%s", $errno, $errno ) if $IO::Async::Debug::DEBUG > 1;

         $self->maybe_invoke_event( on_read_error => $errno )
            or $self->close_now;

         foreach ( @{ $self->{readqueue} } ) {
            $_->future->fail( "read failed: $errno", sysread => $errno ) if $_->future;
         }
         undef @{ $self->{readqueue} };

         return;
      }

      if( $IO::Async::Debug::DEBUG > 1 ) {
         $self->debug_printf( "READ len=%d", $len );
         IO::Async::Debug::log_hexdump( $data ) if $IO::Async::Debug::DEBUG_FLAGS{Sr};
      }

      $METRICS and $METRICS->inc_counter_by( stream_read => $len ) if $len;

      my $eof = $self->{read_eof} = ( $len == 0 );

      if( my $encoding = $self->{encoding} ) {
         my $bytes = defined $self->{bytes_remaining} ? $self->{bytes_remaining} . $data : $data;
         $data = $encoding->decode( $bytes, STOP_AT_PARTIAL );
         $self->{bytes_remaining} = $bytes;
      }

      $self->{readbuff} .= $data if !$eof;

      1 while $self->_flush_one_read( $eof );

      if( $eof ) {
         $self->debug_printf( "READ-EOF" );
         $self->maybe_invoke_event( on_read_eof => );
         $self->close_now if $self->{close_on_read_eof};
         foreach ( @{ $self->{readqueue} } ) {
            $_->future->done( undef ) if $_->future;
         }
         undef @{ $self->{readqueue} };
         return;
      }

      last unless $self->{read_all};
   }

   if( defined $self->{read_high_watermark} and length $self->{readbuff} >= $self->{read_high_watermark} ) {
      $self->{at_read_high_watermark} or
         $self->invoke_event( on_read_high_watermark => length $self->{readbuff} );

      $self->{at_read_high_watermark} = 1;
   }
}

sub on_read_high_watermark
{
   my $self = shift;
   $self->want_readready_for_read( 0 );
}

sub on_read_low_watermark
{
   my $self = shift;
   $self->want_readready_for_read( 1 );
}

=head2 push_on_read

   $stream->push_on_read( $on_read )

Pushes a new temporary C<on_read> handler to the end of the queue. This queue,
if non-empty, is used to provide C<on_read> event handling code in preference
to using the object's main event handler or method. New handlers can be
supplied at any time, and they will be used in first-in first-out (FIFO)
order.

As with the main C<on_read> event handler, each can return a (defined) boolean
to indicate if they wish to be invoked again or not, another C<CODE> reference
to replace themself with, or C<undef> to indicate it is now complete and
should be removed. When a temporary handler returns C<undef> it is shifted
from the queue and the next one, if present, is invoked instead. If there are
no more then the object's main handler is invoked instead.

=cut

sub push_on_read
{
   my $self = shift;
   my ( $on_read, %args ) = @_;
   # %args undocumented for internal use

   push @{ $self->{readqueue} }, Reader( $on_read, $args{future} );

   # TODO: Should this always defer?
   return if $self->{flushing_read};
   1 while length $self->{readbuff} and $self->_flush_one_read( 0 );
}

=head1 FUTURE-RETURNING READ METHODS

The following methods all return a L<Future> which will become ready when
enough data has been read by the Stream into its buffer. At this point, the
data is removed from the buffer and given to the C<Future> object to complete
it.

 my $f = $stream->read_...

 my ( $string ) = $f->get;

Unlike the C<on_read> event handlers, these methods don't allow for access to
"partial" results; they only provide the final result once it is ready.

If a C<Future> is cancelled before it completes it is removed from the read
queue without consuming any data; i.e. each C<Future> atomically either
completes or is cancelled.

Since it is possible to use a readable C<Stream> entirely using these
C<Future>-returning methods instead of the C<on_read> event, it may be useful
to configure a trivial return-false event handler to keep it from consuming
any input, and to allow it to be added to a C<Loop> in the first place.

 my $stream = IO::Async::Stream->new( on_read => sub { 0 }, ... );
 $loop->add( $stream );

 my $f = $stream->read_...

If a read EOF or error condition happens while there are read C<Future>s
pending, they are all completed. In the case of a read EOF, they are done with
C<undef>; in the case of a read error they are failed using the C<$!> error
value as the failure.

 $f->fail( $message, sysread => $! )

If a read EOF condition happens to the currently-processing read C<Future>, it
will return a partial result. The calling code can detect this by the fact
that the returned data is not complete according to the specification (too
short in C<read_exactly>'s case, or lacking the ending pattern in
C<read_until>'s case). Additionally, each C<Future> will yield the C<$eof>
value in its results.

 my ( $string, $eof ) = $f->get;

=cut

sub _read_future
{
   my $self = shift;
   my $f = $self->loop->new_future;
   $f->on_cancel( $self->_capture_weakself( sub {
      my $self = shift or return;
      1 while $self->_flush_one_read;
   }));
   return $f;
}

=head2 read_atmost

=head2 read_exactly

   ( $string, $eof ) = $stream->read_atmost( $len )->get

   ( $string, $eof ) = $stream->read_exactly( $len )->get

Completes the C<Future> when the read buffer contains C<$len> or more
characters of input. C<read_atmost> will also complete after the first
invocation of C<on_read>, even if fewer characters are available, whereas
C<read_exactly> will wait until at least C<$len> are available.

=cut

sub read_atmost
{
   my $self = shift;
   my ( $len ) = @_;

   my $f = $self->_read_future;
   $self->push_on_read( sub {
      my ( undef, $buffref, $eof ) = @_;
      return undef if $f->is_cancelled;
      $f->done( substr( $$buffref, 0, $len, "" ), $eof );
      return undef;
   }, future => $f );
   return $f;
}

sub read_exactly
{
   my $self = shift;
   my ( $len ) = @_;

   my $f = $self->_read_future;
   $self->push_on_read( sub {
      my ( undef, $buffref, $eof ) = @_;
      return undef if $f->is_cancelled;
      return 0 unless $eof or length $$buffref >= $len;
      $f->done( substr( $$buffref, 0, $len, "" ), $eof );
      return undef;
   }, future => $f );
   return $f;
}

=head2 read_until

   ( $string, $eof ) = $stream->read_until( $end )->get

Completes the C<Future> when the read buffer contains a match for C<$end>,
which may either be a plain string or a compiled C<Regexp> reference. Yields
the prefix of the buffer up to and including this match.

=cut

sub read_until
{
   my $self = shift;
   my ( $until ) = @_;

   ref $until or $until = qr/\Q$until\E/;

   my $f = $self->_read_future;
   $self->push_on_read( sub {
      my ( undef, $buffref, $eof ) = @_;
      return undef if $f->is_cancelled;
      if( $$buffref =~ $until ) {
         $f->done( substr( $$buffref, 0, $+[0], "" ), $eof );
         return undef;
      }
      elsif( $eof ) {
         $f->done( $$buffref, $eof ); $$buffref = "";
         return undef;
      }
      else {
         return 0;
      }
   }, future => $f );
   return $f;
}

=head2 read_until_eof

   ( $string, $eof ) = $stream->read_until_eof->get

Completes the C<Future> when the stream is eventually closed at EOF, and
yields all of the data that was available.

=cut

sub read_until_eof
{
   my $self = shift;

   my $f = $self->_read_future;
   $self->push_on_read( sub {
      my ( undef, $buffref, $eof ) = @_;
      return undef if $f->is_cancelled;
      return 0 unless $eof;
      $f->done( $$buffref, $eof ); $$buffref = "";
      return undef;
   }, future => $f );
   return $f;
}

=head1 UTILITY CONSTRUCTORS

=cut

=head2 new_for_stdin

=head2 new_for_stdout

=head2 new_for_stdio

   $stream = IO::Async::Stream->new_for_stdin

   $stream = IO::Async::Stream->new_for_stdout

   $stream = IO::Async::Stream->new_for_stdio

Return a C<IO::Async::Stream> object preconfigured with the correct
C<read_handle>, C<write_handle> or both.

=cut

sub new_for_stdin  { shift->new( read_handle  => \*STDIN, @_ ) }
sub new_for_stdout { shift->new( write_handle => \*STDOUT, @_ ) }

sub new_for_stdio { shift->new( read_handle => \*STDIN, write_handle => \*STDOUT, @_ ) }

=head2 connect

   $future = $stream->connect( %args )

A convenient wrapper for calling the C<connect> method on the underlying
L<IO::Async::Loop> object, passing the C<socktype> hint as C<stream> if not
otherwise supplied.

=cut

sub connect
{
   my $self = shift;
   return $self->SUPER::connect( socktype => "stream", @_ );
}

=head1 DEBUGGING FLAGS

The following flags in C<IO_ASYNC_DEBUG_FLAGS> enable extra logging:

=over 4

=item C<Sr>

Log byte buffers as data is read from a Stream

=item C<Sw>

Log byte buffers as data is written to a Stream

=back

=cut

=head1 EXAMPLES

=head2 A line-based C<on_read> method

The following C<on_read> method accepts incoming C<\n>-terminated lines and
prints them to the program's C<STDOUT> stream.

 sub on_read
 {
    my $self = shift;
    my ( $buffref, $eof ) = @_;

    while( $$buffref =~ s/^(.*\n)// ) {
       print "Received a line: $1";
    }

    return 0;
 }

Because a reference to the buffer itself is passed, it is simple to use a
C<s///> regular expression on the scalar it points at, to both check if data
is ready (i.e. a whole line), and to remove it from the buffer. Since it
always removes as many complete lines as possible, it doesn't need invoking
again when it has finished, so it can return a constant C<0>.

=head2 Reading binary data

This C<on_read> method accepts incoming records in 16-byte chunks, printing
each one.

 sub on_read
 {
    my ( $self, $buffref, $eof ) = @_;

    if( length $$buffref >= 16 ) {
       my $record = substr( $$buffref, 0, 16, "" );
       print "Received a 16-byte record: $record\n";

       return 1;
    }

    if( $eof and length $$buffref ) {
       print "EOF: a partial record still exists\n";
    }

    return 0;
 }

This time, rather than a C<while()> loop we have decided to have the handler
just process one record, and use the C<return 1> mechanism to ask that the
handler be invoked again if there still remains data that might contain
another record; only stopping with C<return 0> when we know we can't find one.

The 4-argument form of C<substr()> extracts the 16-byte record from the buffer
and assigns it to the C<$record> variable, if there was enough data in the
buffer to extract it.

A lot of protocols use a fixed-size header, followed by a variable-sized body
of data, whose size is given by one of the fields of the header. The following
C<on_read> method extracts messages in such a protocol.

 sub on_read
 {
    my ( $self, $buffref, $eof ) = @_;

    return 0 unless length $$buffref >= 8; # "N n n" consumes 8 bytes

    my ( $len, $x, $y ) = unpack "N n n", $$buffref;

    return 0 unless length $$buffref >= 8 + $len;

    substr( $$buffref, 0, 8, "" );
    my $data = substr( $$buffref, 0, $len, "" );

    print "A record with values x=$x y=$y\n";

    return 1;
 }

In this example, the header is C<unpack()>ed first, to extract the body
length, and then the body is extracted. If the buffer does not have enough
data yet for a complete message then C<0> is returned, and the buffer is left
unmodified for next time. Only when there are enough bytes in total does it
use C<substr()> to remove them.

=head2 Dynamic replacement of C<on_read>

Consider the following protocol (inspired by IMAP), which consists of
C<\n>-terminated lines that may have an optional data block attached. The
presence of such a data block, as well as its size, is indicated by the line
prefix.

 sub on_read
 {
    my $self = shift;
    my ( $buffref, $eof ) = @_;

    if( $$buffref =~ s/^DATA (\d+):(.*)\n// ) {
       my $length = $1;
       my $line   = $2;

       return sub {
          my $self = shift;
          my ( $buffref, $eof ) = @_;

          return 0 unless length $$buffref >= $length;

          # Take and remove the data from the buffer
          my $data = substr( $$buffref, 0, $length, "" );

          print "Received a line $line with some data ($data)\n";

          return undef; # Restore the original method
       }
    }
    elsif( $$buffref =~ s/^LINE:(.*)\n// ) {
       my $line = $1;

       print "Received a line $line with no data\n";

       return 1;
    }
    else {
       print STDERR "Unrecognised input\n";
       # Handle it somehow
    }
 }

In the case where trailing data is supplied, a new temporary C<on_read>
callback is provided in a closure. This closure captures the C<$length>
variable so it knows how much data to expect. It also captures the C<$line>
variable so it can use it in the event report. When this method has finished
reading the data, it reports the event, then restores the original method by
returning C<undef>.

=head1 SEE ALSO

=over 4

=item *

L<IO::Handle> - Supply object methods for I/O handles

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
