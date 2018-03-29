#!/usr/bin/perl

package Devel::Events::Generator;
# ABSTRACT: An optional base role for event generators.
our $VERSION = '0.09';
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

=encoding UTF-8

=head1 NAME

Devel::Events::Generator - An optional base role for event generators.

=head1 VERSION

version 0.09

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
