package Eve::EventMap;

use parent qw(Eve::Class);

use strict;
use warnings;

=head1 NAME

Eve::EventMap - maps events to event handlers.

=head1 SYNOPSIS

    my $event_map = Eve::EventMap->new();

    $event_map->bind(
        event_class => 'Eve::Event::Foo',
        handler => $some_handler);

    $event_map->bind(
        event_class => 'Eve::Event::Bar',
        handler => $another_handler);

    my $event = Eve::Event::Foo->new(event_map => $event_map);

=head1 DESCRIPTION

B<Eve::EventMap> is the facility on the one hand used to bind
events to event handlers, on the other hand to extract handlers that
need to be run when a certain event is triggered.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my $self = shift;

    $self->{'_map'} = {};

    return;
}

=head2 B<bind()>

Binds an event class to an event handler.

=head3 Arguments

=over 4

=item C<event_class>

an event class (B<Eve::Event> derivative)

=item C<handler>

a handler instance (B<Eve::EventHandler::Class> derivative).

=back

=head3 Throws

=over 4

=item C<Eve::Exception::Duplicate>

trying to bind a handler duplicating one that has already been bound
to the event.

=back

=cut

sub bind {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($event_class, $handler));

    if (not exists $self->_map->{$event_class}) {
        $self->_map->{$event_class} = [];
    } else {
        if (grep($_ == $handler, @{$self->_map->{$event_class}})) {
            Eve::Exception::Duplicate->throw(
                message => 'Duplicate handler in the event map: '.$handler);
        }
    }

    push(@{$self->_map->{$event_class}}, $handler);

    return;
}

=head2 B<get_handler_list()>

Returns handler list for an event.

=head3 Arguments

=over 4

=item C<event>

an event instance we are requesting handlers for.

=back

=head3 Returns

Unified list of handlers bound to the event and to all its
ancestors. Note that if one handler is bound to an event and its
ancestors it will be returned only once.

=cut

sub get_handler_list {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $event);

    my $handler_list = [];
    for my $event_class (keys %{$self->_map}) {
        if ($event->isa($event_class)) {
            push(@{$handler_list}, @{$self->_map->{$event_class}});
        }
    }

    return Eve::Support::unique(list => $handler_list);
}

=head1 SEE ALSO

=over 4

=item L<Eve::Class>

=item L<Eve::Event>

=item L<Eve::EventHandler>

=item L<Eve::Exception>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=back

=cut

1;
