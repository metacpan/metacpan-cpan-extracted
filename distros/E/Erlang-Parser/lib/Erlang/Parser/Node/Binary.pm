# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Binary;

use Moose;
with 'Erlang::Parser::Node';

has 'bexprs' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node::BinaryExpr]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh '<<';

	my $first = 1;
	foreach (@{$self->bexprs}) {
		if ($first) { $first = 0 } else { print $fh ', ' }
		$_->print($fh, $depth);
	}

	print $fh '>>';
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Binary - a binary string or list

=head1 DESCRIPTION

A compactly-stored block of data.

=head2 Accessors

=over 4

=item C<bexprs>

A list of L<Erlang::Parser::BinaryExpr>s; the individual expressions are
composed to create the binary string or list.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	<<"abc">>

=cut

1;

# vim: set sw=4 ts=4:
