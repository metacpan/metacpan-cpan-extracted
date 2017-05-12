use utf8;

package Interchange6::Schema::Result::Country;

=head1 NAME

Interchange6::Schema::Result::Country

=cut

use Interchange6::Schema::Candy;

=head1 DESCRIPTION

ISO 3166-1 codes for country identification

=cut

=head1 ACCESSORS

=head2 country_iso_code

Primary key.

Two letter country code such as 'SI' = Slovenia.

=cut

primary_column country_iso_code => { data_type => "char", size => 2 };

=head2 scope

Internal sorting field.

=cut

column scope => { data_type => "varchar", default_value => "", size => 32 };

=head2 name

Full country name.

=cut

column name => { data_type => "varchar", size => 255 };

=head2 priority

Display order.

=cut

column priority => { data_type => "integer", default_value => 0 };

=head2 show_states

Whether this country has related L<Interchange6::Schema::Result::State> via
relationship L</states>. Default is false. This is used so that we don't
have to bother running a query across the states relation every time we
want to check if the country has states (or provinces, etc. ).

=cut

column show_states => { data_type => "boolean", default_value => 0 };

=head2 active

Active shipping destination?  Default is true.

=cut

column active => { data_type => "boolean", default_value => 1 };

=head1 RELATIONSHIPS

=head2 zone_countries

C<has_many> relationship with L<Interchange6::Schema::Result::ZoneCountry>

=cut

has_many
  zone_countries => "Interchange6::Schema::Result::ZoneCountry",
  { "foreign.country_iso_code" => "self.country_iso_code" };

=head2 zones

C<many_to_many> relationship with L<Interchange6::Schema::Result::Zone>

=cut

many_to_many zones => "zone_countries", "zone";

=head2 states

C<has_many> relationship with L<Interchange6::Schema::Result::State>

=cut

has_many
  states => "Interchange6::Schema::Result::State",
  'country_iso_code';

1;
