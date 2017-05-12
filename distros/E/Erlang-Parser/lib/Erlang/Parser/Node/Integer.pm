# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Integer;

use Moose;
with 'Erlang::Parser::Node';

has 'int' => (is => 'rw', required => 1, isa => 'Int');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;
	print $fh $self->int;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Integer - an integer

=head1 DESCRIPTION

A number.

=head2 Accessors

=over 4

=item C<int>

The value.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	42

=cut

1;

# vim: set sw=4 ts=4:
