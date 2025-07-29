package Geo::Address::Parser;

use 5.014;
use strict;
use warnings;

use Carp;
use Module::Runtime qw(use_module);
use Params::Get 0.11;
use Text::Capitalize 'capitalize_title';

=encoding utf-8

=head1 NAME

Geo::Address::Parser - Lightweight country-aware address parser from flat text

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

# Supported countries and their corresponding rule modules
my %COUNTRY_MODULE = (
	US => 'Geo::Address::Parser::Rules::US',
	UK => 'Geo::Address::Parser::Rules::UK',
	CA => 'Geo::Address::Parser::Rules::CA',
	AU => 'Geo::Address::Parser::Rules::AU',
	NZ => 'Geo::Address::Parser::Rules::NZ',
);

=head1 METHODS

=head1 SYNOPSIS

    use Geo::Address::Parser;

    my $parser = Geo::Address::Parser->new(country => 'US');

    my $result = $parser->parse("Mastick Senior Center, 1525 Bay St, Alameda, CA");

=head1 DESCRIPTION

This module extracts address components from flat text input. It supports
lightweight parsing for the US, UK, Canada, Australia, and New Zealand, using
country-specific regular expressions.

=head2 new(country => $code)

Creates a new parser for a specific country (US, UK, CA, AU, NZ).

=head3 FORMAL SPECIFICATION

    [COUNTRY]

    GeoAddressParserNew
    ====================
    country? : COUNTRY
    supported : ℙ COUNTRY
    parser! : Parser

    supported = {US, UK, CA, AU, NZ}
    country? ∈ supported
    parser! = parserFor(country?)

=cut

sub new {
	my $class = shift;

	my $params = Params::Get::get_params('country', \@_);

	croak "Missing required 'country' parameter" unless $params->{country};

	my $country = uc $params->{'country'};
	my $module = $COUNTRY_MODULE{$country} or croak "Unsupported country: $country";

	# Load the appropriate parser module dynamically
	use_module($module);

	return bless {
		country => $country,
		module => $module,
	}, $class;
}

=head2 parse($text)

Parses a flat string and returns a hashref with the following fields:

=over

=item * name

=item * street

=item * city

=item * region

=item * country

=back

=head3 FORMAL SPECIFICATION

    [TEXT, COUNTRY, FIELD, VALUE]

    GeoAddressParserState
    ======================
    country : COUNTRY
    parser : COUNTRY ↛ (TEXT ↛ FIELD ↛ VALUE)

    GeoAddressParserParse
    ======================
    ΔGeoAddressParserState
    text? : TEXT
    result! : FIELD ↛ VALUE

    text? ≠ ∅
    country ∈ dom parser
    result! = (parser(country))(text?)
    result!("country") = country

=cut

sub parse
{
	my $self = shift;

	my $params = Params::Get::get_params('text', \@_);

	my $text = $params->{'text'};

	croak 'No input text provided' unless defined $text;

	my $parser = $self->{module};

	# Strip extra whitespace
	$text =~ s/\s+/ /g;
	$text =~ s/^\s//g;
	$text =~ s/\s$//g;
	$text =~ s/\s,/,/g;

	my $result = $parser->parse_address($text);

	# Add country field to result if not already present
	$result->{country} //= $self->{country} if $result;

	$result->{'name'} = capitalize_title($result->{'name'}) if($result->{'name'});

	return $result;
}

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
