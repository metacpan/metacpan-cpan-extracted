package Geo::Address::Parser;

use 5.014;
use strict;
use warnings;

use Carp;
use Module::Runtime qw(use_module);
use Object::Configure 0.16;
use Params::Get 0.13;
use Params::Validate::Strict qw(validate_strict);
use Return::Set 0.02;
use Text::Capitalize 'capitalize_title';

=head1 NAME

Geo::Address::Parser - Lightweight country-aware address parser from flat text

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

# Supported countries and their corresponding rule modules
my %COUNTRY_MODULE = (
	FR => 'Geo::Address::Parser::Rules::FR',
	US => 'Geo::Address::Parser::Rules::US',
	USA => 'Geo::Address::Parser::Rules::US',
	UK => 'Geo::Address::Parser::Rules::UK',
	GB => 'Geo::Address::Parser::Rules::UK',
	CA => 'Geo::Address::Parser::Rules::CA',
	'CANADA' => 'Geo::Address::Parser::Rules::CA',
	AU => 'Geo::Address::Parser::Rules::AU',
	'AUSTRALIA' => 'Geo::Address::Parser::Rules::AU',
	'FRANCE' => 'Geo::Address::Parser::Rules::FR',
	IE => 'Geo::Address::Parser::Rules::IRL',     # Ireland ISO code
	IRL => 'Geo::Address::Parser::Rules::IRL',    # 3-letter code
	'IRELAND' => 'Geo::Address::Parser::Rules::IRL', # Full name
	NZ => 'Geo::Address::Parser::Rules::NZ',
	'NEW ZEALAND' => 'Geo::Address::Parser::Rules::NZ',
);

=head1 METHODS

=head1 SYNOPSIS

    use Geo::Address::Parser;

    my $parser = Geo::Address::Parser->new(country => 'US');

    my $result = $parser->parse("Mastick Senior Center, 1525 Bay St, Alameda, CA");

=encoding utf-8

=head1 DESCRIPTION

This module extracts address components from flat text input. It supports
lightweight parsing for the US, UK, Canada, Australia, and New Zealand, using
country-specific regular expressions.

The class can be configured at runtime using environments and configuration files,
for example,
setting C<$ENV{'GEO__ADDRESS__PARSER__carp_on_warn'}> causes warnings to use L<Carp>.
For more information about runtime configuration,
see L<Object::Configure>.

=head2 new(country)

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

=head3 API SPECIFICATION

=head4 INPUT

  {
    'country' => {
      'type' => 'string', 'min' => 2, 'matches' => qr/^[A-Za-z\s]+$/
    }
  }

=head4 OUTPUT

=over 4

=item * Error: log (if set); croak

=item * Can't parse: undef

=item * Otherwise: Geo::Address::Parser object

=back

=cut

sub new {
	my $class = shift;

	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params('country', \@_),
		schema => {
			'country' => { 'type' => 'string', 'min' => 2, 'matches' => qr/^[A-Za-z\s]+$/ }
		}
	});

	$params = Object::Configure::configure($class, $params);

	my $country = uc($params->{'country'});
	my $module = $COUNTRY_MODULE{$country};
	if(!defined($module)) {
		if($params->{'logger'}) {
			$params->{'logger'}->warn("Unsupported country: $country");
		}
		croak("Unsupported country: $country");
	}

	# Load the appropriate parser module dynamically
	use_module($module);

	return bless {
		%{$params},
		country => $country,
		module => $module
	}, $class;
}

=head2 parse

Takes a string and returns a hashref with the following fields:

=over

=item * name

=item * road

=item * city

=item * region

=item * country

=back

=head3 API SPECIFICATION

=head4 INPUT

  {
    'text' => { 'type' => 'string', 'min' => 2
  }

=head4 OUTPUT

=over 4

=item * Error: log (if set); croak

=item * Can't parse: undef

=item * Otherwise:

  {
    'type' => 'hashref', 'min' => 2
  }

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

	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params('text', \@_),
		schema => {
			'text' => { 'type' => 'string', 'min' => 2 }
		}
	});

	if(!defined($params)) {
		croak(__PACKAGE__, '::parse: Usage($text => string)');
	}
	my $text = $params->{'text'};
	if(!defined($text)) {
		croak(__PACKAGE__, '::parse: Usage($text => string)');
	}

	my $parser = $self->{module};

	# Strip extra whitespace
	$text =~ s/\s+/ /g;
	$text =~ s/^\s//g;
	$text =~ s/\s$//g;
	$text =~ s/\s,/,/g;

	if(my $result = $parser->parse_address($text)) {
		# FIXME: The code addeth and the code taketh away.  It shouldn't addeth in the first place
		for my $key (keys %{$result}) {
			delete $result->{$key} unless defined $result->{$key};
		}
		# Add country field to result if not already present
		$result->{country} //= $self->{country} if $result;

		$result->{'name'} = capitalize_title($result->{'name'}) if($result->{'name'});

		# Returns a hashref with at least two items: name and country
		return Return::Set::set_return($result, { 'type' => 'hashref', 'min' => 2 });
	}
}

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-geo-address-parser at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Address-Parser>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Geo-Address-Parser/coverage/>

=item * L<Object::Configure>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

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
