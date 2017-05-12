# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::FunLocal;

use Moose;
with 'Erlang::Parser::Node';

has 'cases' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node::FunLocalCase]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh 'fun ';

	my $first = 1;
	foreach (@{$self->cases}) {
		if ($first) { $first = 0 } else { print $fh '; ' }

		$_->print($fh, $depth);
	}

	print $fh ' end';
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::FunLocal - a lambda-style local fun

=head1 DESCRIPTION

A lambda-ish local fun definition, comprised of multiple cases; see
L<Erlang::Parser::Node::DefList>.

=head2 Accessors

=over 4

=item C<cases>

A list of L<Erlang::Parser::Node::FunLocalCase>s.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	fun (0) -> 1; (N) -> N + 1 end	 % wtf does this do

=cut

1;

# vim: set sw=4 ts=4:
