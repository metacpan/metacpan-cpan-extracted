use utf8;

package Interchange6::Schema::Result::ShipmentRate;

=head1 NAME

Interchange6::Schema::Result::ShipmentRate

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 DESCRIPTION

In the context of shipment the rate is the value give for a shipping method based on
desination zone_id and weight.

=over 4

=item * Flat rate shipping

If min_weight and max_weight are set to 0 for a shipping method and zone flate rate will be
assumed.  If min_weight is set and max_weight is 0 max weight is assumed as infinite.

=back

=head1 ACCESSORS

=head2 shipment_rates_id

Primary key.

=cut

primary_column shipment_rates_id =>
  { data_type => "integer", is_auto_increment => 1 };

=head2 zones_id 

FK on L<Interchange6::Schema::Result::Zone/zones_id>

=cut

column zones_id =>
  { data_type => "integer" };

=head2 shipment_methods_id

FK on L<Interchange6::Schema::Result::ShipmentMethod/shipment_methods_id>

=cut

column shipment_methods_id =>
  { data_type => "integer" };

=head2 value_type

Type of value stored in </min_value> and </max_value>, e.g.: weight, volume

Is nullable.

=cut

column value_type => {
    data_type   => "varchar",
    size        => 64,
    is_nullable => 1,
};

=head2 value_unit

Unit of measurement for L</value_type>, e.g.: kg, meter, cubic meter, lb, oz

Is nullable.

=cut

column value_unit => {
    data_type   => "varchar",
    size        => 64,
    is_nullable => 1,
};

=head2 min_value

Minimum value of L</value_type>.

=cut

column min_value => {
    data_type     => "numeric",
    default_value => 0,
    size          => [ 10, 2 ]
};

=head2 max_value

Maximum value of L</value_type>.

=cut

column max_value => {
    data_type     => "numeric",
    default_value => 0,
    size          => [ 10, 2 ]
};

=head2 price

Price.

=cut

column price => {
    data_type     => "numeric",
    default_value => 0,
    size          => [ 21, 3 ],
};

=head2 valid_from

Date from which rate is valid. Defaults to time record is created.

=cut

column valid_from => { data_type => "date", set_on_create => 1 };

=head2 valid_to

Final date on which rate is valid.

Is nullable.

=cut

column valid_to => { data_type => "date", is_nullable => 1 };

=head2 created


Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created =>
  { data_type => "datetime", set_on_create => 1 };

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified => {
    data_type     => "datetime",
    set_on_create => 1,
    set_on_update => 1,
};

=head1 RELATIONS

=head2 zone

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Zone>

=cut

belongs_to
  zone => "Interchange6::Schema::Result::Zone",
  "zones_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 shipment_method

Type: belongs_to

Related object: L<Interchange6::Schema::Result::ShipmentMethod>

=cut

belongs_to
  shipment_method => "Interchange6::Schema::Result::ShipmentMethod",
  "shipment_methods_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

1;
