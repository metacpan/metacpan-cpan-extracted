use utf8;

package Interchange6::Schema::Result::OrderStatus;

=head1 NAME

Interchange6::Schema::Result::OrderStatus

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 ACCESSORS

=head2 order_status_id

Primary key.

=cut

primary_column order_status_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "order_status_id_seq",
};

=head2 orders_id

FK on L<Interchange6::Schema::Result::Order/orders_id>.

=cut

column orders_id => { data_type => "integer" };

=head2 status

Status of the order, e.g.: picking, complete, shipped, cancelled

=cut

column status => { data_type => "varchar", size => 32 };

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => { data_type => "datetime", set_on_create => 1 };

=head1 RELATIONS

=head2 order

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Order>

=cut

belongs_to order => "Interchange6::Schema::Result::Order", "orders_id";

1;
