#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2024 -- leonerd@leonerd.org.uk

package Future::Buffer 0.06;

use v5.14;
use warnings;

use Future;

use Scalar::Util qw( weaken );

=head1 NAME

C<Future::Buffer> - a string buffer that uses Futures

=head1 SYNOPSIS

   use Future::Buffer;

   use Future::AsyncAwait;
   use Future::IO;

   my $buffer = Future::Buffer->new(
      fill => sub { Future::IO->sysread( $socket, 8192 ) }
   );

   async sub print_lines
   {
      while(1) {
         my $line = await $buffer->read_until( "\n" );
         chomp $line;

         say "Got a line: $line";
      }
   }

   await print_lines();

=head1 DESCRIPTION

Objects in this class provide a string buffer, on which operations return
L<Future> instances which will complete when data is available. Data can be
inserted into the buffer either in a push-based manner by calling the C<write>
method, or in a pull-based manner by providing it with a C<fill> callback by
which it can request data itself. This flexibility allows the buffer to act as
an adapter between push- and pull-based providers and consumers.

Each C<read>-like method returns a L<Future> which will complete once there
are enough bytes in the buffer to satisfy the required condition. The buffer
behaves somewhat like a pipe, where bytes provided at the writing end (either
by the C<write> method or the C<fill> callback) are eventually consumed at the
reading end by one of the C<read> futures.

Multiple C<read> futures can remain pending at once, and will be completed in
the order they were created when more data is eventually available. Thus, any
call to the C<write> method to provide more data can potentially result in
multiple futures becoming ready.

I<Since version 0.04> the buffer supports an end-of-file condition. The
L</close> method or a C<fill> callback future yielding an empty result will
mark that the buffer is now closed. Once it has exhausted the remaining stored
data any further read futures will yield empty.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $buffer = Future::Buffer->new( %args );

Returns a new L<Future::Buffer> instance.

Takes the following named arguments:

=over 4

=item fill => CODE

   $data = await $fill->();

Optional callback which the buffer will invoke when it needs more data.

Any read futures which are waiting on the fill future are constructed by using
the fill future as a prototype, ensuring they have the correct type.

If the result is an empty list this will be treated as an end-of-file
notification and the buffer is closed.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   return bless {
      pending => [],
      data    => "",
      fill    => $args{fill},
   }, $class;
}

=head1 METHODS

=cut

sub _fill
{
   my $self = shift;

   return $self->{fill_f} if $self->{fill_f};

   my $fill = $self->{fill};

   # Arm the fill loop
   my $f = $self->{fill_f} = $fill->(); # TODO: give it a size hint?

   weaken( my $weakself = $self );

   $f->on_done( sub {
      my $self = $weakself or return;

      undef $self->{fill_f};

      if( @_ ) {
         my ( $data ) = @_;
         $self->{data} .= $data;
      }
      else {
         $self->{at_eof} = 1;
      }

      $self->_invoke_pending;

      $self->_fill if @{ $self->{pending} };
   });
}

sub _new_read_future
{
   my $self = shift;
   my ( $code ) = @_;

   my $pending = $self->{pending};

   # First see if the buffer is already sufficient;
   if( !@$pending and
         ( my @ret = $code->( \$self->{data} ) ) ) {
      return Future->done( @ret );
   }

   my $f;
   if( $self->{fill} and my $fill_f = $self->_fill ) {
      $f = $fill_f->new;
   }
   else {
      $f = Future->new;
   }

   push @$pending, [ $code, $f ];

   $self->_invoke_pending if length $self->{data};

   $f->on_cancel( sub {
      shift @$pending while @$pending and $pending->[0]->[1]->is_cancelled;
      return if @$pending or !$self->{fill_f};

      $self->{fill_f}->cancel;
      undef $self->{fill_f};
   } );

   return $f;
}

sub _invoke_pending
{
   my $self = shift;

   my $pending = $self->{pending};

   while( @$pending and length $self->{data} ) {
      my $p = $pending->[0];
      shift @$pending and next if $p->[1]->is_cancelled;

      defined( my $ret = $p->[0]->( \$self->{data} ) )
         or last;

      shift @$pending;
      $p->[1]->done( $ret );
   }
   while( @$pending and $self->{at_eof} ) {
      my $p = $pending->[0];
      shift @$pending and next if $p->[1]->is_cancelled;

      shift @$pending;
      $p->[1]->done();
   }
}

=head2 length

   $len = $buffer->length;

Returns the length of the currently-stored data; that is, data that has been
provided by C<write> calls or the C<fill> callback but not yet consumed by a
C<read> future.

=cut

sub length :method { length $_[0]->{data} }

=head2 is_empty

   $empty = $buffer->is_empty;

Returns true if the stored length is zero.

=cut

sub is_empty { shift->length == 0 }

=head2 write

   $f = $buffer->write( $data );

Appends to the stored data, invoking any pending C<read> futures that are
outstanding and can now complete.

Currently this method returns an already-completed C<Future>. Some later
version may implement a buffer maximum size, and choose not to complete this
future until there is enough space to accept the new data. For now it is safe
for the caller to ignore the return value, but it may become not so.

=cut

sub write
{
   my $self = shift;
   $self->{data} .= $_[0];

   $self->_invoke_pending if @{ $self->{pending} };

   return Future->done;
}

=head2 close

   $buffer->close;

Marks that the buffer is now at EOF condition. Once any remaining buffered
content is consumed, any further read futures will all yield EOF condition.

=cut

sub close
{
   my $self = shift;
   $self->{at_eof} = 1;

   $self->_invoke_pending if @{ $self->{pending} };

   return Future->done;
}

=head2 read_atmost

   $data = await $buffer->read_atmost( $len );

Returns a future which will complete when there is some data available in the
buffer and will yield I<up too> the given length. Note that, analogous to
calling the C<read> IO method on a filehandle, this can still complete and
yield a shorter length if less is currently available.

If the stream is closed and there is no remaining data, the returned future
will yield empty.

=cut

sub read_atmost
{
   my $self = shift;
   my ( $maxlen ) = @_;

   return $self->_new_read_future(
      sub {
         my ( $dref ) = @_;
         return unless length $$dref;

         return substr( $$dref, 0, $maxlen, "" );
      }
   );
}

=head2 read_exactly

   $data = await $buffer->read_exactly( $len );

Returns a future which will complete when there is enough data available in
the buffer to yield exactly the length given.

If the stream is closed and there is no remaining data, the returned future
will yield empty.

=cut

sub read_exactly
{
   my $self = shift;
   my ( $len ) = @_;

   return $self->_new_read_future(
      sub {
         my ( $dref ) = @_;
         return unless length $$dref >= $len;

         return substr( $$dref, 0, $len, "" );
      }
   );
}

=head2 read_until

   $data = await $buffer->read_until( $pattern );

Returns a future which will complete when the buffer contains a match for the
given pattern (which may either be a plain string or a compiled C<Regexp>).
The future will yield the contents of the buffer up to and including this
match.

If the stream is closed and there is no remaining data, the returned future
will yield empty.

For example, a C<readline>-like operation can be performed by

   $f = $buffer->read_until( "\x0d\x0a" );

=cut

sub read_until
{
   my $self = shift;
   my ( $pattern ) = @_;

   $pattern = qr/\Q$pattern/ unless ref $pattern eq "Regexp";

   return $self->_new_read_future(
      sub {
         my ( $dref ) = @_;
         return unless $$dref =~ m/$pattern/;

         return substr( $$dref, 0, $+[0], "" );
      }
   );
}

=head2 read_unpacked

   $data = await $buffer->read_unpacked( $pack_format );

I<Since version 0.03.>

Returns a future which will complete when the buffer contains enough data to
unpack all of the requested fields using the given C<pack()> format. The
future will yield a list of all the fields extracted by the format.

If the stream is closed and there is no remaining data, the returned future
will yield empty.

Note that because the implementation is shamelessly stolen from
L<IO::Handle::Packable> the same limitations on what pack formats are
recognized will apply.

=cut

# Gratuitously stolen from IO::Handle::Packable

use constant {
   BYTES_FMT_i => length( pack "i", 0 ),
   BYTES_FMT_f => length( pack "f", 0 ),
   BYTES_FMT_d => length( pack "d", 0 ),
};

sub _length_of_packformat
{
   my ( $format ) = @_;
   local $_ = $format;

   my $bytes = 0;
   while( length ) {
      s/^\s+//;
      length or last;

      my $this;

      # Basic template
      s/^[aAcC]// and $this = 1 or
      s/^[sSnv]// and $this = 2 or
      s/^[iI]//   and $this = BYTES_FMT_i or
      s/^[lLNV]// and $this = 4 or
      s/^[qQ]//   and $this = 8 or
      s/^f//      and $this = BYTES_FMT_f or
      s/^d//      and $this = BYTES_FMT_d or
         die "TODO: unrecognised template char ${\substr $_, 0, 1}\n";

      # Ignore endian specifiers
      s/^[<>]//;

      # Repeat count
      s/^(\d+)// and $this *= $1;

      $bytes += $this;
   }

   return $bytes;
}

sub read_unpacked
{
   my $self = shift;
   my ( $format ) = @_;

   my $len = _length_of_packformat $format;
   return $self->_new_read_future(
      sub {
         my ( $dref ) = @_;
         return unless length $$dref >= $len;

         return unpack $format, substr( $$dref, 0, $len, "" );
      }
   );
}

=head2 unread

   $buffer->unread( $data );

I<Since version 0.03.>

Prepends more data back into the buffer,

It is uncommon to need this method, but it may be useful in certain situations
such as when it is hard to determine upfront how much data needs to be read
for a single operation, and it turns out too much was read. The trailing
content past what is needed can be put back for a later operation.

Note that use of this method causes an inherent race condition between
outstanding read futures and existing data in the buffer. If there are no
pending futures then this is safe. If there is no existing data already in the
buffer this is also safe. If neither of these is true then a warning is
printed indicating that the logic of the caller is not well-defined.

=cut

sub unread
{
   my $self = shift;
   my ( $data ) = @_;

   if( @{ $self->{pending} } and length $self->{data} ) {
      warn "Racy use of ->unread with both pending read futures and existing data";
   }

   $self->{data} = $data . $self->{data};
   $self->_invoke_pending if @{ $self->{pending} };

   return Future->done;
}

=head1 TODO

=over 4

=item *

An "on-read" event, taking maybe inspiration from L<IO::Async::Stream>. This
would allow both pull- and push-based consumers.

=item *

Size limitation. Allow an upper bound of stored data, make C<write> calls
return pending futures until buffer can accept it. Needs consideration of
unbounded C<read_until> though.

=item *

Consider extensions of the L</read_unpacked> method to handle more situations.
This may require building a shared CPAN module for doing streaming-unpack
along with C<IO::Handle::Packable> and other situations.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

Inspired by L<Ryu::Buffer> by Tom Molesworth <TEAM@cpan.org>

=cut

0x55AA;
