package Ekahau::Events;
use base 'Ekahau::Base'; our $VERSION = $Ekahau::Base::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use warnings;
use strict;

use base 'Exporter';
our %EXPORT_TAGS = (events => [ qw(

EKAHAU_EVENT_DEVICE_LIST EKAHAU_EVENT_DEVICE_PROPERTIES
EKAHAU_EVENT_AREA_ESTIMATE EKAHAU_EVENT_LOCATION_ESTIMATE
EKAHAU_EVENT_LOCATION_CONTEXT EKAHAU_EVENT_MAP_IMAGE
EKAHAU_EVENT_AREA_LIST EKAHAU_EVENT_STOP_AREA_TRACK_OK
EKAHAU_EVENT_STOP_LOCATION_TRACK_OK
EKAHAU_EVENT_ERROR 
EKAHAU_EVENT_ANY EKAHAU_EVENT_ANY_TAG
				   )]);
our @EXPORT_OK = (@{$EXPORT_TAGS{events}});

use constant EKAHAU_EVENT_DEVICE_LIST => 'DEVICE_LIST';
use constant EKAHAU_EVENT_DEVICE_PROPERTIES => 'DEVICE_PROPERTIES';
use constant EKAHAU_EVENT_AREA_ESTIMATE => 'AREA_ESTIMATE';
use constant EKAHAU_EVENT_LOCATION_ESTIMATE => 'LOCATION_ESTIMATE';
use constant EKAHAU_EVENT_LOCATION_CONTEXT => 'CONTEXT';
use constant EKAHAU_EVENT_MAP_IMAGE => 'MAP';
use constant EKAHAU_EVENT_AREA_LIST => 'AREALIST';
use constant EKAHAU_EVENT_STOP_AREA_TRACK_OK => 'STOP_AREA_TRACK_OK';
use constant EKAHAU_EVENT_STOP_LOCATION_TRACK_OK => 'STOP_LOCATION_TRACK_OK';
use constant EKAHAU_EVENT_ERROR => 'ERROR';
use constant EKAHAU_EVENT_ANY => '';
use constant EKAHAU_EVENT_ANY_TAG => '';


=head1 NAME

Ekahau::Events - Event-driven interface to Ekahau location sensing system

=head1 SYNOPSIS

The C<Ekahau::Events> class provides an event-driven interface to the
Ekahau location sensing system's YAX protocol.

This class inherits from L<Ekahau::Base|Ekahau::Base>, and you can use methods from
that class.  An alternative, synchronous interface is provided by the
L<Ekahau|Ekahau> class.

=head1 DESCRIPTION

This class implements methods for registering event handlers to
receive particular Ekahau responses, and dispatching events based on
responses received from Ekahau.  Requests can be sent using methods
available from L<Ekahau::Base|Ekahau::Base>.

=head2 Constructor

This class uses L<Ekahau::Base::new|Ekahau::Base/new> as its constructor.

=head2 Methods

=head3 register_handler ( $tag, $event, $handler )

Registers an event handling sub for the given tag and event.  C<$tag>
and C<$event> should be strings representing the tag and event to be
handled, and C<$handler> is a subroutine reference.

Both the tag and event must match for the handler to be called.  If
one or the other is C<undef>, events with any value for that property
will be handled by C<$handler>; if both are C<undef>, any event will
be handled by the given C<$handler>.

When L<dispatchone|/dispatchone> is looking for an event handler, it will first
look for a registered handler matching both C<$tag> and C<$event>,
then matching just C<$tag>, then matching just C<$event>, and finally
the "default handler" registered with both C<$tag> and C<$event> set
to C<undef>.  If none of these match, the event is ignored.

If an event matches, C<$handler> will be called with an
L<Ekahau::Response|Ekahau::Response> object as the first parameter, followed by the
tag, followed by the event.

Each handler takes up a small amount of memory, so make sure you call
L<unregister_handler|/unregister_handler> when you no longer need to handle the event.
If you're just handling a single event one time, consider using
L<register_handler_once|/register_handler_once>, which automatically unregisters the event
afterwards.

=cut

sub register_handler
{
    my $self = shift;
    my($tag,$event,$handler) = @_;
    
    $tag ||= '';
    $event ||= '';
    
    warn 'EVENTS: '.($handler?"Registered":"Unregistered")." event for tag '$tag', event '$event'\n"
	if ($ENV{EVENTS_VERBOSE});
    $self->{_handler}{$tag}{$event} = $handler;
}

=head3 register_handler_once ( $tag, $event, $handler )

Registers an event handling sub for the given tag and event, just like
L<register_handler|/register_handler>, but when the event completes automatically
unregisters the handler.

This is useful for simple requests with simple responses, to avoid
leaking memory.

=cut

sub register_handler_once
{
    my $self = shift;
    my($tag,$event,$handler) = @_;

    $self->register_handler($tag,$event,sub { $self->unregister_handler($tag,$event); $handler->(@_); });
}

=head3 unregister_handler ( $tag, $event )

Unregister the handler for the given C<$tag> and C<$event>.

=cut

sub unregister_handler
{
    my $self = shift;
    $self->register_handler($_[0],$_[1],undef);
}

=head3 dispatch ( )

Read pending events from the Ekahau server, and call the registered
handler for each of them.  This call will block; to avoid that, you
should first use the L<Ekahau::Base::can_read|Ekahau::Base/can_read> method or select on the
filehandles returned by L<Ekahau::Base::select_handles|Ekahau::Base/select_handles>.

=cut

sub dispatch
{
    my $self = shift;

    $self->readsome();
    while (my $ev = $self->getpending)
    {
	$self->dispatchone($ev);
    }
}

=head3 dispatchone ( $event )

Dispatch a single event to the appropriate handler.  Generally you
won't call this yourself, relying on L<dispatch|/dispatch> to do it for you.

=cut

sub dispatchone
{
    my $self = shift;
    my($ev)=@_;
    my $handler;

    my $cmd = $ev->error ? 'ERROR' : $ev->{cmd};
    my $tag = $ev->{tag};

    if (      ($handler = $self->{_handler}{$tag}{$cmd})
	   or ($handler = $self->{_handler}{$tag}{''})
	   or ($handler = $self->{_handler}{''}{$cmd})
           or ($handler = $self->{_handler}{''}{''}))
    {
        $handler->($ev,$tag,$cmd);
    }
    # Unhandled event, just ignore.
}

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Base|Ekahau::Base>, L<Ekahau|Ekahau>.

=cut


1;
