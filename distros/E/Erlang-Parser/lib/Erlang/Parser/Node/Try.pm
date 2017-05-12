# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Try;

use Moose;
with 'Erlang::Parser::Node';

has 'exprs' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');
has 'of'    => (is => 'rw', required => 0, isa => 'Maybe[ArrayRef[Erlang::Parser::Node::Alt]]');
has 'catch' => (is => 'rw', required => 0, isa => 'Maybe[ArrayRef[Erlang::Parser::Node::Alt]]');
has 'aft'   => (is => 'rw', required => 0, isa => 'Maybe[ArrayRef[Erlang::Parser::Node]]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh "try\n";

	$depth++;
	print $fh "\t" x $depth;

	my $first = 1;
	foreach (@{$self->exprs}) {
		if ($first) { $first = 0 } else { print $fh ",\n", "\t" x $depth }
		$_->print($fh, $depth);
	}

	$depth--;
	print $fh "\n", "\t" x $depth;

	if (defined $self->of and @{$self->of}) {
		print $fh "of\n";

		$depth++;
		print $fh "\t" x $depth;

		my $first = 1;
		foreach (@{$self->of}) {
			if ($first) { $first = 0 } else { print $fh ";\n", "\t" x $depth }
			$_->print($fh, $depth);
		}

		$depth--;
		print $fh "\n", "\t" x $depth;
	}

	if (defined $self->catch and @{$self->catch}) {
		print $fh "catch\n";

		$depth++;
		print $fh "\t" x $depth;

		my $first = 1;
		foreach (@{$self->catch}) {
			if ($first) { $first = 0 } else { print $fh ";\n", "\t" x $depth }
			$_->print($fh, $depth);
		}

		$depth--;
		print $fh "\n", "\t" x $depth;
	}

	if (defined $self->aft and @{$self->aft}) {
		print $fh "after\n";

		$depth++;
		print $fh "\t" x $depth;

		my $first = 1;
		foreach (@{$self->aft}) {
			if ($first) { $first = 0 } else { print $fh ";\n", "\t" x $depth }
			$_->print($fh, $depth);
		}

		$depth--;
		print $fh "\n", "\t" x $depth;
	}

	print $fh "end";
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Try - a try/catch clause

=head1 DESCRIPTION

A clause to catch exceptions. A block of expressions is evaluated; the last
expression's value is optionally then matched against patterns and guards, and
then a further block of statements executed. Exceptions raised therein can be
caught in the catch clause. Finally, cleanup statements can be invoked.

=head2 Accessors

=over 4

=item C<exprs>

A list of L<Erlang::Parser::Node>s; the last expression's value is that used in
the of clause.

=item C<of>

An optional list of L<Erlang::Parser::Node::Alt>s against which the last
expression in C<exprs> is matched.

=item C<catch>

An optional list of L<Erlang::Parser::Node::Alt>s for exceptions raised during
evaluation in C<exprs> and C<of>.

=item C<aft>

An optional list of L<Erlang::Parser::Node>s, executed after all previous
statements.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	try
		{ok, X} = my_fun(),
		binary_to_term(X)
	catch
		throw:Term -> Term
	after
		file:close(F)
	end

=cut

1;

# vim: set sw=4 ts=4:
