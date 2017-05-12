# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Def;

use Moose;
with 'Erlang::Parser::Node';

has 'def'   => (is => 'rw', required => 1, isa => 'Str');
has 'args'  => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');
has 'whens' => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node::WhenList');
has 'stmts' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh $self->def, '(';

	my $first = 1;
	foreach (@{$self->args}) {
		if ($first) { $first = 0 } else { print $fh ', ' }
		$_->print($fh, $depth);
	}
	
	$depth++;

	print $fh ") ";

	$self->whens->print($fh, $depth);
	
	print $fh "->\n", "\t" x $depth;
	$first = 1;
	foreach (@{$self->stmts}) {
		if ($first) { $first = 0 } else { print $fh ",\n", "\t" x $depth }
		$_->print($fh, $depth);
	}

	$depth--;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Def - a match in a function definition

=head1 DESCRIPTION

Contains a single pattern match and guard expr/seq list, with the body of the
function.

=head2 Accessors

=over 4

=item C<def>

The name of the function.

=item C<args>

A list of L<Erlang::Parser::Node>s which constitute the argument patterns to be
matched.

=item C<whens>

The L<Erlang::Parser::Node::WhenList> containing guard expressions/sequences.

=item C<stmts>

A list of L<Erlang::Parser::Node>s; the body for the function.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	x(Y) ->
		Z = Y + Y,
		Z * 2

=cut

1;

# vim: set sw=4 ts=4:
