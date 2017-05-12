# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::List;

use Moose;
with 'Erlang::Parser::Node';

has 'elems' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');
has 'cdr'   => (is => 'rw', required => 1, isa => 'Maybe[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh '[';
	my $first = 1;
	foreach (@{$self->elems}) {
		if ($first) { $first = 0 } else { print $fh ', ' }
		$_->print($fh, $depth);
	}

	if (defined $self->cdr) {
		print $fh '|';
		$self->cdr->print($fh, $depth);
	}

	print $fh ']';
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::List - a list of values

=head1 DESCRIPTION

A lisp-style cdr list.

=head2 Accessors

=over 4

=item C<elems>

A list of L<Erlang::Parser::Node>s which comprise the list.

=item C<cdr>

An optional L<Erlang::Parser::Node> which forms the tail of the list. This
should be another list (usually).

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	[7, 8, 9|[]]

=cut

1;

# vim: set sw=4 ts=4:
