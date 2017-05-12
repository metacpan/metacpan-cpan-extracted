use utf8;

package Interchange6::Schema::Result::Orderline;

=head1 NAME

Interchange6::Schema::Result::Orderline

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 orderlines_id

Primary key.

=cut

primary_column orderlines_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "orderlines_orderlines_id_seq",
};

=head2 orders_id

FK on L<Interchange6::Schema::Result::Order/orders_id>.

=cut

column orders_id =>
  { data_type => "integer" };

=head2 order_position

Signed integer order position. Defaults to 0.

=cut

column order_position =>
  { data_type => "integer", default_value => 0 };

=head2 sku

FK on L<Interchange6::Schema::Result::Product/sku>.

=cut

column sku =>
  { data_type => "varchar", size => 64 };

=head2 name

Product name.

=cut

column name => {
    data_type     => "varchar",
    size          => 255
};

=head2 short_description

Product short description.

Defaults to empty string.

=cut

column short_description => {
    data_type     => "varchar",
    default_value => "",
    size          => 500
};

=head2 description

Product descrtption.

=cut

column description => { data_type => "text" };

=head2 weight

Weight of product. Defaults to 0.

=cut

column weight => {
    data_type     => "numeric",
    default_value => 0,
    size          => [ 10, 3 ]
};

=head2 quantity

Product quantity.

=cut

column quantity => { data_type => "integer" };

=head2 price

Product price.

=cut

column price => {
    data_type     => "numeric",
    size          => [ 21, 3 ],
};

=head2 subtotal

Line subtotal.

=cut

column subtotal => {
    data_type     => "numeric",
    size          => [ 21, 3 ],
};

=head2 shipping

Shipping cost.

Defaults to 0.

=cut

column shipping => {
    data_type     => "numeric",
    default_value => 0,
    size          => [ 21, 3 ],
};

=head2 handling

Handling cost.

Defaults to 0.

=cut

column handling => {
    data_type     => "numeric",
    default_value => 0,
    size          => [ 21, 3 ],
};

=head2 salestax

Sales tax.

Defaults to 0.

=cut

column salestax => {
    data_type     => "numeric",
    default_value => 0,
    size          => [ 21, 3 ],
};

=head2 status

Status, e.g.: picking, shipped, cancelled.

Defaults to empty string.

=cut

column status =>
  { data_type => "varchar", default_value => "", size => 24 };

=head1 RELATIONS

=head2 order

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Order>

=cut

belongs_to
  order => "Interchange6::Schema::Result::Order",
  "orders_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 orderlines_shipping

Type: has_many

Related object: L<Interchange6::Schema::Result::OrderlinesShipping>

=cut

has_many
  orderlines_shipping => "Interchange6::Schema::Result::OrderlinesShipping",
  "orderlines_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 product

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Product>

=cut

belongs_to
  product => "Interchange6::Schema::Result::Product",
  "sku",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 addresses

Type: many_to_many

Composing rels: L</orderlines_shipping> -> address

=cut

many_to_many addresses => "orderlines_shipping", "address";

1;
