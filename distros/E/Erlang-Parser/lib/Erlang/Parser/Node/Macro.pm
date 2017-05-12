# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Macro;

use Moose;
with 'Erlang::Parser::Node';

has 'macro' => (is => 'rw', required => 1, isa => 'Str');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh '?', $self->macro;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Macro - a preprocessor-style macro

=head1 DESCRIPTION

Defined with the -define() directive; expands as any node.

=head2 Accessors

=over 4

=item C<macro>

The name of the macro being invoked.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	?MODULE

=cut

1;

# vim: set sw=4 ts=4:
