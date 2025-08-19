package Geo::Address::Parser::Rules::AU;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(parse_address);

# Australian states and territories (2–3 letter abbreviations)
my $state_re = qr/\b(ACT|NSW|NT|QLD|SA|TAS|VIC|WA)\b/i;

# Australian postcode (4 digits)
my $postcode_re = qr/\b(\d{4})\b/;

sub parse_address {
	my ($class, $text) = @_;
	return unless defined $text;

	my @parts = map { s/^\s+|\s+$//gr } split /,/, $text;

	my ($name, $road, $suburb, $state, $postcode);

	# Match state + postcode at end
	if ($parts[-1] =~ /$state_re\s*$postcode_re/) {
		$state = uc($1);
		$postcode = $2;
		pop @parts;
	} elsif ($parts[-1] =~ /^$state_re$/) {
		# Match state only
		$state = uc($1);
		pop @parts;
	}

	$suburb = pop @parts if @parts;
	$road = pop @parts if @parts;
	$name = join(', ', @parts) if @parts;

	return {
		name => $name,
		road => $road,
		suburb => $suburb,
		region => $state,
		postcode => $postcode,
	};
}

1;

__END__

=head1 NAME

Geo::Address::Parser::Rules::AU - Parsing rules for Australian addresses

=head1 DESCRIPTION

Parses a flat Australian address string into components: name, road, suburb, state, postcode.

=head1 EXPORTS

=head2 parse_address($text)

Returns a hashref with keys:

=over

=item * name

=item * road

=item * suburb

=item * region (state)

=item * postcode

=back

=cut
