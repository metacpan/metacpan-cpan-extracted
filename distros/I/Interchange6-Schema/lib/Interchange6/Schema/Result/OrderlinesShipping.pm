use utf8;

package Interchange6::Schema::Result::OrderlinesShipping;

=head1 NAME

Interchange6::Schema::Result::OrderlinesShipping

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 orderlines_id

Foreign key constraint on L<Interchange6::Schema::Result::Orderline/orderlines_id>
via L</orderline> relationship.

=cut

column orderlines_id => { data_type => "integer" };

=head2 addresses_id

Foreign key constraint on L<Interchange6::Schema::Result::Address/addresses_id>
via L</address> relationship.

=cut

column addresses_id => { data_type => "integer" };

=head2 shipments_id

Foreign key constraint on L<Interchange6::Schema::Result::Shipment/shipments_id>
via L</shipment> relationship.

=cut

column shipments_id => { data_type => "integer" };

=head2 quantity

The partial or full quantity shipped for the related
L<Interchange6::Schema::Result::Orderline> in this shipment.

=cut

column quantity => { data_type => "integer" };

=head1 PRIMARY KEY

Each unique combination of L</orderline> and L</address> can have multiple
related L</shipments> in case an L</orderline> needs to be shipped in more
than one consignment.

=over 4

=item * L</orderlines_id>

=item * L</addresses_id>

=item * L</shipments_id>

=back

=cut

primary_key "orderlines_id", "addresses_id", "shipments_id";

=head1 RELATIONS

=head2 address

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Address>

=cut

belongs_to
  address => "Interchange6::Schema::Result::Address",
  "addresses_id";

=head2 orderline

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Orderline>

=cut

belongs_to
  orderline => "Interchange6::Schema::Result::Orderline",
  "orderlines_id";

=head2 shipment

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Shipment>

=cut

belongs_to
  shipment => "Interchange6::Schema::Result::Shipment",
  "shipments_id";

=head1 METHODS

=head2 delete

Rows in this table should not be deleted so we overload
L<DBIx::Class::Row/delete> to throw an exception.

NOTE: if L<DBIx::Class::ResultSet/delete> is called on a result set then this
overloaded method is bypassed. Please consider using
L<DBIx::Class::ResultSet/delete_all> instead. Of course we also cannot prevent
deletes performed outside DBIx::Class control.

=cut

sub delete {
    shift->result_source->schema->throw_exception(
        "OrderlinesShipping rows cannot be deleted");
}

=head2 partial_shipment

If L<Interchange6::Schema::Result::Orderline/quantity> is greater than
L</quantity> then return 1. Otherwise returns 0.

=cut

sub partial_shipment {
    my $self = shift;
    return $self->orderline->quantity > $self->quantity ? 1 : 0;
}

1;
