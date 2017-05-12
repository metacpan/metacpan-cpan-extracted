# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Case;

use Moose;
with 'Erlang::Parser::Node';

has 'of'   => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node');
has 'alts' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node::Alt]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh 'case ';
	$self->of->print($fh, $depth);
	print $fh " of\n";

	$depth++;

	print $fh "\t" x $depth;

	my $first = 1;
	foreach (@{$self->alts}) {
		if ($first) { $first = 0 } else { print $fh ";\n", "\t" x $depth }
		$_->print($fh, $depth);
	}

	$depth--;
	print $fh "\n", "\t" x $depth, "end";
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Case - a case expression

=head1 DESCRIPTION

An expression which tries several different pattern matches and guards.

=head2 Accessors

=over 4

=item C<of>

An L<Erlang::Parser::Node> which is evaluated to be matched against C<alts>.

=item C<alts>

A list of L<Erlang::Parser::Node::Alt>s which are tried against C<of> in turn.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	case ?MODULE:myfun() of
	{X, Y} ->
		io:format("I'm a tuple! ~p, ~p~n", [X, Y]);
	[X, Y] = Z ->
		io:format("I'm a list! ~p, ~p~n", Z)
	end

=cut

1;

# vim: set sw=4 ts=4:
