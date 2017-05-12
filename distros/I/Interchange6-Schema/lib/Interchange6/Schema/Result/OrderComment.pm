use utf8;

package Interchange6::Schema::Result::OrderComment;

=head1 NAME

Interchange6::Schema::Result::OrderComment

=cut

use Interchange6::Schema::Candy;

=head1 DESCRIPTION

Link table between Order and Message for order comments.

=cut

=head1 ACCESSORS

=head2 messages_id

Foreign key constraint on L<Interchange6::Schema::Result::Message/messages_id>
via L</message> relationship.

=cut

column messages_id => {
    data_type      => "integer",
};

=head2 orders_id

Foreign key constraint on L<Interchange6::Schema::Result::Order/orders_id>
via L</order> relationship.

=cut

column orders_id => {
    data_type      => "integer",
};

=head1 PRIMARY KEY

=over 4

=item * L</messages_id>

=item * L</orders_id>

=back

=cut

primary_key "messages_id", "orders_id";

=head1 RELATIONS

=head2 message

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Message>

=cut

belongs_to
  message => "Interchange6::Schema::Result::Message",
  "messages_id",
  { cascade_delete => 1 };

=head2 order

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Order>

=cut

belongs_to
  order => "Interchange6::Schema::Result::Order",
  "orders_id";

1;
