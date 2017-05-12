#!/usr/bin/perl

package Devel::Events::Generator;
use Moose::Role;

has handler => (
	# does => "Devel::Events::Handler", # we like duck typing
	isa => "Object",
	is  => "rw",
	required => 1,
);

sub send_event {
	my ( $self, $type, @data ) = @_;
	$self->handler->new_event( $type, generator => $self, @data );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Generator - An optional base role for event generators.

=head1 SYNOPSIS

	package MyGen;
	use Moose;

	with qw/Devel::Events::Generator/;

	sub whatever {
		my ( $self, @args ) = @_;

		# ...

		$self->send_event( @event );
	}

=head1 DESCRIPTION

This convenience role provides a basic C<send_event> method, useful for
implementing generators.

=head1 ATTRIBUTES

=over 4

=item handler

Accepts any object.

Required.

=back

=head1 METHODS

=over 4

=item send_event @event

Delegates to C<handler>, calling the method C<new_event> on it.

The field C<generator> with the value of the generator object will be
prepended.

=back

=cut

