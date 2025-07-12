#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023-2025 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.800;
use Future::AsyncAwait 0.44 ':experimental(cancel)';
use Sublike::Extended 0.29 'method';

class Future::Selector 0.05;

use Carp;
use Scalar::Util qw( refaddr );

=head1 NAME

C<Future::Selector> - manage a collection of pending futures

=head1 SYNOPSIS

   use Future::AsyncAwait;
   use Future::IO;
   use Future::Selector;
   use IO::Socket::IP;

   my $selector = Future::Selector->new;

   my $listensock = IO::Socket::IP->new(
      LocalHost => "::1",
      LocalPort => "8191",
      Listen => 1,
   );

   $selector->add(
      data => "listener",
      gen  => sub { Future::IO->accept( $listensock ) },
   );

   while(1) {
      my @ready = await $selector->select;

      ...
   }

=head1 DESCRIPTION

Objects in this class maintain a collection of pending L<Future> instances,
and manage the lifecycle of waiting for their eventual completion. This
provides a central structure for writing asynchronous event-driven programs
using L<Future> and L<Future::IO>-based logic.

When writing an asynchronous C<Future>-based client, often the program can be
structured similar to a straight-line synchronous program, where at any point
the client is just waiting on sending or receiving one particular message or
data-flow. It therefore suffices to use a simple call/response structure,
perhaps written using the C<async> and C<await> keywords provided by
L<Future::AsyncAwait>.

In contrast, a server program often has many things happening at once. It will
be handling multiple clients simultaneously, as well as waiting for new client
connections and any other internal logic it requires to provide data to those
clients. There is not just one obvious pending future at any one time; there
could be several that all need to be monitored for success or failure.

A C<Future::Selector> instance helps this situation, by storing an entire set
of pending futures that represent individual sub-divisions of the work of the
program (or a part of it). As each completes, the selector instance informs
the containing code so it can continue to perform the work required to handle
that part, perhaps resulting in more future instances for the selector to
manage.

=head2 Program Structure

As per the SYNOPSIS example, a typical server-style program would probably be
structured around a C<while(1){}> loop that repeatedly C<await>s on the next
C<select> future from the selector instance, looking for the next thing to do.
The data values stored with each future and returned by the C<select> method
can be used to help direct the program into working out what is going on. For
example, string names or object instances could help identify different kinds
of next step.

   use v5.36;

   ...

   $selector->add(
      data => "listener",
      gen  => sub { Future::IO->accept( $listensock ) },
   );

   while(1) {
      foreach my ( $data, $f ) ( await $selector->select ) {
         if( $data eq "listener" ) {
            # a new client has been accept()ed. should now set up handling
            # for it in some manner.

            my $sock = await $f;
            my $clientconn = ClientConnection->new( fh => $sock );

            $selector->add( data => $clientconn, f => $clientconn->run );
         }
         elsif( $data isa ClientConnection ) {
            # an existing connection's runloop has terminated. should now
            # handle that in whatever way is appropriate
            ...
         }
         ...
      }
   }

Alternatively, if each stored future instance already performed all of the
work required to handle it before it yields success, there may be nothing for
the toplevel application loop to do other than repeatedly wait for things to
happen.

   $selector->add(
      data => undef, # ignored
      gen  => async sub {
         my $sock = await Future::IO->accept( $listensock );
         my $clientconn = ClientConnection->new( fh => $sock );

         $selector->add( data => undef, f => $clientconn->run );
      }
   );

   await $selector->select while 1;

Failure propagation by the C<select> method here ensures any errors
encountered by individual component futures are still passed upwards through
the program structure, ultimately ending at the toplevel if nothing else
catches it first.

=head2 Comparison With C<select(2)>, C<epoll>, etc..

In some ways, the operation of this class is similar to system calls like
C<select(2)> and C<poll(2)>. However, there are several key differences:

=over 4

=item *

C<Future::Selector> stores high-level futures, rather than operating directly
on system-level filehandles. As such, it can wait for application-level
events and workflow when those things are represented by futures.

=item *

The main waiting call, L</select>, is a method that returns a future. This
could be returned from some module or component of a program, to be awaited on
by another outer  C<Future::Selector> instance. The application is not
limited to exactly one as would be the case for blocking system calls, but can
instead create a hierarchical structure out of as many instances as are
required.

=item *

Once added, a given future remains a member of a C<Future::Selector> instance
until it eventually completes; which may require many calls to the C<select>
method (or indeed, it may never complete during the lifetime of the program,
for tasks that should keep pending throughout). In this way, the object is
more comparable to persistent system-level schedulers like Linux's C<epoll> or
BSD's C<kqueue> mechanisms, than the one-shot nature of C<select(2)> or
C<poll(2)> themselves.

=back

=cut

class Future::Selector::_Item {
   field $data :param :reader;
   field $f    :param :mutator;
   field $gen  :param :reader;
}

field %items; # keyed by refaddr

=head1 METHODS

=cut

field $next_waitf;
field @next_ready;
field $next_failure;
field @items_needing_regen;

method _item_is_ready ( $item )
{
   my $f = $item->f;

   delete $items{ refaddr $item };

   if( $item->gen ) {
      push @items_needing_regen, $item;
   }

   return if $f->is_cancelled;

   if( $next_waitf ) {
      if( $f->is_failed ) {
         $f->on_fail( $next_waitf ); # copy the failure
      }
      else {
         $next_waitf->done( $item->data, $item->f );
      }
   }
   else {
      if( $f->is_failed ) {
         $next_failure //= $f;
      }
      else {
         push @next_ready, $item->data, $item->f;
      }
   }
}

=head2 add

   $selector->add( data => $data, f => $f );

Adds a new future to the collection.

After the future becomes ready, the currently-pending C<select> future (or the
next one to be created) will complete. It will yield the given data and future
instance if this future succeeded, or fail with the same failure if this
future failed. At that point it will be removed from the stored collection.
If the item future was cancelled, it is removed from the collection but
otherwise ignored; the C<select> future will continue waiting for another
result.

   $selector->add( data => $data, gen => $gen );

      $f = $gen->();

Adds a new generator of futures to the collection.

The generator is a code reference which is used to generate a future, which is
then added to the collection similar to the above case. Each time the future
becomes ready, the generator is called again to create another future to
continue watching. This continues until the generator returns C<undef>.

=cut

method add ( :$data, :$f = undef, :$gen = undef )
{
   if( $gen and !$f ) {
      # TODO: Consider if we should do this immediately at all?
      $f = $gen->();
   }
   elsif( !$f ) {
      croak "Require 'f' or 'gen'";
   }

   my $item = Future::Selector::_Item->new(
      data => $data,
      f    => $f,
      gen  => $gen,
   );
   $items{ refaddr $item } = $item;

   $f->on_ready( sub { $self->_item_is_ready( $item ) } );

   return;
}

=head2 select

   ( $data1, $f1, $data2, $f2, ... ) = await $selector->select();

Returns a future that will become ready when at least one of the stored
futures is ready. It will yield an even-sized list of pairs, giving the
associated data and original (now-completed) futures that were stored.

If you are intending to run the loop indefinitely, be careful not to write
code such as

   1 while await $selector->select;

because in scalar context, the C<await>ed future will yield its first value,
which will be the data associated with the first completed future. If that
data value was false (such as C<undef>) then the loop will stop running at
that point. Generally in these sorts of situations you want to use L</run> or
L</run_until_ready>.

=cut

method select ()
{
   my $wait_f = $next_waitf // do {
      if( my @i = @items_needing_regen ) {
         undef @items_needing_regen;

         foreach my $item ( @i ) {
            my $f = $item->gen->() or next;

            $f->on_ready( sub { $self->_item_is_ready( $item ) } );
            $item->f = $f;
            $items{ refaddr $item } = $item;
         }
      }

      keys %items or @next_ready or $next_failure or
         croak "$self cowardly refuses to sit idle and do nothing";

      $_->f->is_ready or $next_waitf = $_->f->new, last for values %items;
      $next_waitf //= Future->new;

      $next_waitf->set_label( "Future::Selector next_waitf" );

      if( $next_failure ) {
         $next_failure->on_fail( $next_waitf ); # copy the failure
         undef $next_failure;
      }
      elsif( @next_ready ) {
         $next_waitf->done( @next_ready );
         undef @next_ready;
      }

      $next_waitf->on_ready( sub { undef $next_waitf } );
   };

   # We need to ensure that overlapping calls to ->select can't accidentally
   # cancel each other.
   # A simple call to ->without_cancel doesn't quite work as it causes
   # sequence futures to be lost.

   my $ret_f = $wait_f->new;
   $wait_f->on_done( $ret_f )
      ->on_fail( $ret_f );
   # nothing about cancel of $ret_f here. technically if we don't tidy up the
   # on_done/on_fail above these will retain $ret_f longer than necessary, but
   # there's no API to do that currently. Hopefully $wait_f will get cycled
   # and replaced soon enough anyway and that will all go then.
   return $ret_f;
}

=head2 run

   await $selector->run();

I<Since version 0.02.>

Returns a future that represents repeatedly calling the L</select> method
indefinitely. This will not return, except that if any of the contained
futures fails then this will fail the same way.

This is most typically used at the toplevel of a server-type program, one
where there is no normal exit condition and the program is expected to remain
running unless some fatal error happens.

=cut

async method run ()
{
   await $self->select while 1;
}

=head2 run_until_ready

   @result = await $selector->run_until_ready( $f );

I<Since version 0.02.>

Returns a future that represents repeatedly calling the L</select> method
until the given future instance is ready. When it becomes ready (either by
success or failure) the returned future will yield the same result. If the
returned future is cancelled, then C<$f> itself will be cancelled too. This
will not cancel a concurrently-pending C<select> or C<run> call, however.

The given future will be added to the selector by calling this method; you
should I<not> call L</add> on it yourself first.

This is typically used in client or hybrid code, or as a nested component of
a server program, which needs to wait on a result while also performing other
background tasks.

Remember that since this method itself returns a future, it could easily serve
as the input to another outer-level selector instance.

=cut

async method run_until_ready ( $f )
{
   $self->add( data => undef, f => $f );
   CANCEL { $f->cancel; }
   await $self->select until $f->is_ready;
   return await $f;
}

=head1 TODO

=over 4

=item *

Convenience ->add_f / ->add_gen

=item *

Configurable behaviour on component future failure

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
