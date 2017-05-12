#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Event::Distributor;

use strict;
use warnings;

our $VERSION = '0.04';

use Carp;

use Future;

use Event::Distributor::Signal;
use Event::Distributor::Action;
use Event::Distributor::Query;

=head1 NAME

C<Event::Distributor> - a simple in-process pub/sub mechanism

=head1 SYNOPSIS

 use Event::Distributor;

 my $dist = Event::Distributor->new;

 $dist->declare_signal( "announce" );


 $dist->subscribe_sync( announce => sub {
    my ( $message ) = @_;
    say $message;
 });

 $dist->subscribe_async( announce => sub {
    my ( $message ) = @_;
    return $async_http->POST( "http://server/message", $message );
 });


 $dist->fire_sync( announce => "Hello, world!" );

=head1 DESCRIPTION

Instances of this class provide a simple publish/subscribe mechanism within a
single process, for either synchronous or L<Future>-based asynchronous use.

A given instance has a set of named events. Subscribers are C<CODE> references
attached to a named event. Publishers can declare the existence of a named
event, and then later invoke it by passing in arguments, which are distributed
to all of the subscribers of that named event.

It is specifically I<not> an error to request to subscribe an event that has
not yet been declared, in order to allow multiple modules of code to be loaded
and subscribe events the others publish, without introducing loading order
dependencies. An event only needs to be declared by the time it is fired.

Natively all of the events provided by the distributor are fully-asynchronous
in nature. Each subscriber is expected to return a L<Future> instance which
will indicate its completion; the results of these are merged into a single
future returned by the fire method itself. However, to support synchronous or
semi-synchronous programs using it, both the observe and invoke methods also
have a synchronous variant. Note however, that this module does not provide
any kind of asynchronous detachment of synchronous functions; using the
L</subscribe_sync> method to subscribe a long-running blocking function will
cause the C<fire_*> methods to block until that method returns. To achieve a
truely-asynchronous experience the attached code will need to use some kind of
asynchronous event system.

This module is very-much a work-in-progress, and many ideas may still be added
or changed about it. It is the start of a concrete implementaion of some of
the ideas in my "Event-Reflexive Programming" series of blog posts. See the
L</TODO> and L</SEE ALSO> sections for more detail.

=head1 EVENTS

Each of the events known by a distributor has a name. Conceptually each also
has a type. Currently there are three types of event, a "signal", an "action",
and a "query".

=over 2

=item *

A signal event simply informs subscribers that some event or condition has
occurred. Additional arguments can be passed from the invoker to the
subscribers, but subscriptions are not expected to return a meaningful value,
nor does firing this event return a value. All subscriber functions are
invoked sequentually and synchronously by a C<fire_*> method (though, of
course, asynchronous subscribers synchronously return a future instance, which
allows them to continue working asynchronously).

=item *

An action event requires a single subscriber, and represents a request from
the invoker to the subscriber to perform some activity. This behaves much like
a regular (L<Future>-returning) method call, except that the indirection
mechanism of the distributor allows a more flexible method of connection
between the two sides.

=item *

A query event invokes subscriber code expecting a successful return, returning
the first result that is successful. If a synchronous subscriber returns a
result, or if an asynchronous one returns a successful immediate Future, then
no further subscribers are invoked, and that result is taken immediately. Any
other pending Futures are then cancelled.

=back

=cut

sub new
{
   my $class = shift;

   my $self = bless {
      events           => {},
      pre_registration => {},
   }, $class;

   return $self;
}

=head1 METHODS

=cut

sub _add_event
{
   my $self = shift;
   my ( $name, $event ) = @_;

   $self->{events}{$name} and
      croak "Cannot declare an event '$name' a second time";

   $self->{events}{$name} = $event;

   if( my $subs = delete $self->{pre_registration}{$name} ) {
      $event->subscribe( $_ ) for @$subs;
   }
}

=head2 declare_signal

   $distributor->declare_signal( $name )

Declares a new "signal" event of the given name.

=cut

sub declare_signal
{
   my $self = shift;
   my ( $name ) = @_;

   $self->_add_event( $name, Event::Distributor::Signal->new );
}

=head2 declare_action

   $distributor->declare_action( $name )

I<Since version 0.04.>

Declares a new "action" event of the given name.

=cut

sub declare_action
{
   my $self = shift;
   my ( $name ) = @_;

   $self->_add_event( $name, Event::Distributor::Action->new );
}

=head2 declare_query

   $distributor->declare_query( $name )

I<Since version 0.02.>

Declares a new "query" event of the given name.

=cut

sub declare_query
{
   my $self = shift;
   my ( $name ) = @_;

   $self->_add_event( $name, Event::Distributor::Query->new );
}

=head2 subscribe_async

   $distributor->subscribe_async( $name, $code )

Adds a new C<CODE> reference to the list of subscribers for the named event.
This subscriber is expected to return a L<Future> that will eventually yield
its result.

When invoked the code will be passed the distributor object itself and the
list of arguments, and is expected to return a L<Future>.

 $f = $code->( $distributor, @args )

=cut

sub subscribe_async
{
   my $self = shift;
   my ( $name, $code ) = @_;

   if( my $event = $self->{events}{$name} ) {
      $event->subscribe( $code );
   }
   else {
      push @{ $self->{pre_registration}{$name} }, $code;
   }
}

=head2 subscribe_sync

   $distributor->subscribe_sync( $name, $code )

Adds a new C<CODE> reference to the list of subscribers for the named event.
This subscriber is expected to perform its work synchronously and return its
result immediately.

In non-blocking or asynchronous applications, this method should only be used
for simple subscribers which can immediately return having completed their
work. If the work is likely to take some time by blocking on external factors,
consider instead using the L</subscribe_async> method.

When invoked the code will be passed the distributor object itself and the
list of arguments.

 $code->( $distributor, @args )

=cut

sub subscribe_sync
{
   my $self = shift;
   my ( $name, $code ) = @_;

   $self->subscribe_async( $name, sub {
      Future->done( $code->( @_ ) )
   });
}

=head2 fire_async

   $f = $distributor->fire_async( $name, @args )

Invokes the named event, passing the arguments to the subscriber functions.
This function returns as soon as all the subscriber functions have been
invoked, returning a L<Future> that will eventually complete when all the
futures returned by the subscriber functions have completed.

=cut

sub fire_async
{
   my $self = shift;
   my ( $name, @args ) = @_;

   my $event = $self->{events}{$name} or
      croak "Cannot fire an event '$name' when it doesn't exist";

   $event->fire( $self, @args );
}

=head2 fire_sync

   $distributor->fire_sync( $name, @args )

Invokes the named event, passing the arguments to the subscriber functions.
This function synchronously waits until all the subscriber futures have
completed, and will return once they have all done so.

Note that since this method calls the C<get> method on the Future instance
returned by L</fire_async>, it is required that this either be an immediate, or
be some subclass that can actually perform the await operation. This should be
the case if it is provided by an event framework or similar, or custom
application logic.

=cut

sub fire_sync
{
   my $self = shift;
   $self->fire_async( @_ )->get;
}

=head1 TODO

Some of these ideas appear in the "Event-Reflexive Progamming" series of blog
posts, and may be suitable for implementation here. All of these ideas are
simply for consideration; there is no explicit promise that any of these will
actually be implemented.

=over 4

=item *

Unsubscription from events.

=item *

Define (or document the lack of) ordering between subscriptions of a given
event.

=item *

Refine the failure-handling semantics of signals.

=item *

Ability to invoke signals after the current one is finished, by deferring the
C<fire> method. Should this be a new C<fire_*> method, or a property of the
signal itself?

=item *

More control over the semantics of value-returning events - scatter/map/gather
pattern.

=item *

Sub-heirarchies of events.

=item *

Subclasses for specific event frameworks (L<IO::Async>).

=item *

Subclasses (or other behaviours) for out-of-process event serialisation and
subscribers.

=item *

Event parameter filtering mechanics - allows parametric heirarchies,
instrumentation logging, efficient out-of-process subscribers.

=back

=head1 SEE ALSO

=over 4

=item L<Event-Reflexive Programming|http://leonerds-code.blogspot.co.uk/search/label/event-reflexive>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
