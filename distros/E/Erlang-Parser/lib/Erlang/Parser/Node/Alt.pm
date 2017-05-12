# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Alt;

use Moose;
with 'Erlang::Parser::Node';

has 'catch' => (is => 'rw', required => 0, isa => 'Bool');
has 'class' => (is => 'rw', required => 0, isa => 'Maybe[Str]');
has 'expr'  => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node');
has 'whens' => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node::WhenList');
has 'stmts' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh $self->class, ':' if defined($self->class);
	$self->expr->print($fh, $depth);
	$depth++;
	print $fh ' ';

	$self->whens->print($fh, $depth);
	
	print $fh "->\n", "\t" x $depth;

	my $first = 1;
	foreach (@{$self->stmts}) {
		if ($first) { $first = 0 } else { print $fh ",\n", "\t" x $depth }
		$_->print($fh, $depth);
	}

	$depth--;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Alt - an alternative in a case or try

=head1 DESCRIPTION

One alternative (the catch class (if any), pattern match, guards (if any) and
expressions) in a case or try statement.

=head2 Accessors

=over 4

=item C<catch>

True if this is a case in a catch clause. If so, it will also possess the
C<class> attribute.

=item C<class>

The class in the pattern match; the 'Z' in try X catch Y:Z -> ... end.

=item C<expr>

The L<Erlang::Parser::Node> pattern match expression.

=item C<whens>

A L<Erlang::Parser::Node::WhenList> of guard sequences/expressions, if any.

=item C<stmts>

A list of L<Erlang::Parser::Node>s; the body executed for this alternative.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	{X, Y} when is_bool(X) ->
		Z = Y + Y,
		Z * 2

=cut

1;

# vim: set sw=4 ts=4:
