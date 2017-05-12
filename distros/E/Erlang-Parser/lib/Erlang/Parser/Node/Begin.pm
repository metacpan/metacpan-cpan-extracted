# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Begin;

use Moose;
with 'Erlang::Parser::Node';

has 'exprs' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh "begin\n";

	$depth++;
	print $fh "\t" x $depth;

	my $first = 1;
	foreach (@{$self->exprs}) {
		if ($first) { $first = 0 } else { print $fh ",\n", "\t" x $depth }
		$_->print($fh, $depth);
	}

	$depth--;

	print $fh "\n", "\t" x $depth, 'end';
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Begin - a block of statements

=head1 DESCRIPTION

A block of statements; a glorified parenthesis.

=head2 Accessors

=over 4

=item C<exprs>

A list of L<Erlang::Parser::Node>s; the body for this block. The last
expression is the value for the block.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	begin
		do_this(),
	xyz:do_that()
	end

=cut

1;

# vim: set sw=4 ts=4:
