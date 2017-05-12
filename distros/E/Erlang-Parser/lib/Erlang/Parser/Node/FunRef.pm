# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::FunRef;

use Moose;
with 'Erlang::Parser::Node';

has 'module'   => (is => 'rw', required => 0, isa => 'Maybe[Erlang::Parser::Node]');
has 'function' => (is => 'rw', required => 1, isa => 'Str');
has 'arity'    => (is => 'rw', required => 1, isa => 'Int');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh 'fun ';

	if (defined $self->module) {
		$self->module->print($fh, $depth);
		print $fh ':';
	}

	print $fh $self->function, '/', $self->arity;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::FunRef - a reference to a function

=head1 DESCRIPTION

A reference to a function (as a first-class value), either local to this
module, or external.

=head2 Accessors

=over 4

=item C<module>

An optional L<Erlang::Parser::Node> which returns as an atom the name of the
module to find the function in.

=item C<function>

The name of the function (a plain string).

=item C<arity>

The arity of the function (a number).

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	fun ?MODULE:code_change/0

=cut

1;

# vim: set sw=4 ts=4:
