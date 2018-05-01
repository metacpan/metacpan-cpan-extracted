package Locale::Country::EU;
$Locale::Country::EU::VERSION = '0.002';
use 5.016003;
use strict;
use warnings;

use Carp;
use Data::Util qw( is_hash_ref is_array_ref);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    is_eu_country
    list_eu_countries
    $ISO_CODES
    $EU_COUNTRY_MAP
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );


# ABSTRACT: Module to check if a country is in the European Union ( EU ) using various ISO data formats

our $EU_COUNTRY_MAP = [
    {
        'ISO-name'   => 'Bulgaria',
        'ISO-m49'    => '100',
        'ISO-alpha3' => 'BGR',
        'ISO-alpha2' => 'BG',
    },
    {
        'ISO-name'   => 'Hungary',
        'ISO-m49'    => '348',
        'ISO-alpha3' => 'HUN',
        'ISO-alpha2' => 'HU',
    },
    {
        'ISO-name'   => 'Poland',
        'ISO-m49'    => '616',
        'ISO-alpha3' => 'POL',
        'ISO-alpha2' => 'PL',
    },
    {
        'ISO-name'   => 'Romania',
        'ISO-m49'    => '642',
        'ISO-alpha3' => 'ROU',
        'ISO-alpha2' => 'RO',
    },
    {
        'ISO-name'   => 'Slovakia',
        'ISO-m49'    => '703',
        'ISO-alpha3' => 'SVK',
        'ISO-alpha2' => 'SK',
    },
    {
        'ISO-name'   => 'Denmark',
        'ISO-m49'    => '208',
        'ISO-alpha3' => 'DNK',
        'ISO-alpha2' => 'DK',
    },
    {
        'ISO-name'   => 'Estonia',
        'ISO-m49'    => '233',
        'ISO-alpha3' => 'EST',
        'ISO-alpha2' => 'EE',
    },
    {
        'ISO-name'   => 'Finland',
        'ISO-m49'    => '246',
        'ISO-alpha3' => 'FIN',
        'ISO-alpha2' => 'FI',
    },
    {
        'ISO-name'    => 'Iceland',
        'ISO-m49'     => '352',
        'ISO-alpha3'  => 'ISL',
        'ISO-alpha2'  => 'IS',
        'EFTA-member' => 'true',
    },
    {
        'ISO-name'   => 'Ireland',
        'ISO-m49'    => '372',
        'ISO-alpha3' => 'IRL',
        'ISO-alpha2' => 'IE',
    },
    {
        'ISO-name'   => 'Lithuania',
        'ISO-m49'    => '440',
        'ISO-alpha3' => 'LTU',
        'ISO-alpha2' => 'LT',
    },
    {
        'ISO-name'    => 'Norway',
        'ISO-m49'     => '578',
        'ISO-alpha3'  => 'NOR',
        'ISO-alpha2'  => 'NO',
        'EFTA-member' => 'true',
    },
    {
        'ISO-name'   => 'Sweden',
        'ISO-m49'    => '752',
        'ISO-alpha3' => 'SWE',
        'ISO-alpha2' => 'SE',
    },
    {
        'ISO-name'   => 'United Kingdom',
        'ISO-m49'    => '826',
        'ISO-alpha3' => 'GBR',
        'ISO-alpha2' => 'GB',
    },
    {
        'ISO-name'   => 'Croatia',
        'ISO-m49'    => '191',
        'ISO-alpha3' => 'HRV',
        'ISO-alpha2' => 'HR',
    },
    {
        'ISO-name'   => 'Greece',
        'ISO-m49'    => '300',
        'ISO-alpha3' => 'GRC',
        'ISO-alpha2' => 'GR',
    },
    {
        'ISO-name'   => 'Italy',
        'ISO-m49'    => '380',
        'ISO-alpha3' => 'ITA',
        'ISO-alpha2' => 'IT',
    },
    {
        'ISO-name'   => 'Malta',
        'ISO-m49'    => '470',
        'ISO-alpha3' => 'MLT',
        'ISO-alpha2' => 'MT',
    },
    {
        'ISO-name'   => 'Portugal',
        'ISO-m49'    => '620',
        'ISO-alpha3' => 'PRT',
        'ISO-alpha2' => 'PT',

    },
    {
        'ISO-name'   => 'Slovenia',
        'ISO-m49'    => '705',
        'ISO-alpha3' => 'SVN',
        'ISO-alpha2' => 'SI',
    },
    {
        'ISO-name'   => 'Spain',
        'ISO-m49'    => '724',
        'ISO-alpha3' => 'ESP',
        'ISO-alpha2' => 'ES',
    },
    {
        'ISO-name'   => 'Austria',
        'ISO-m49'    => '40',
        'ISO-alpha3' => 'AUT',
        'ISO-alpha2' => 'AT',
    },
    {
        'ISO-name'   => 'Belgium',
        'ISO-m49'    => '56',
        'ISO-alpha3' => 'BEL',
        'ISO-alpha2' => 'BE',
    },
    {
        'ISO-name'   => 'France',
        'ISO-m49'    => '250',
        'ISO-alpha3' => 'FRA',
        'ISO-alpha2' => 'FR',
    },
    {
        'ISO-name'   => 'Germany',
        'ISO-m49'    => '276',
        'ISO-alpha3' => 'DEU',
        'ISO-alpha2' => 'DE',
    },
    {
        'ISO-name'    => 'Liechtenstein',
        'ISO-m49'     => '438',
        'ISO-alpha3'  => 'LIE',
        'ISO-alpha2'  => 'LI',
        'EFTA-member' => 'true',
    },
    {
        'ISO-name'   => 'Luxembourg',
        'ISO-m49'    => '442',
        'ISO-alpha3' => 'LUX',
        'ISO-alpha2' => 'LU',
    },
    {
        'ISO-name'   => 'Netherlands',
        'ISO-m49'    => '528',
        'ISO-alpha3' => 'NLD',
        'ISO-alpha2' => 'NL',
    },
    {
        'ISO-name'    => 'Switzerland',
        'ISO-m49'     => '756',
        'ISO-alpha3'  => 'CHE',
        'ISO-alpha2'  => 'CH',
        'EFTA-member' => 'true',
    },
    {
        'ISO-name'   => 'Cyprus',
        'ISO-m49'    => '196',
        'ISO-alpha3' => 'CYP',
        'ISO-alpha2' => 'CY',
    },
    {
        'ISO-name'   => 'Czech Republic',
        'ISO-m49'    => '203',
        'ISO-alpha3' => 'CZE',
        'ISO-alpha2' => 'CZ',
    },
    {
        'ISO-name' => 'Latvia',
        'ISO-m49'        => '428',
        'ISO-alpha3' => 'LVA',
        'ISO-alpha2' => 'LV',
    }
];

our $ISO_CODES = [ 'ISO-name', 'ISO-m49', 'ISO-alpha3', 'ISO-alpha2', 'EFTA-member' ];

sub is_eu_country {
    my %args = @_ == 1 && is_hash_ref( $_[0] ) ? %{ $_[0] } : @_;

    croak "Agrument country is required"
        unless ($args{country});

    croak "Agrument exclude must be an ARRAY"
        if ($args{exclude} && !is_array_ref($args{exclude}) );

    my $include_EFTA = $args{include_efta} // 0;
    my $exclude_arr  = $args{exclude} // [];
    my $check_country = $args{country};

    foreach my $country ( @{$EU_COUNTRY_MAP} )
    {
        if ( ! $include_EFTA ) {
            if ( $country->{'EFTA-member'} ) {
                next;
            }
        }

        my @country_values = values $country;
        if ( length $exclude_arr > 0 ) {
            my $should_exclude;
            foreach my $elt ( @{$exclude_arr} ) {
                if ( grep { /$elt/xg } @country_values ) {
                    $should_exclude = 1;
                    last;
                }
            }

            if ( $should_exclude ) {
                next;
            }
        }

        foreach my $value ( values $country )
        {
            if ( ref($value) eq 'ARRAY' ) {
                if ( grep { /^$check_country$/xg } @{$value} ) {
                    return 1;
                }
            }

            if ( $value eq $check_country ) {
                return 1;
            }
        }
    }

    return 0;
}

sub list_eu_countries {
    my %args = @_ == 1 && is_hash_ref( $_[0] ) ? %{ $_[0] } : @_;

    croak "Agrument exclude must be an ARRAY"
        if ($args{exclude} && ! is_array_ref($args{exclude}) );

    my $include_EFTA = $args{include_efta} // 0;
    my $exclude_arr = $args{exclude} // [ ];
    my $data_key = $args{iso_code};

    if ( $data_key && ! grep { /^$data_key$/xg } @{$ISO_CODES} ) {
        croak "Argument iso_code must be one of 'ISO-name', 'ISO-m49', 'ISO-alpha3', 'ISO-alpha2'";
    }


    my @return_countries;

    foreach my $country ( @{$EU_COUNTRY_MAP} )
    {
        if ( ! $include_EFTA ) {
            if ( $country->{'EFTA-member'} ) {
                next;
            }
        }

        my @country_values = values $country;
        if ( length $exclude_arr > 0 ) {
            my $should_exclude;
            foreach my $elt ( @{$exclude_arr} ) {
                if ( grep { /$elt/xg } @country_values ) {
                    $should_exclude = 1;
                    last;
                }
            }

            if ( $should_exclude ) {
                next;
            }
        }

        if ( $data_key ) {
            push @return_countries, $country->{$data_key};
        } else {
            push @return_countries, $country;
        }
    }

    return \@return_countries;
}

1;

__END__

=head1 NAME

Locale::Country::EU

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Locale::Country::EU;

  my $array = list_eu_countries({
    include_efta => 1,
    exclude => ['GB']
  });


  my $boolean = is_eu_country({
    country => $array->[0]->{'ISO-name'}
  });

=head1 DESCRIPTION

Locale::Country::EU - Perl extension for determining if a country is within the European Union based on the
following ISO data.

    'ISO-name'   => 'Germany',
    'ISO-m49'    => '276',
    'ISO-alpha3' => 'DEU',
    'ISO-alpha2' => 'DE',

This Module also allows for list customization with additional helper arguments. These are handy in cases like GDPR
where certain conditions can cause the list data to change.

=head2 EXPORT

    is_eu_country
    list_eu_countries
    $ISO_CODES
    $EU_COUNTRY_MAP

=head1 AUTHOR

mgreen, E<lt>matt@mattsizzle.comE<gt>

=head1 METHODS

=head2 is_eu_country ()

Returns where a country is within the European Union (EU) based on the agruments passed to the method. The return will
be truthy when the country is located within the European Union and falsy if it was not determined to be in the EU.

Note agruments are passed into the method within a single hash of key value pairs.

=head3 ARGUMENTS

=over 4

=item B<country: STRING>

The country to be checked for inclusion in the European Union (EU). This value can be any of the following:

    ISO-name    ex. Germany
    ISO-m49     ex. 276
    ISO-alpha3  ex. DEU
    ISO-alpha2  ex. DE

NOTE: You do not have to specific the ISO type being provided for flexiblity as it will cycle through each value automatically to find a match.

=item B<include_efta: 1>

Modifies the European Union (EU) DataSet to include the European Free Trade Association (EFTA) countries. While not part of the "full" EU these additional countries can have EU laws or restrictions applied. Such as the case with GDPR.

=item B<exclude: ARRARY[STR,]>

Allows the caller to modify the European Union (EU) DataSet so that certain countries are excluded. Each value in the passed array is checked against all ISO types in the DataSet.

NOTE: You do not have to specific the ISO type being provided for flexiblity as it will cycle through each value automatically to find a match.

=back

=cut

=head2 list_eu_countries ()

Returns a DataSet of countries in the European Union (EU) based on the agruments passed.

Note agruments are passed into the method within a single hash of key value pairs.

=head3 ARGUMENTS

=over 4

=item B<iso_code: STRING>

When passed and a valid ISO type is provided this method will return an ARRAY[STR,] where each STR is the requested ISO
code for each country.

    ISO-name    ex. Germany
    ISO-m49     ex. 276
    ISO-alpha3  ex. DEU
    ISO-alpha2  ex. DE

NOTE: You do not have to specific the ISO code agrument. If it is not supplied the unmodified EU country DataSet is returned

=item B<include_efta: 1>

Modifies the European Union (EU) DataSet to include the European Free Trade Association (EFTA) countries. While not part of the "full" EU these additional countries can have EU laws or restrictions applied. Such as the case with GDPR.

=item B<exclude: ARRARY[STR,]>

Allows the caller to modify the European Union (EU) DataSet so that certain countries are excluded. Each value in the passed array is checked against all ISO types in the DataSet.

NOTE: You do not have to specific the ISO type being provided for flexiblity as it will cycle through each value automatically to find a match.

=back

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Matthew Green <matt@mattsizzle.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
