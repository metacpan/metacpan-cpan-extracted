# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::If;

use Moose;
with 'Erlang::Parser::Node';

has 'cases' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node::IfExpr]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh "if\n";

	$depth++;
	print $fh "\t" x $depth;
	my $first = 1;
	foreach (@{$self->cases}) {
		if ($first) { $first = 0 } else { print $fh ";\n", "\t" x $depth }
		$_->print($fh, $depth);
	}

	$depth--;
	print $fh "\n", "\t" x $depth, "end";
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::If - an 'if' statement

=head1 DESCRIPTION

A list of guards and statement blocks to execute if one is true.

=head2 Accessors

=over 4

=item C<cases>

A list of L<Erlang::Parser::Node::IfExpr>s.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	if
		X>Y ->
			true;
		true ->
			false
	end

=cut

1;

# vim: set sw=4 ts=4:
