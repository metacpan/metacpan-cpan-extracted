# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Variable;

use Moose;
with 'Erlang::Parser::Node';

has 'variable' => (is => 'rw', required => 1, isa => 'Str');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh $self->variable;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Variable - a variable

=head1 DESCRIPTION

Any use or reference to a variable, bound or unbound.

=head2 Accessors

=over 4

=item C<variable>

The name of the variable.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	Argument

=cut

1;

# vim: set sw=4 ts=4:
