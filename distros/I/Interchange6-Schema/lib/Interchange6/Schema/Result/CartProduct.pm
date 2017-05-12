use utf8;

package Interchange6::Schema::Result::CartProduct;

=head1 NAME

Interchange6::Schema::Result::CartProduct

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 DESCRIPTION

Holds products for related L<Interchange6::Schema::Result::Cart> class and
links to the full product details held in L<Interchange6::Schema::Result::Product>.

=head1 ACCESSORS

=head2 cart_products_id

Primary key.

=cut

primary_column cart_products_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "cart_product_cart_products_id_seq",
};

=head2 carts_id

Foreign key constraint on L<Interchange6::Schema::Result::Cart/carts_id>
via L</cart> relationship.

=cut

column carts_id => {
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

=head2 cart_position

Integer cart position.

=cut

column cart_position => {
    data_type   => "integer",
};

=head2 quantity

The integer quantity of product in the cart. Defaults to 1.

=cut

column quantity => {
    data_type     => "integer",
    default_value => 1,
};

=head2 combine

Indicate whether products with the same SKU should be combined in the Cart

Defaults to true.

=cut

column combine => {
    data_type     => "boolean",
    default_value => 1,
};

=head2 extra

Any extra info associated with this cart product. This could be used to store
special instructions for product like personalisation.

Is nullable.

=cut

column extra => {
    data_type   => "text",
    is_nullable => 1,
};

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => {
    data_type     => "datetime",
    set_on_create => 1,
};

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update

=cut

column last_modified => {
    data_type     => "datetime",
    set_on_create => 1,
    set_on_update => 1,
};

=head1 RELATIONS

=head2 cart

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Cart>

=cut

belongs_to
  cart => "Interchange6::Schema::Result::Cart",
  { carts_id      => "carts_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 product

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Product>

=cut

belongs_to
  product => "Interchange6::Schema::Result::Product",
  { sku           => "sku" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

1;
