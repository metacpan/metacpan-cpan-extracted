# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::BinaryExpr;

use Moose;
with 'Erlang::Parser::Node';

has 'output'    => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node');
has 'size'      => (is => 'rw', required => 0, isa => 'Maybe[Erlang::Parser::Node]');
has 'qualifier' => (is => 'rw', required => 0, isa => 'Maybe[Str]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh '(';
	$self->output->print($fh, $depth);
	print $fh ')';
	if (defined $self->size) {
		print $fh ':';
		$self->size->print($fh, $depth);
	}
	print $fh '/', $self->qualifier if defined $self->qualifier;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::BinaryExpr - a term within a binary term

=head1 DESCRIPTION

Any expression that can be part of the body of a binary list or string.

=head2 Accessors

=over 4

=item C<output>

The L<Erlang::Parser::Node> which provides the output for this term.

=item C<size>

A L<Erlang::Parser::Node> which specifies the length (in bits) of this term,
or C<undef>.

=item C<qualifier>

Qualifiers that specify how this term is to be output in string form, or
C<undef>.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	X:8/integer-signed-big

=cut

1;

# vim: set sw=4 ts=4:
