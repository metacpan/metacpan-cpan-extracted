# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Float;

use Moose;
with 'Erlang::Parser::Node';

has 'float' => (is => 'rw', required => 1, isa => 'Num');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;
	print $fh $self->float;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Float - a floating point integer

=head1 DESCRIPTION

A number with decimal places.

=head2 Accessors

=over 4

=item C<float>

The value.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	4.1

=cut

1;

# vim: set sw=4 ts=4:
