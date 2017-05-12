# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Literal;

use Moose;
with 'Erlang::Parser::Node';

has 'literal' => (is => 'rw', required => 1, isa => 'Str');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;
	print $fh '$', $self->literal;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Literal - a character literal

=head1 DESCRIPTION

A number based on the ASCII value (Unicode codepoint?) of a character.

=head2 Accessors

=over 4

=item C<literal>

The character (or string) which we take the literal value of.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	$X

=cut

1;

# vim: set sw=4 ts=4:
