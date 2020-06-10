#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Future::Buffer;

use 5.010; # //
use strict;
use warnings;

our $VERSION = '0.01';

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

   print_lines()->get;

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

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $buffer = Future::Buffer->new( %args )

Returns a new L<Future::Buffer> instance.

Takes the following named arguments:

=over 4

=item fill => CODE

   $f = $fill->()

      $data = $f->get

Optional callback which the buffer will invoke when it needs more data.

Any read futures which are waiting on the fill future are constructed by using
the fill future as a prototype, ensuring they have the correct type.

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
   return $self->{fill_f} //= do {
      weaken( my $weakself = $self );
      my $fill = $self->{fill};

      # Arm the fill loop
      $self->{fill_f} = $fill->() # TODO: give it a size hint?
         ->on_done( sub {
            my ( $data ) = @_;
            $weakself or return;

            $weakself->{data} .= $data;
            undef $self->{fill_f};

            $weakself->_invoke_pending;

            $weakself->_fill if @{ $self->{pending} };
         });
   };
}

sub _new_read_future
{
   my $self = shift;

   if( $self->{fill} and my $fill_f = $self->_fill ) {
      return $fill_f->new;
   }

   return Future->new;
}

sub _invoke_pending
{
   my $self = shift;

   my $pending = $self->{pending};

   while( @$pending and length $self->{data} ) {
      $pending->[0]->( \$self->{data} )
         or last;

      shift @$pending;
   }
}

=head2 length

   $len = $buffer->length

Returns the length of the currently-stored data; that is, data that has been
provided by C<write> calls but not yet consumed by C<read>.

=cut

sub length :method { length $_[0]->{data} }

=head2 is_empty

   $empty = $buffer->is_empty

Returns true if the stored length is zero.

=cut

sub is_empty { shift->length == 0 }

=head2 write

   $f = $buffer->write( $data )

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

=head2 read

   $f = $buffer->read( $len )

      $data = $f->get

Returns a future which will complete when there is some data available in the
buffer and will yield I<up too> the given length. Note that, analogous to
calling the C<read> IO method on a filehandle, this can still complete and
yield a shorter length if less is currently available.

=cut

sub read
{
   my $self = shift;
   my ( $maxlen ) = @_;

   my $f = $self->_new_read_future;

   push @{ $self->{pending} }, sub {
      my ( $dref ) = @_;
      return unless length $$dref;

      my $ret = substr( $$dref, 0, $maxlen, "" );
      $f->done( $ret );
   };

   $self->_invoke_pending if length $self->{data};

   return $f;
}

=head2 read_exactly

   $f = $buffer->read_exactly( $len )

      $data = $f->get

Returns a future which will complete when there is enough data available in
the buffer to yield exactly the length given.

=cut

sub read_exactly
{
   my $self = shift;
   my ( $len ) = @_;

   my $f = $self->_new_read_future;

   push @{ $self->{pending} }, sub {
      my ( $dref ) = @_;
      return unless length $$dref >= $len;

      my $ret = substr( $$dref, 0, $len, "" );
      $f->done( $ret );
   };

   $self->_invoke_pending if length $self->{data};

   return $f;
}

=head2 read_until

   $f = $buffer->read_until( $pattern )

      $data = $f->get

Returns a future which will complete when the buffer contains a match for the
given pattern (which may either be a plain string or a compiled C<Regexp>).
The future will yield the contents of the buffer up to and including this
match.

For example, a C<readline>-like operation can be performed by

   $f = $buffer->read_until( "\x0d\x0a" );

=cut

sub read_until
{
   my $self = shift;
   my ( $pattern ) = @_;

   $pattern = qr/\Q$pattern/ unless ref $pattern eq "Regexp";

   my $f = $self->_new_read_future;

   push @{ $self->{pending} }, sub {
      my ( $dref ) = @_;
      return unless $$dref =~ m/$pattern/;

      my $ret = substr( $$dref, 0, $+[0], "" );
      $f->done( $ret );
   };

   $self->_invoke_pending if length $self->{data};

   return $f;
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

Consider some C<read + unpack> assistance, to allow nice handling of binary
protocols by unpacking out of the buffer directly.

=item *

Consider what happens at EOF. Add a C<close> method for producers to call.
Understand what C<fill> would do there. Have all the pending C<read> futures
yield an empty list maybe?

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

Inspired by L<Ryu::Buffer> by Tom Molesworth <TEAM@cpan.org>

=cut

0x55AA;
