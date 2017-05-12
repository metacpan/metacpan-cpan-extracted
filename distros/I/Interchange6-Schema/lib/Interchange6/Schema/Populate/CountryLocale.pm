package Interchange6::Schema::Populate::CountryLocale;

=head1 NAME

Interchange6::Schema::Populate::CountryLocale

=head1 DESCRIPTION

This module provides population capabilities for the Country schema

=cut

use Moo::Role;
use Locale::SubCountry;
use namespace::clean;

=head1 METHODS

=head2 populate_countries

=cut

sub populate_countries {
    my $self = shift;
    my $has_state;
    my @countries_with_states = qw(US CA); # United States, Canada
    my $world = Locale::SubCountry::World->new;;
    my %all_country_keyed_by_code = $world->code_full_name_hash;

    my $rset = $self->schema->resultset('Country');

    foreach my $country_code ( sort keys %all_country_keyed_by_code ){
        #need regex to clean up records containing 'See (*)'
        my $country_name = $all_country_keyed_by_code{$country_code};
        if ( grep( /^$country_code$/, @countries_with_states ) ) {
            $has_state = '1';
        } else {
            $has_state = '0';
        }
        $rset->create(
            {
                'country_iso_code' => $country_code,
                'name'             => $country_name,
                'show_states'      => $has_state
            }
        );
    }
}

1;
