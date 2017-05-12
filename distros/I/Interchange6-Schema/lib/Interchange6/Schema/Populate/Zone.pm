package Interchange6::Schema::Populate::Zone;

=head1 NAME

Interchange6::Schema::Populate::Zone

=head1 DESCRIPTION

This module provides population capabilities for the Zone schema

=cut

use Moo::Role;

=head1 METHODS

=head2 populate_zones

Returns array reference containing one hash reference per zone ready to use with populate schema method.

=cut

sub populate_zones {
    my $self   = shift;
    my $schema = $self->schema;

    my $countries =
      $schema->resultset('Country')->search( undef, { prefetch => 'states' } );

    my $zones = $schema->resultset('Zone');

    # one zone per country

    while ( my $country = $countries->next ) {

        $zones->create(
            {
                zone => $country->name,
                zone_countries =>
                  [ { country_iso_code => $country->country_iso_code } ],
            }
        );

        # one zone per state

        my $states = $country->states;

        while ( my $state = $states->next ) {

            my $name = $country->name . " - " . $state->name;

            $zones->create(
                {
                    zone => $name,
                    zone_countries =>
                      [ { country_iso_code => $country->country_iso_code } ],
                    zone_states => [ { states_id => $state->id } ],
                }
            );
        }
    }

    # US lower 48 includes all 51 from US except for Alaska and Hawaii

    my @lower48states = $schema->resultset('State')->search(
        {
            'country_iso_code' => 'US',
            'state_iso_code'   => { -not_in => [qw/ AK HI /] }
        },
    )->get_column('states_id')->all;

    $zones->create(
        {
            zone           => 'US lower 48',
            zone_countries => [ { country_iso_code => 'US' } ],
            zone_states    => [ map { { 'states_id' => $_ } } @lower48states ],
        }
    );

    # EU member states

    my @eu_countries = (
        qw ( BE BG CZ DK DE EE GR ES FR HR IE IT CY LV LT LU HU MT
          NL AT PL PT RO SI SK FI SE GB )
    );

    $zones->create(
        {
            zone => 'EU member states',
            zone_countries =>
              [ map { { 'country_iso_code' => $_ } } @eu_countries ],
        }
    );

    # EU VAT countries = EU + Isle of Man

    my @eu_vat_countries = (
        qw ( BE BG CZ DK DE EE GR ES FR HR IE IT CY LV LT LU HU MT
          NL AT PL PT RO SI SK FI SE GB IM )
    );

    $zones->create(
        {
            zone => 'EU VAT countries',
            zone_countries =>
              [ map { { 'country_iso_code' => $_ } } @eu_vat_countries ],
        }
    );
}

1;
