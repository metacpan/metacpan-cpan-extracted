use utf8;

package Interchange6::Schema::Result::ZoneState;

=head1 NAME

Interchange6::Schema::Result::ZoneState

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 zones_id

FK on L<Interchange6::Schema::Result::Zone/zones_id>,

=cut

column zones_id =>
  { data_type => "integer" };

=head2 states_id

FK on L<Interchange6::Schema::Result::Zone/states_id>,

=cut

column states_id =>
  { data_type => "integer" };

=head1 PRIMARY KEY

=over 4

=item * L</zones_id>

=item * L</states_id>

=back

=cut

primary_key "zones_id", "states_id";

=head1 RELATIONS

=head2 zone

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Zone>

=cut

belongs_to
  zone => "Interchange6::Schema::Result::Zone",
  "zones_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 state

Type: belongs_to

Related object: L<Interchange6::Schema::Result::State>

=cut

belongs_to
  state => "Interchange6::Schema::Result::State",
  "states_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

1;
