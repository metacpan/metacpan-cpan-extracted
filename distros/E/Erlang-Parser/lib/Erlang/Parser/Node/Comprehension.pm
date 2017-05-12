# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Comprehension;

use Moose;
with 'Erlang::Parser::Node';

has 'binary'     => (is => 'rw', default => 0,  isa => 'Bool');
has 'output'     => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node');
has 'generators' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh $self->binary ? '<<' : '[';
	$self->output->print($fh, $depth);
	print $fh ' || ';
	
	my $first = 1;
	foreach (@{$self->generators}) {
		if ($first) { $first = 0 } else { print $fh ', ' }
		$_->print($fh, $depth);
	}
	print $fh $self->binary ? '>>' : ']';
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Comprehension - a list or binary comprehension

=head1 DESCRIPTION

Used to generate (binary) lists/strings by a combination of generators, guards
and output expressions.

=head2 Accessors

=over 4

=item C<binary>

True if this is a binary comprehension.

=item C<output>

The L<Erlang::Parser::Node> which forms the output elements based on
C<generators>.

=item C<generators>

A mixture of generators (in the form C<<X <- Y>> or C<<X <= Y>>) and guards
which create the terms used by C<output>.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	[X + Y || X <- [1, 2, 3], Y <- [1, 2, 3], X + Y > 2]

=cut

1;

# vim: set sw=4 ts=4:
