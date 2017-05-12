# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::DefList;

use Moose;
with 'Erlang::Parser::Node';

has 'defs' => (is => 'rw', default => sub {[]}, isa => 'ArrayRef[Erlang::Parser::Node::Def]');

sub _append {
	my ($self, $expr) = @_;
	push @{$self->defs}, $expr;
	$self;
}

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	my $first = 1;
	foreach (@{$self->defs}) {
		if ($first) { $first = 0 } else { print $fh ";\n", "\t" x $depth }
		$_->print($fh, $depth);
	}
	print $fh ".\n";
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::DefList - a list of definitions for one function

=head1 DESCRIPTION

A set of definitions (alternative matches) for one function.

=head2 Accessors

=over 4

=item C<defs>

A list of L<Erlang::Parser::Node::Def>s.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	fac(0) ->
		1;
	fac(N) ->
		N * fac(N - 1)

=cut

1;

# vim: set sw=4 ts=4:
