package Geo::Address::Parser::Rules::IRL;

use strict;
use warnings;
use utf8;

# use Geo::Coder::Abbreviations;
use Text::Capitalize qw(capitalize_title);

=head1 NAME

Geo::Address::Parser::Rules::IRL - Parsing rules for Irish addresses

=head1 DESCRIPTION

Parses a flat Irish address string into components: name, road, city, and postcode.

=head1 EXPORTS

=head2 parse_address($text)

Returns a hashref with keys:

=over

=item * name

=item * road

=item * city

=item * postcode

=back

=cut

our $VERSION = '0.06';

# heuristics for detecting building/venue names
my $BUILDING_RE = qr/\b(?:house|hall|mill|centre|center|museum|church|hotel|inn|club|school|library|theatre)\b/i;

# Eircode-ish pattern (basic)
my $eircode_re = qr/\b[A-Z0-9]{3}\s?[A-Z0-9]{4}\b/i;

sub parse_address {
	my ($class, $text) = @_;
	return unless defined $text;

	# Basic normalisation
	$text =~ s/^\s+|\s+$//g;
	$text =~ s/\s{2,}/ /g;

	# Expand abbreviations if available
	# my $abbrev;
	# eval { $abbrev = Geo::Coder::Abbreviations->new; 1 } or $abbrev = undef;
	# if ($abbrev) {
		# eval { $text = $abbrev->expand($text) // $text; 1 } or do { /* keep original */ };
	# }

	# Split into comma parts and trim
	my @parts = map { s/^\s+|\s+$//gr } split /,/, $text;
	@parts = grep { length $_ } @parts;	# drop empty parts

	# Remove trailing explicit country token (Ireland/Éire)
	if (@parts and $parts[-1] =~ /^(?:ireland|éire)$/i) {
		pop @parts;
	}

	# Try to extract an Eircode from the last part (or anywhere in last part)
	my $postal_code;
	if (@parts and $parts[-1] =~ /($eircode_re)/) {
		$postal_code = uc $1;
		$parts[-1] =~ s/\Q$1\E//i;
		$parts[-1] =~ s/^\s+|\s+$//g;
		pop @parts if $parts[-1] eq '';
	}

	# Detect "Co. CountyName" in the last part
	my $region;
	if (@parts and $parts[-1] =~ /^co\.?\s*(.+)$/i) {
		$region = capitalize_title(lc $1);
		pop @parts;
	}

	# Prepare result fields
	my ($name, $road, $city);
	my $n = scalar @parts;

	if ($n == 0) {
		# nothing left; return at least country/postal if present
		return {
			name => undef,
			road => undef,
			city => undef,
			region => $region,
			postal_code => $postal_code,
			country => 'Ireland',
		};
	} elsif ($n == 1) {
		# Single token: assume it's a road/locality
		$road = capitalize_title(lc $parts[0]);
		$city = undef;
	} elsif ($n == 2) {
		# Two tokens — ambiguous: decide if first is a building name
		if ($parts[0] =~ $BUILDING_RE) {
			$name = capitalize_title(lc $parts[0]);
			$road = capitalize_title(lc $parts[1]);  # treat locality as road too
			$city = $road;
		} else {
			# likely "road, city"
			$road = capitalize_title(lc $parts[0]);
			$city = capitalize_title(lc $parts[1]);
		}
	} else { # n >= 3
		# typical: [maybe-building-name..., road, city]
		$city = capitalize_title(lc $parts[-1]);
		$road = capitalize_title(lc $parts[-2]);

		# everything before that is the name (may be empty)
		my @name_parts = @parts[0 .. $n - 3];
		$name = join(', ', map { capitalize_title(lc $_) } @name_parts) if @name_parts;
	}

	undef $road if($road eq $city);

	# Fix Irish O' prefixes — e.g., O'connell => O'Connell
	$road =~ s/\bO'([a-z])/"O'" . uc($1)/ge if($road);

	# Final result
	my %result = (
		name => $name,
		road => $road,
		city => $city,
		region => $region,
		postal_code => $postal_code,
		country => 'Ireland',
	);

	return \%result;
}

1;
