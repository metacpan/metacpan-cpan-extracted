# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Call;

use Moose;
with 'Erlang::Parser::Node';

has 'module'   => (is => 'rw', required => 0, isa => 'Erlang::Parser::Node');
has 'function' => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node');
has 'args'     => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	if (defined $self->module) {
		$self->module->print($fh, $depth);
		print $fh ':';
	}

	print $fh '(' if $self->function->blessed ne 'Erlang::Parser::Node::Atom';
	$self->function->print($fh, $depth);
	print $fh ')' if $self->function->blessed ne 'Erlang::Parser::Node::Atom';
	print $fh '(';
	my $first = 1;
	foreach (@{$self->args}) {
		if ($first) { $first = 0 } else { print $fh ', ' }
		$_->print($fh, $depth);
	}
	print $fh ')';
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Call - a function call

=head1 DESCRIPTION

A call to a function, either local or external.

=head2 Accessors

=over 4

=item C<module>

A L<Erlang::Parser::Node> which returns the name of the module to use as an
atom; or C<undef>.

=item C<function>

A L<Erlang::Parser::Node> which either returns an atom which corresponds to a
local function or a function in C<module> if specified; or which returns a
calculated fun or fun reference itself.

=item C<args>

A list of L<Erlang::Parser::Node>s which are passed as arguments to the
function.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	lists:reverse([1, 2, 3])

=cut

1;

# vim: set sw=4 ts=4:
