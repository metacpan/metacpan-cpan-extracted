package Locale::Country::OFAC;

use strict;
use warnings;

use Exporter;
use Carp;

use Readonly;
Readonly my @CRIMEA_REGION => (95000..99999, 295000..299999 );

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( get_sanction_by_code is_region_sanctioned is_division_sanctioned );

our $VERSION = '1.3.0'; # VERSION
# ABSTRACT: Module to look up OFAC Sanctioned Countries

=pod

=encoding utf8

=head1 NAME

Locale::Country::OFAC - Module to look up OFAC Sanctioned Countries

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Locale::Country::OFAC qw( get_sanction_by_code is_region_sanctioned is_division_sanctioned );

    my $is_sanctioned = get_sanction_by_code( 'IR' );         # Country Code
    my $is_sanctioned = is_region_sanctioned( 'UK', 95000 );  # Country Code, Zip Code
    my $is_sanctioned = is_division_sanctioned( 'UK', '43' ); # Country Code, SubCountry/Division Code

=head1 DESCRIPTION

Module to lookup if a country is OFAC Sanctioned.

OFAC Source: <<L http://www.treasury.gov/resource-center/sanctions/Programs/Pages/Programs.aspx >>

=head1 METHODS

=head2 get_sanction_by_code

    use Locale::Country::OFAC qw( get_sanction_by_code );

    my $iran = 'IR';

    if ( get_sanction_by_code($iran) ) {
        print "Sorry, can't do business- country is Sanctioned\n";
    }

Returns 1 if the country is sanctioned, 0 if not. It also accepts lower case and 3 letter country codes.

=head2 is_region_sanctioned

    use Locale::Country::OFAC qw( is_region_sanctioned );

    my $russia = 'RU';
    my $zip    = 95001;

    if ( is_region_sanctioned( $russia, $zip ) ) {
        print "region is sanctioned \n";
    }

This method takes a country code and zip code. It returns 1 if it is sanctioned and 0 if not.

=head3 CAVEATS AND LIMITATIONS

Russian and Ukranian country codes are in this module's lookup table,
but only certain zip codes of them are currently OFAC sanctioned. This is the reasoning
for creating the is_region_sanctioned method.

=head2 is_division_sanctioned

    use Locale::Country::OFAC qw( is_division_sanctioned );

    my $ukraine = 'UA';
    my $crimea  = '43'; # ISO-3166-2 for Crimera

    if ( is_division_sanctioned( $ukraine, $crimea ) ) {
        print "division is sanctioned \n";
    }


This method takes a country and subcountry code.  It returnes 1 if the provided combination is sanctioned and 0 if not.

=head3 CAVEATS AND LIMITATIONS

All of Crimea is considered sanctioned (when searching for ISO-3166-2:UA 43 ).

=head1 AUTHOR

Daniel Culver,  C<< perlsufi@cpan.org >>

=head1 THANKS TO

Robert Stone, C<< drzigman@cpan.org >>

Doug Schrag

Eris Caffee

HostGator

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

our %sanctioned_country_codes = (
  IRN => 1,
  IR  => 1,
  CUB => 1,
  CU  => 1,
  PRK => 1,
  KP  => 1,
  SYR => 1,
  SY  => 1,
  UA   => \@CRIMEA_REGION, # Ukraine Crimea zip code
  UKR  => \@CRIMEA_REGION,
  RU   => \@CRIMEA_REGION, # Russia Crimea zip code
  RUS  => \@CRIMEA_REGION,
);

our %sanctioned_country_divisions = (
    UA  => [qw( 43 )],
    UKR => [qw( 43 )],
    RU  => [qw( 43 )], # This actually doesn't exist in Russia per ISO-3166-2, but for ease of use include it
    RUS => [qw( 43 )], # This actually doesn't exist in Russia per ISO-3166-2, but for ease of use include it
);

sub get_sanction_by_code {
    my $country_code = shift || croak "get_sanction_by_code requires country code";

    my $country_sanction = $sanctioned_country_codes{uc $country_code};
    return defined $country_sanction && !ref $country_sanction || 0;
}

sub is_region_sanctioned {
    my $country = shift || croak "is_region_sanctioned requires country code";
    my $zip     = shift || croak "is_region_sanctioned requires zip code";

    if ( defined $sanctioned_country_codes{uc$country} ) {
        my $zipcodes = $sanctioned_country_codes{uc$country};
        if ( ref $zipcodes eq 'ARRAY' ) {
            if ( grep { $_ eq $zip } @$zipcodes ) {
                return 1;
            }
        }
    }

    return get_sanction_by_code($country);
}

sub is_division_sanctioned {
    my $country  = shift || croak 'is_division_sanctioned requires country code';
    my $division = shift || croak 'is_division_sanctioned requires division';

    if ( defined $sanctioned_country_divisions{ uc $country } ) {
        my $divisions = $sanctioned_country_divisions{ uc $country };

        if ( ref $divisions eq 'ARRAY' ) {
            if ( grep { $_ eq $division } @$divisions ) {
                return 1;
            }
        }
    }

    return get_sanction_by_code($country);
}

1;
