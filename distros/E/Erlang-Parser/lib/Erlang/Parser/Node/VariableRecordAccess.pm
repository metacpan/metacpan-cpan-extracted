# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::VariableRecordAccess;

use Moose;
with 'Erlang::Parser::Node';

has 'variable' => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node::Variable');
has 'record'   => (is => 'rw', required => 1, isa => 'Erlang::Parser::Node::Atom');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	$self->variable->print($fh, $depth);
	print $fh '#';
	$self->record->print($fh, $depth);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::VariableRecordAccess - variable record access

=head1 DESCRIPTION

An access of a variable record's component.

=head2 Accessors

=over 4

=item C<variable>

The L<Erlang::Parser::Node::Variable> which is being accessed.

=item C<record>

An L<Erlang::Parser::Node::Atom> which defines the record and (!) the record
part. (TODO)

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	MyVar#state.part

=cut

1;

# vim: set sw=4 ts=4:
