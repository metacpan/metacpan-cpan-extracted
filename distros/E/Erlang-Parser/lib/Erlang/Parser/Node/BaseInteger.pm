# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::BaseInteger;

use Moose;
with 'Erlang::Parser::Node';

has 'baseinteger' => (is => 'rw', required => 1, isa => 'Str');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;
	print $fh $self->baseinteger;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::BaseInteger - a number with base

=head1 DESCRIPTION

A number with a specified base.

=head2 Accessors

=over 4

=item C<baseinteger>

The string representation of the number.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	16#f7f7f7f7

=cut

1;

# vim: set sw=4 ts=4:
