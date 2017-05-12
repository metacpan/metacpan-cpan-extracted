# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Atom;

use Moose;
with 'Erlang::Parser::Node';

has 'atom' => (is => 'rw', required => 1, isa => 'Str');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	if (not $self->atom =~ /^[^a-z]|[^a-zA-Z_0-9]/
		and not $self->atom =~ /^(case|receive|after|of|end|fun|when|div|bs[lr]|bx?or|band|rem|try|catch|andalso|and|orelse|or|begin|not|if)$/) {
		print $fh $self->atom;
	} else {
		my $atom = $self->atom;
		$atom =~ s/\\/\\\\/g;
		$atom =~ s/'/\\'/g;

		print $fh "'$atom'";
	}
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Atom - a plain atom

=head1 DESCRIPTION

The basic symbol unit in Erlang.

=head2 Accessors

=over 4

=item C<atom>

The string representation of the atom>

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	my.atom@is.long.

=cut

1;

# vim: set sw=4 ts=4:
