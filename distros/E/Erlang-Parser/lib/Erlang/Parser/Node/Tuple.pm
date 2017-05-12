# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Tuple;

use Moose;
with 'Erlang::Parser::Node';

has 'elems' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh '{';
	my $first = 1;
	foreach (@{$self->elems}) {
		if ($first) { $first = 0 } else { print $fh ', ' }
		$_->print($fh, $depth);
	}

	print $fh '}';
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Tuple - a tuple of items

=head1 DESCRIPTION

A set number of items; if you need something with variable length, use lists.

=head2 Accessors

=over 4

=item C<elems>

The L<Erlang::Parser::Node>s which make up the tuple's elements.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	{1, 2, 3}

=cut

1;

# vim: set sw=4 ts=4:
