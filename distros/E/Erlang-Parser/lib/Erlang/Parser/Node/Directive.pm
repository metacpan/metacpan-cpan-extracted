# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Directive;

use Moose;
with 'Erlang::Parser::Node';

has 'directive' => (is => 'rw', required => 1, isa => 'Str');
has 'args'      => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh "-", $self->directive, "(";
	my $first = 1;

	foreach (@{$self->args}) {
		if ($first) { $first = 0 } else { print $fh ', ' }
		$_->print($fh, $depth);
	}
	print $fh ").\n";
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Directive - a compiler directive

=head1 DESCRIPTION

Any pragma to the compiler.

=head2 Accessors

=over 4

=item C<directive>

The name of the pragma.

=item C<args>

A list of L<Erlang::Parser::Node>s which make up the arguments of the
directive, if any.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	-export([a/0]).

=cut

1;

# vim: set sw=4 ts=4:
