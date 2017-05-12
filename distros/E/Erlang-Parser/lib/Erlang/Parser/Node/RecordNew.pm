# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::RecordNew;

use Moose;
with 'Erlang::Parser::Node';

has 'record' => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node::Atom');
has 'exprs'  => (is => 'rw', required => 1, isa => 'ArrayRef[Erlang::Parser::Node]');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	print $fh '#';
	$self->record->print($fh, $depth);
	print $fh '{';

	my $first = 1;
	foreach (@{$self->exprs}) {
		if ($first) { $first = 0 } else { print $fh ', ' }
		$_->print($fh, $depth);
	}

	print $fh '}';
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::RecordNew - creation of a new record

=head1 DESCRIPTION

Creation of a record based on a record definition.

=head2 Accessors

=over 4

=item C<record>

The name of the record definition being used.

=item C<exprs>

A list of L<Erlang::Parser::Node>s which instantiate fields in the record.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	#state{S=4}

=cut

1;

# vim: set sw=4 ts=4:
