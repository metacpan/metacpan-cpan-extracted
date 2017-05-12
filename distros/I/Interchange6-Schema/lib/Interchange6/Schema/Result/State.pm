use utf8;

package Interchange6::Schema::Result::State;

=head1 NAME

Interchange6::Schema::Result::State

=cut

use Interchange6::Schema::Candy;

=head1 DESCRIPTION

ISO 3166-2 codes for sub_country identification "states"

=head1 ACCESSORS

=head2 states_id

Primary key.

=cut

primary_column states_id =>
  { data_type => "integer", is_auto_increment => 1 };

=head2 scope

Scope. Defaults to empty string.

=cut

column scope =>
  { data_type => "varchar", default_value => "", size => 32 };

=head2 country_iso_code

FK on L<Interchange6::Schema::Result::Country/country_iso_code>.

=cut

column country_iso_code =>
  { data_type => "char", size => 2 };

=head2 state_iso_code

State ISO code, e.g.: NY.

=cut

column state_iso_code =>
  { data_type => "varchar", default_value => "", size => 6 };

=head2 name

Full name of state/province, e.g.: New York.

Defaults to empty string.

=cut

column name => {
    data_type     => "varchar",
    default_value => "",
    size          => 255
};

=head2 priority

Display sort order. Defaults to 0.

=cut

column priority =>
  { data_type => "integer", default_value => 0 };

=head2 active

Whether state is an active shipping destination. Defaults to 1 (true).

=cut

column active =>
  { data_type => "boolean", default_value => 1 };

=head1 UNIQUE CONSTRAINT

=head2 states_state_country

=over 4

=item * L</country_iso_code>

=item * L</state_iso_code>

=back

=cut

unique_constraint states_state_country => [qw/country_iso_code state_iso_code/];

=head1 RELATIONS

=head2 country

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Country>

=cut

belongs_to
  country => "Interchange6::Schema::Result::Country",
  "country_iso_code",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 zone_states

Type: has_many

Related object L<Interchange6::Schema::Result::ZoneState>

=cut

has_many
  zone_states => "Interchange6::Schema::Result::ZoneState",
  "states_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 zones

Type: many_to_many

Composing rels: L</zone_states> -> zone

=cut

many_to_many zones => "zone_states", "zone";

1;
