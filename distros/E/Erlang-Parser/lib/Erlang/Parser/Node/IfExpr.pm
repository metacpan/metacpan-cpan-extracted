# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::IfExpr;

use Moose;
with 'Erlang::Parser::Node';

has 'seq'   => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');
has 'stmts' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	my $first = 1;
	foreach (@{$self->seq}) {
		if ($first) { $first = 0 } else { print $fh ', ' }
		$_->print($fh, $depth);
	}
	print $fh " ->\n";

	$depth++;
	print $fh "\t" x $depth;
	
	$first = 1;
	foreach (@{$self->stmts}) {
		if ($first) { $first = 0 } else { print $fh ",\n", "\t" x $depth }
		$_->print($fh, $depth);
	}
	$depth--;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::IfExpr - a case in an if statement

=head1 DESCRIPTION

A block of statements; a glorified parenthesis.

=head2 Accessors

=over 4

=item C<seq>

The guard sequence; a list of L<Erlang::Parser::Node>s.

=item C<exprs>

The body of L<Erlang::Parser::Node>s to be executed if C<seq> evalutes true.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	X>Y ->
		true

=cut

1;

# vim: set sw=4 ts=4:
