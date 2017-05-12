use utf8;

package Interchange6::Schema::Result::ProductMessage;

=head1 NAME

Interchange6::Schema::Result::ProductMessage

=cut

use Interchange6::Schema::Candy;

=head1 DESCRIPTION

Link table between Product and Message for product reviews, etc.

=cut

=head1 ACCESSORS

=head2 messages_id

Foreign key constraint on L<Interchange6::Schema::Result::Message/messages_id>
via L</message> relationship.

=cut

column messages_id => {
    data_type      => "integer",
};

=head2 sku

Foreign key constraint on L<Interchange6::Schema::Result::Product/sku>
via L</product> relationship.

=cut

column sku => {
    data_type      => "varchar",
    size           => 64,
};

=head1 PRIMARY KEY

=over 4

=item * L</messages_id>

=item * L</sku>

=back

=cut

primary_key "messages_id", "sku";

=head1 RELATIONS

=head2 message

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Message>

=cut

belongs_to
  message => "Interchange6::Schema::Result::Message",
  "messages_id",
  { cascade_delete => 1 };

=head2 product

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Product>

=cut

belongs_to product => "Interchange6::Schema::Result::Product", "sku";

1;
