#!/usr/bin/perl

package Devel::Events::Generator::ClassPublisher;
use Moose;

with qw/Devel::Events::Generator/;

use Class::Publisher;

our $VERSION = "0.01";

sub subscribe {
	my ( $self, $publisher, $event ) = @_;

	$event = '*' unless defined $event;

	$publisher->add_subscriber( $event, $self );
}

sub unsubscribe {
	my ( $self, $publisher, $event ) = @_;

	$publisher->delete_subscriber($event, $self);
}

sub update {
	my ( $self, $publisher, $type, @data ) = @_;
	$self->send_event( $type, publisher => $publisher, @data );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Generator::ClassPublisher - Relay events from
L<Class::Publisher>

=head1 SYNOPSIS

	use Devel::Events::Generator::ClassPublisher;

	my $gen = Devel::Events::Generator::ClassPublisher->new(
		handler => $handler,
	);

	$gen->subscribe( $publisher, $event );

=head1 DESCRIPTION

This event generator can glue events from L<Class::Publisher> into the
L<Devel::Events> framework.

This is useful if you wish to place certain events like
L<Devel::Events::Objects>'s ones in a certain context by later analyzing the in
memory log.

=head1 METHODS

=over 4

=item subscribe $publisher, [ $event ]

=item unsubscribe $publisher, [ $event ]

These convenience methods are provided if you prefer calling

	$gen->subscribe($publisher, $event);

over

	$publisher->add_subscriber($event, $gen);

If C<$event> is omitted then all events are assumed.

=item update $publisher, $event, @args

Called by L<Class::Publisher/notify_subscribers>. Will raise an event with the
value:

	$event, publisher => $publisher, @args

A custom filter right after this generator to munge C<@args> into a key value
pair list is reccomended if your events are not structured that way to begin
with.

=back

=head1 SEE ALSO

L<Devel::Events>, L<Class::Publisher>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2007 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute it and/or modify it
	under the terms of the MIT license or the same terms as Perl itself.

=cut


