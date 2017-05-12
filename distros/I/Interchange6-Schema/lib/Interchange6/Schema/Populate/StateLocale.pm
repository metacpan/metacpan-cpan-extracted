package Interchange6::Schema::Populate::StateLocale;

=head1 NAME

Interchange6::Schema::Populate::StateLocale

=head1 DESCRIPTION

This role provides population capabilities for the State class

=cut

use Moo::Role;
use Locale::SubCountry;

=head1 METHODS

=head2 populate_states

Returns array reference containing one hash reference per state,
ready to use with populate schema method.

=cut

sub populate_states {
    my $self = shift;

    my $countries =
      $self->schema->resultset('Country')->search( { -bool => 'show_states' } );

    while ( my $country_result = $countries->next ) {

        my $country =
          Locale::SubCountry->new( $country_result->country_iso_code );

        # should never happen so let Devel::Cover watch it for us
        # uncoverable branch true
        next unless $country->has_sub_countries;

        my %country_states_keyed_by_code = $country->code_full_name_hash;

        foreach my $state_code ( sort keys %country_states_keyed_by_code ) {

            # some US 'states' are not actually states of the US
            next
              if ( $country_result->country_iso_code eq 'US'
                && $state_code =~ /(AS|GU|MP|PR|UM|VI)/ );

            my $state_name = $country_states_keyed_by_code{$state_code};

            # remove (Junk) from some records
            $state_name =~ s/\s*\([^)]*\)//g;

            $country_result->create_related(
                'states',
                {
                    'name'           => $state_name,
                    'state_iso_code' => $state_code,
                }
            );
        }
    }
}

1;
