# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::UnOp;

use Moose;
with 'Erlang::Parser::Node';

has 'op' => (is => 'rw', required => 1, isa => 'Str');
has 'a'  => (is => 'rw', required => 1, does => 'Erlang::Parser::Node');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh '(';
	print $fh $self->op;
	print $fh ' ';
	$self->a->print($fh, $depth);
	print $fh ')';
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::UnOp - a unary operation

=head1 DESCRIPTION

An prefix unary operation.

=head2 Accessors

=over 4

=item C<op>

The operation as a string (i.e. '!', 'not').

=item C<a>

The L<Erlang::Parser::Node> argument to the operation.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	!true

=cut

1;

# vim: set sw=4 ts=4:
