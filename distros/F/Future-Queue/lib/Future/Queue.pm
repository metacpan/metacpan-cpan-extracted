#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2024 -- leonerd@leonerd.org.uk

package Future::Queue 0.52;

use v5.14;
use warnings;

use Carp;

=head1 NAME

C<Future::Queue> - a FIFO queue of values that uses L<Future>s

=head1 SYNOPSIS

   use Future::Queue;
   use Future::AsyncAwait;

   my $queue = Future::Queue->new;

   async sub process_queue
   {
      while(1) {
         my $thing = await $queue->shift;
         ...
      }
   }

   my $f = process_queue();
   $queue->push( "a thing" );

=head1 DESCRIPTION

Objects in this class provide a simple FIFO queue the stores arbitrary perl
values. Values may be added into the queue using the L</push> method, and
retrieved from it using the L</shift> method.

Values may be stored within the queue object for C<shift> to retrieve later,
or if the queue is empty then the future that C<shift> returns will be
completed once an item becomes available.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $queue = Future::Queue->new( %params );

Returns a new C<Future::Queue> instance.

Takes the following named arguments:

=over 4

=item max_items => INT

I<Since version 0.50.>

Optional. If defined, there can be at most the given number of items in the
queue. Attempts to call L</push> beyond that will yield a future that remains
pending, until a subsequent L</shift> operation makes enough space.

=item prototype => STRING or OBJECT or CODE

I<Since verison 0.51.>

Optional. If defined, gives either a class name, an object instance to clone
or a code reference to invoke when a new pending C<Future> instance is needed
by the C<shift> or C<push> methods when they cannot complete immediately.

   $f = $prototype->();    # if CODE reference
   $f = $prototype->new;   # otherwise

If not provided, a default of C<Future> will be used.

=back

=cut

sub new
{
   my $class = shift;
   my %params = @_;

   my $prototype = $params{prototype};

   return bless {
      items => [],
      max_items => $params{max_items},
      shift_waiters => [],
      ( ref $prototype eq "CODE" ) ?
         ( f_factory => $prototype ) :
         ( f_prototype => $prototype // "Future" ),
   }, $class;
}

=head2 push

   $queue->push( @items );

   await $queue->push( @items );

Adds more items into the queue. If the queue was previously empty and there is
at least one C<shift> future waiting, then the next one will be completed by
this method.

I<Since version 0.50> this can take multiple items; earlier versions can only
take one value at once.

This method always returns a L<Future> instance. If C<max_items> is defined
then it is possible that this future will be in a still-pending state;
indicating that there was not yet space in the queue to add the items. It will
become completed once enough L</shift> calls have been made to make space for
them.

If C<max_items> is not defined then these instances will always be immediately
complete; it is safe to drop or ignore it, or call the method in void context.

If the queue has been finished then more items cannot be pushed and an
exception will be thrown.

=cut

sub _manage_shift_waiters
{
   my $self = shift;

   my $items = $self->{items};
   my $shift_waiters = $self->{shift_waiters};

   ( shift @$shift_waiters )->()
      while @$shift_waiters and @$items;
}

sub push :method
{
   my $self = shift;
   my @more = @_;

   $self->{finished} and
      croak "Cannot ->push more items to a Future::Queue that has been finished";

   my $items = $self->{items};
   my $max = $self->{max_items};

   if( defined $max ) {
      my $count = $max - @$items;
      push @$items, splice @more, 0, $count;
   }
   else {
      push @$items, @more;
      @more = ();
   }

   $self->_manage_shift_waiters;
   return Future->done if !@more;

   my $f = $self->{f_factory} ? $self->{f_factory}->() : $self->{f_prototype}->new;
   push @{ $self->{push_waiters} //= [] }, sub {
      my $count = $max - @$items;
      push @$items, splice @more, 0, $count;
      $self->_manage_shift_waiters;

      return 0 if @more;

      $f->done;
      return 1;
   };
   return $f;
}

=head2 shift

   $item = await $queue->shift;

Returns a C<Future> that will yield the next item from the queue. If there is
already an item then this will be taken and the returned future will be
immediate. If not, then the returned future will be pending, and the next
C<push> method will complete it.

If the queue has been finished then the future will yield an empty list, or
C<undef> in scalar context.

If C<undef> is a valid item in your queue, make sure to test this condition
carefully. For example:

   while( ( my $item ) = await $queue->shift ) {
      ...
   }

Here, the C<await> expression and the assignment are in list context, so the
loop will continue to iterate while I<any> value is assigned, even if that
value is C<undef>. The loop will only stop once no items are returned,
indicating the end of the queue.

=cut

sub _manage_push_waiters
{
   my $self = shift;

   my $items = $self->{items};
   my $max_items = $self->{max_items};
   my $push_waiters = $self->{push_waiters} || [];

   shift @$push_waiters
      while @$push_waiters and
         ( !defined $max_items or @$items < $max_items )
         and $push_waiters->[0]->();
}

sub shift :method
{
   my $self = shift;

   my $items = $self->{items};

   if( @$items ) {
      my @more = shift @$items;
      $self->_manage_push_waiters;
      return Future->done( @more );
   }

   return Future->done if $self->{finished};

   my $f = $self->{f_factory} ? $self->{f_factory}->() : $self->{f_prototype}->new;
   push @{ $self->{shift_waiters} }, sub {
      return $f->done if !@$items and $self->{finished};
      $f->done( shift @$items );
      $self->_manage_push_waiters;
   };
   return $f;
}

=head2 shift_atmost

   @items = await $queue->shift_atmost( $count );

I<Since version 0.50.>

A bulk version of L</shift> that can return multiple items at once.

Returns a C<Future> that will yield the next few items from the queue. If
there is already at least one item in the queue then up to C<$count> items
will be taken, and the returned future will be immediate. If not, then the
returned future will be pending and the next C<push> method will complete it.

=cut

sub shift_atmost
{
   my $self = shift;
   my ( $count ) = @_;

   my $items = $self->{items};

   if( @$items ) {
      my @more = splice @$items, 0, $count;
      $self->_manage_push_waiters;
      return Future->done( @more );
   }

   return Future->done if $self->{finished};

   my $f = $self->{f_factory} ? $self->{f_factory}->() : $self->{f_prototype}->new;
   push @{ $self->{shift_waiters} }, sub {
      return $f->done if !@$items and $self->{finished};
      $f->done( splice @$items, 0, $count );
      $self->_manage_push_waiters;
   };
   return $f;
}

=head2 finish

   $queue->finish;

I<Since version 0.50.>

Marks that the queue is now finished. Once the current list of items has been
exhausted, any further attempts to C<shift> more will yield empty.

=cut

sub finish
{
   my $self = shift;
   $self->{finished}++;

   ( shift @{ $self->{shift_waiters} } )->() while @{ $self->{shift_waiters} };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
