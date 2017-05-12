# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::VariableRecordUpdate;

use Moose;
with 'Erlang::Parser::Node';

has 'variable' => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node::Variable');
has 'update'   => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node::RecordNew');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	$self->variable->print($fh, $depth);
	$self->update->print($fh, $depth);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::VariableRecordUpdate - variable record update

=head1 DESCRIPTION

An update of a variable record's component.

=head2 Accessors

=over 4

=item C<variable>

The L<Erlang::Parser::Node::Variable> which is being updated.

=item C<record>

An L<Erlang::Parser::Node::RecordNew> which updates parts of the record.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	MyVar#state{part=42}

=cut

1;

# vim: set sw=4 ts=4:
