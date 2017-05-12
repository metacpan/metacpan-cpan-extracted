# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::ReceiveAfter;

use Moose;
with 'Erlang::Parser::Node';

has 'time'  => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node');
has 'stmts' => (is => 'rw', required => 0, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh 'after ';
	$self->time->print($fh, $depth);

	$depth++;
	print $fh " ->\n", "\t" x $depth;

	my $first = 1;
	foreach (@{$self->stmts}) {
		if ($first) { $first = 0 } else { print $fh ",\n", "\t" x $depth }
		$_->print($fh, $depth);
	}

	$depth--;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::ReceiveAfter - the after clause for a receive statement

=head1 DESCRIPTION

Specifies the length of time after which the clause should activate, and the
statement block to execute in that case.

=head2 Accessors

=over 4

=item C<time>

A L<Erlang::Parser::Node> that yields the number of milliseconds, or the atom
infinity.

=item C<stmts>

A list of L<Erlang::Parser::Node>s to run if the timeout is activated.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	after X ->
		Y

=cut

1;

# vim: set sw=4 ts=4:
