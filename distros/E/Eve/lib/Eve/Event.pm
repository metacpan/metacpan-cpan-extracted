package Eve::Event;

use parent qw(Eve::Class);

use strict;
use warnings;

=head1 NAME

B<Eve::Event> - a base class for all event classes.

=head1 SYNOPSIS

    package Eve::Event::Foo;

    use parent qw(Eve::Event);

    1;

    my $event = Eve::Event::Foo->new(event_map => $event_map)
                                  ->trigger();

=head1 DESCRIPTION

B<Eve::Event> is an abstract class that must be inherited
by event classes. This will enable them to be triggered and have
handlers bound to them.

=head3 Constructor arguments:

=over 4

=item C<event_map>

an event map the event will interact with.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $event_map);

    $self->{'_event_map'} = $event_map;

    return;
}

=head2 B<trigger()>

The C<trigger()> method is used to start processing the event by all
handlers that are bound to it and its ancestors.

=cut

sub trigger {
    my $self = shift;

    my $handler_list = $self->_event_map->get_handler_list(event => $self);
    for my $handler (@{$handler_list}) {
        $handler->handle(event => $self);
    }

    return;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Class>

=item L<Eve::EventMap>

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
