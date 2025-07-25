package Geo::Address::Parser::Rules::NZ;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(parse_address);

# NZ postcode: 4 digits
my $postcode_re = qr/\b(\d{4})\b/;

sub parse_address {
	my ($class, $text) = @_;
	return unless defined $text;

	my @parts = map { s/^\s+|\s+$//gr } split /,/, $text;

	my ($name, $street, $suburb, $city, $postcode);

	if ($parts[-1] =~ /(.+?)\s+($postcode_re)$/) {
		$postcode = $2;
		$parts[-1] = $1;	# keep city without postcode
	}

	$city = pop @parts if @parts;
	$suburb = pop @parts if @parts;
	$street = pop @parts if @parts;
	$name = join(', ', @parts) if @parts;

	return {
		name => $name,
		street => $street,
		suburb => $suburb,
		city => $city,
		postcode => $postcode,
	};
}

1;

__END__

=head1 NAME

Geo::Address::Parser::Rules::NZ - Parsing rules for New Zealand addresses

=head1 DESCRIPTION

Parses a flat New Zealand address string into components: name, street, suburb, city, postcode.

=head1 EXPORTS

=head2 parse_address($text)

Returns a hashref with keys:

=over

=item * name

=item * street

=item * suburb

=item * city

=item * postcode

=back

=cut
