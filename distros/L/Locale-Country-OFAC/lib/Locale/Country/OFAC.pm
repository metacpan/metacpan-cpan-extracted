package Locale::Country::OFAC;

use strict;
use warnings;

use Exporter;
use Carp;

use List::Util qw(any);
use Readonly;

Readonly my @CRIMEA_REGION => (95000..99999, 295000..299999 );

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( get_sanction_by_code is_region_sanctioned );

our $VERSION = '1.2.0'; # VERSION 1.1.0
# ABSTRACT: Module to look up OFAC Sanctioned Countries

=pod

=encoding utf8

=head1 NAME

Locale::Country::OFAC - Module to look up OFAC Sanctioned Countries

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Locale::Country::OFAC qw( get_sanction_by_code );

    my $sanction = get_sanction_by_code('IR');

=head1 DESCRIPTION

Module to lookup if a country is OFAC Sanctioned.
Takes a country code and returns a true value if it is.

OFAC Source: <<L http://www.treasury.gov/resource-center/sanctions/Programs/Pages/Programs.aspx >>

=head1 METHODS

=head2 get_sanction_by_code

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

=head1 CAVEATS AND LIMITATIONS

Russian and Ukranian country codes are in this module's lookup table,
but only certain zip codes of them are currently OFAC sanctioned. This is the reasoning
for creating the is_region_sanctioned method.

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

sub get_sanction_by_code {
    my $country_code = shift || croak "get_sanction_by_code requires country code";

    my $country_sanction = $sanctioned_country_codes{uc $country_code};
    return defined $country_sanction && !ref $country_sanction || 0;
}

sub is_region_sanctioned {
    my $country = shift || croak "is_region_sanctioned requires country code";
    my $zip     = shift || croak "is_region_sanctioned requires zip code";

    if ( defined $sanctioned_country_codes{uc$country} ) {
        my $value = $sanctioned_country_codes{uc$country};
        if ( ref $value eq 'ARRAY' ) {
            if ( any { $_ == $zip } @$value  ) {
                return 1;
            }
        }
    }
    return get_sanction_by_code($country);
}

1;
