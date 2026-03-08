package Geo::Address::Parser::Rules::FR;

use strict;
use warnings;

use Exporter 'import';
use Params::Get;
our @EXPORT_OK = qw(parse_address);

our $VERSION = '0.08';

=head1 NAME

Geo::Address::Parser::Rules::FR - Parsing rules for French addresses

=head1 DESCRIPTION

Extracts name, street, city, and postcode from a flat French address string.
French format typically follows: [Name], [Street], [Postcode] [City]

=head1 EXPORTS

=head2 parse_address($text)

Returns a hashref with keys:

=over

=item * name

=item * street

=item * city

=item * region

This contains the state.

=item * postcode

This contains the zip code.

=back

=cut

sub parse_address {
	my $class = shift;
	my $args = Params::Get::get_params('text', \@_);
	my $text = $args->{text};
	my $logger = $args->{logger};

	unless(defined $text) {
		$logger->notice(__PACKAGE__, '::parse_address: Usage(text => $string)') if(defined($logger));
		return;
	}

	# Split by commas and trim whitespace
	my @parts = map { s/^\s+|\s+$//gr } split /,/, $text;

	my ($name, $street, $city, $postcode);

	# France: Postcode (5 digits) usually precedes the City
	# We look at the last part to find "12345 CityName"
	if (@parts) {
		my $last_part = pop @parts;
		# Robust approach to catch common formats
		if ($last_part =~ /(\d{5})\s+(.*)/ || $last_part =~ /(\d{5})/) {
			$postcode = $1;
			$city = $2 // ''; # If the city is missing or elsewhere
		} else {
			# Fallback if the format doesn't match the expected structure
			$city = $last_part;
		}
	} elsif(defined($logger)) {
		$logger->notice(__PACKAGE__, "::parse_address: Can't parse $text");
	}

	# Assign remaining parts to street and name
	$street = pop @parts if @parts;
	$name = join(', ', @parts) if @parts;

	return {
		name	 => $name,
		street   => $street,
		city	 => $city,
		region   => undef, # France uses Departments, but usually not in simple lines
		postcode => $postcode,
	};
}

1;
