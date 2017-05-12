use utf8;

package Interchange6::Schema::Result::ShipmentMethod;

=head1 NAME

Interchange6::Schema::Result::ShipmentMethod

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 ACCESSORS

=head2 shipment_methods_id

Primary key.

=cut

primary_column shipment_methods_id =>
  { data_type => "integer", is_auto_increment => 1 };

=head2 name

Name. e.g.: priority.

Defaults to empty string.

=cut

column name => {
    data_type     => "varchar",
    default_value => "",
    size          => 255
};

=head2 title

Full title of shipment method, e.g.: Priority 3-5 busines days.

Defaults to empty string.

=cut

column title => {
    data_type     => "varchar",
    default_value => "",
    size          => 255
};

=head2 shipment_carriers_id

FK on L<Interchange6::Schema::Result::ShipmentCarrier/shipment_carriers_id>.

=cut

column shipment_carriers_id =>
  { data_type => "integer" };

=head2 active

Whether this shipment method is active. Defaults to 1 (true).

=cut

column active =>
  { data_type => "boolean", default_value => 1 };

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => {
    data_type     => "datetime",
    set_on_create => 1
};

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified => {
    data_type     => "datetime",
    set_on_create => 1,
    set_on_update => 1
};

=head1 RELATIONS

=head2 shipment_carrier

Type: belongs_to

Related object: L<Interchange6::Schema::Result::ShipmentCarrier>

=cut

belongs_to
  shipment_carrier => "Interchange6::Schema::Result::ShipmentCarrier",
  "shipment_carriers_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 shipment_rates

Type: has_many

Related object: L<Interchange6::Schema::Result::ShipmentRate>

=cut

has_many
  shipment_rates => "Interchange6::Schema::Result::ShipmentRate",
  "shipment_methods_id",
  { cascade_copy => 0, cascade_delete => 0 };

1;
