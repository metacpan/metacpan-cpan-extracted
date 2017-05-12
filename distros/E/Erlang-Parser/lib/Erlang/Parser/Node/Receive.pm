# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::Receive;

use Moose;
with 'Erlang::Parser::Node';

has 'alts' => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node::Alt]');
has 'aft'  => (is => 'rw', required => 0, isa => 'Maybe[Erlang::Parser::Node::ReceiveAfter]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh "receive\n";

	$depth++;

	print $fh "\t" x $depth;

	my $first = 1;
	foreach (@{$self->alts}) {
		if ($first) { $first = 0 } else { print $fh ";\n", "\t" x $depth }
		$_->print($fh ,$depth);
	}

	$depth--;
	print $fh "\n", "\t" x $depth;
	
	$self->aft->print($fh, $depth) if defined $self->aft;
	
	print $fh "\n", "\t" x $depth, "end";
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::Receive - a receive statement

=head1 DESCRIPTION

Receives a message from the mailbox which matches any pattern (and guard);
optionally with a timeout.

=head2 Accessors

=over 4

=item C<alts>

A list of L<Erlang::Parser::Node::Alt>s which are matched against the process
mailbox.

=item C<aft>

An optional L<Erlang::Parser::Node::ReceiveAfter>.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	receive
		{X, Y} when is_bool(X) ->
			X;
		{X, Y, Z} ->
			Y + Z;
		_ ->
			io:format("wth~n", [])
	after
		10000 ->
			{error, timeout}
	end

=cut

1;

# vim: set sw=4 ts=4:
