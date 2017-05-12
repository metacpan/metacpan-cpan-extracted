# 
# This file is part of Geo-ICAO
# 
# This software is copyright (c) 2007 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use 5.008;
use warnings;
use strict;

package Geo::ICAO;
our $VERSION = '1.100140';
# ABSTRACT: Airport and ICAO codes lookup

use Carp;
use File::ShareDir qw{ dist_dir };
use List::Util     qw{ first };
use Path::Class;
use Readonly;
use Sub::Exporter  qw{ setup_exporter };


# -- exporting
{
    my @regions   = qw{ all_region_codes  all_region_names  region2code  code2region  };
    my @countries = qw{ all_country_codes all_country_names country2code code2country };
    my @airports  = qw{ all_airport_codes all_airport_names airport2code code2airport };
    setup_exporter( {
        exports => [ @regions, @countries, @airports ],
        groups  => {
            region  => \@regions,
            country => \@countries,
            airport => \@airports,
        }
    } );
}


#-- private vars.

# - vars defined statically

# list of ICAO codes for the regions with their name.
Readonly my %code2region => (
    A => 'Western South Pacific',
    B => 'Iceland/Greenland',
    C => 'Canada',
    D => 'West Africa',
    E => 'Northern Europe',
    F => 'Southern Africa',
    G => 'Northwestern Africa',
    H => 'Northeastern Africa',
    K => 'USA',
    L => 'Southern Europe and Israel',
    M => 'Central America',
    N => 'South Pacific',
    O => 'Southwest Asia, Afghanistan and Pakistan',
    P => 'Eastern North Pacific',
    R => 'Western North Pacific',
    S => 'South America',
    T => 'Caribbean',
    U => 'Russia and former Soviet States',
    V => 'South Asia and mainland Southeast Asia',
    W => 'Maritime Southeast Asia',
    Y => 'Australia',
    Z => 'China, Mongolia and North Korea',
);

# list of ICAO codes for the countries with their name.
Readonly my %code2country => _get_code2country();

# location of data file
Readonly my $FDATA => file( dist_dir('Geo-ICAO'), 'icao.data' );


# - vars computed after other vars

my %region2code = reverse %code2region;
my %country2code;
{ # need to loop, since some countries have more than one code.
    foreach my $code ( keys %code2country ) {
        my $country = $code2country{$code};
        push @{ $country2code{$country} }, $code;
    }
}


#-- public subs

# - subs handling regions.


sub all_region_codes { return keys %code2region; }
sub all_region_names { return keys %region2code; }



sub region2code { return $region2code{$_[0]}; }
sub code2region {
    my ($code) = @_;
    my $letter = substr $code, 0, 1; # can be called with an airport code
    return $code2region{$letter};
}


# - subs handling countries.


sub all_country_codes {
    my ($code) = @_;

    return keys %code2country unless defined $code; # no filters
    # sanity checks on params
    croak "'$code' is not a valid region code" unless defined code2region($code);
    return grep { /^$code/ } keys %code2country;    # filtering
}



sub all_country_names {
    my ($code) = @_;

    return keys %country2code unless defined $code; # no filters
    # sanity checks on params
    croak "'$code' is not a valid region code" unless defined code2region($code);

    # %country2code holds array refs. but even if a country has more
    # than one code assigned, they will be in the same region: we just
    # need to test the first code.
    return grep { $country2code{$_}[0] =~ /^$code/ } keys %country2code;
}



sub country2code {
    my ($country) = @_;
    my $codes = $country2code{$country};
    return defined $codes ? @$codes : undef;
}



sub code2country {
    my ($code) = @_;
    return $code2country{$code}
        || $code2country{substr($code,0,2)}
        || $code2country{substr($code,0,1)};
}


# - subs handling airports


sub all_airport_codes {
    my ($code) = @_;

    # sanity checks on params
    croak 'should provid a region or country code' unless defined $code;
    croak "'$code' is not a valid region or country code"
        unless exists $code2country{$code}
            || exists $code2region{$code};

    open my $fh, '<', $FDATA or die "can't open $FDATA: $!";
    my @codes;
    LINE:
    while ( my $line = <$fh>) {
        next LINE unless $line =~ /^$code/;  # filtering on $code
        my ($c, undef) = split/\|/, $line;
        push @codes, $c;
    }
    close $fh;
    return @codes;
}



sub all_airport_names {
    my ($code) = @_;

    # sanity checks on params
    croak 'should provid a region or country code' unless defined $code;
    croak "'$code' is not a valid region or country code"
        unless exists $code2country{$code}
            || exists $code2region{$code};

    open my $fh, '<', $FDATA or die "can't open $FDATA: $!";
    my @codes;
    LINE:
    while ( my $line = <$fh>) {
        next LINE unless $line =~ /^$code/;  # filtering on $code
        my (undef, $airport, undef) = split/\|/, $line;
        push @codes, $airport;
    }
    close $fh;
    return @codes;
}



sub airport2code {
    my ($name) = @_;

    open my $fh, '<', $FDATA or die "can't open $FDATA: $!";
    LINE:
    while ( my $line = <$fh>) {
        my ($code, $airport, undef) = split/\|/, $line;
        next LINE unless lc($airport) eq lc($name);
        close $fh;
        return $code;
    }
    close $fh;
    return;          # no airport found
}



sub code2airport {
    my ($code) = @_;

    open my $fh, '<', $FDATA or die "can't open $FDATA: $!";
    LINE:
    while ( my $line = <$fh>) {
        next LINE unless $line =~ /^$code\|/;
        chomp $line;
        my (undef, $airport, $location) = split/\|/, $line;
        close $fh;
        return wantarray ? ($airport, $location) : $airport;
    }
    close $fh;
    return;          # no airport found
}


# -- private subs

#
# my %data = _get_code2country();
#
# read the country.data file shipped in the share/ directory, parse and
# return it as a hash. the key is the country code, the value is the
# country name.
#
sub _get_code2country {
    my %data;
    my $file = file( dist_dir('Geo-ICAO'), 'country.data' );
    open my $fh, '<', $file or die "can't open $file: $!";
    while ( my $line = <$fh>) {
        chomp $line;
        my ($code, $country) = split/\|/, $line;
        $data{$code} = $country;
    }
    close $fh;
    return %data;
}


1;


=pod

=head1 NAME

Geo::ICAO - Airport and ICAO codes lookup

=head1 VERSION

version 1.100140

=head1 SYNOPSIS

    use Geo::ICAO qw{ :all };

    my @region_codes = all_region_codes();
    my @region_names = all_region_names();
    my $code   = region2code('Canada');
    my $region = code2region('C');

    my @country_codes = all_country_codes();
    my @country_names = all_country_names();
    my @codes  = country2code('Brazil');
    my $region = code2country('SB');

    my @airport_codes = all_airport_codes('B');
    my @airport_names = all_airport_names('B');
    my $code    = airport2code('Lyon Bron Airport');
    my $airport = code2airport('LFLY');
    my ($airport, $location) = code2airport('LFLY'); # list context

=head1 DESCRIPTION

The International Civil Aviation Organization (ICAO), a major agency of
the United Nations, codifies the principles and techniques of
international air navigation and fosters the planning and development of
international air transport to ensure safe and orderly growth. Among the
standards defined by ICAO is an airport code system (not to be confused
with IATA airport codes), using 4-letter for this.

This module provides easy access to the list of airport ICAO codes, with
mapping of those codes with airport names, country and region codes.

Nothing is exported by default, but all the functions described below
are exportable: it's up to you to decide what you want to import. Export
is done with L<Sub::Exporter>, so you can play all kind of tricks.

Note that the keyword C<:all> will import everything, and each category
of function provides its own keyword. See below.

=head2 Regions

The first letter of an ICAO code refer to the region of the airport. The
region is quite loosely defined as per the ICAO. This set of functions
allow retrieval and digging of the regions.

Note: you can import all those functions with the C<:region> keyword.

=head2 Countries

The first two letters of an ICAO code refer to the country of the
airport. Once again, the rules are not really set in stone: some codes
are shared by more than one country, some countries are defined more
than once... and some countries (Canada, USA, Russia, Australia and
China) are even coded on only one letter - ie, the country is the same
as the region). This set of functions allow retrieval and digging of the
countries.

Note: you can import all those functions with the C<:country> keyword.

=head2 Airports

This set of functions allow retrieval and digging of the airports, which
are defined on 4 letters.

Note: you can import all those functions with the C<:airport> keyword.

=head1 REGION FUNCTIONS

=head2 my @codes = all_region_codes();

Return the list of all single letters defining an ICAO region. No
parameter needed.

=head2 my @regions = all_region_names();

Return the list of all ICAO region names. No parameter needed.

=head2 my $code = region2code( $region );

Return the one-letter ICAO C<$code> corresponding to C<$region>. If the
region does not exist, return undef.

=head2 my $region = code2region( $code );

Return the ICAO C<$region> corresponding to C<$code>. Note that C<$code>
can be a one-letter code (region), two-letters code (country) or a four-
letters code (airport): in either case, the region will be returned.

Return undef if the associated region doesn't exist.

=head1 COUNTRIES FUNCTIONS

=head2 my @codes = all_country_codes( [$code] );

Return the list of all single- or double-letters defining an ICAO
country. If a region C<$code> is given, return only the country codes of
this region. (Note: dies if C<$code> isn't a valid ICAO region code).

=head2 my @countries = all_country_names( [$code] );

Return the list of all ICAO country names. If a region C<$code> is
given, return only the country names of this region. (Note: dies if
C<$code> isn't a valid ICAO region code).

=head2 my @codes = country2code( $country );

Return the list of ICAO codes corresponding to C<$country>. It's a list
since some countries have more than one code. Note that the codes can be
single-letters (USA, etc.)

=head2 my $country = code2country( $code );

Return the ICAO C<$country> corresponding to C<$code>. Note that
C<$code> can be a classic country code, or a four-letters code
(airport): in either case, the region will be returned.

Return undef if the associated region doesn't exist.

=head1 AIRPORT FUNCTIONS

=head2 my @codes = all_airport_codes( $code );

Return the list of all ICAO airport codes in the C<$code> country
(C<$code> can also be a region code). Note that compared to the
region or country equivalent, this function B<requires> an argument.
It will die otherwise (or if C<$code> isn't a valid ICAO country or
region code).

=head2 my @codes = all_airport_names( $code );

Return the list of all ICAO airport names in the C<$code> country
(C<$code> can also be a region code). Note that compared to the
region or country equivalent, this function B<requires> an argument.
It will die otherwise (or if C<$code> isn't a valid ICAO country or
region code).

=head2 my $code = airport2code( $airport );

Return the C<$code> of the C<$airport>, undef i no airport matched. Note
that the string comparison is done on a case-insensitive basis.

=head2 my $airport = code2airport( $code );

Return the C<$airport> name corresponding to C<$code>. In list context,
return both the airport name and its location (if known).

=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-ICAO>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-ICAO>

=item * Git repository

L<http://github.com/jquelin/geo-icao>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-ICA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-ICAO>

=back

=head1 AUTHOR

  Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


