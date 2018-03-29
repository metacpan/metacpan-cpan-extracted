#!/usr/bin/perl

package Devel::Events::Handler::Multiplex;
# ABSTRACT: Delegate events to multiple handlers
our $VERSION = '0.09';
use Moose;

with qw/Devel::Events::Handler/;

use Set::Object;

has '_handlers' => (
	is        => 'ro',
	isa       => 'Set::Object',
	default   => sub { Set::Object->new },
);

sub BUILD {
	my ( $self, $param ) = @_;

	if ( my $handlers = $param->{handlers} ) {
		$self->add_handler( @$handlers );
	}
}

sub add_handler {
	my ( $self, @h ) = @_;
	$self->_handlers->insert(@h);
}

sub remove_handler {
	my ( $self, @h ) = @_;
	$self->_handlers->remove(@h);
}

sub handlers {
	my ( $self, @h ) = @_;

	if ( @h ) {
		$self->_handlers( Set::Object->new(@h) );
	}

	$self->_handlers->members;
}

sub new_event {
	my ( $self, @event ) = @_;

	foreach my $handler ( $self->handlers ) {
		$handler->new_event(@event);
	}
}

__PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Events::Handler::Multiplex - Delegate events to multiple handlers

=head1 VERSION

version 0.09

=head1 SYNOPSIS

	use Devel::Events::Handler::Multiplex;

	my $h = Devel::Events::Handler::Multiplex->new(
		handlers => \@handlers,
	);

	$h->add_handler( $other_handler );

	$h->new_event( ... );

	$h->remove_handler( $some_handler );

=head1 DESCRIPTION

This handler repeats events to any number of sub handlers.

It is useful as a central hub, delegating to any number of sub listeners, from
any number of generators.

=head1 METHODS

=over 4

=item new_event @handlers

Delegates the event to every one of the sub handlers.

=item handlers

Lists the handlers

=item add_handler $handler

Add a handler to the set of registered handlers.

=item remove_handler $handler

Remove a handler from the set of registered handlers.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Events>
(or L<bug-Devel-Events@rt.cpan.org|mailto:bug-Devel-Events@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
