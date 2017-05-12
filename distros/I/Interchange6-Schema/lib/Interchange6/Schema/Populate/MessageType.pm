package Interchange6::Schema::Populate::MessageType;

=head1 NAME

Interchange6::Schema::Populate::MessageType

=head1 DESCRIPTION

This module provides population capabilities for the MessageType schema

=cut

use Moo::Role;

=head1 METHODS

=head2 populate_message_types

=cut

sub populate_message_types {
    my $self = shift;

    my @types = qw( blog_post order_comment product_review wiki_node );

    my $rset = $self->schema->resultset('MessageType');

    map { $rset->create({ name => $_ }) } @types;
}

1;
