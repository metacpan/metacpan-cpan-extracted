#!perl -w

# The scantext region hint is an ISO 3166-1 code, and it is appended to each
# candidate place as its country.  Before 0.52:
#
#   - region => 'CA' was appended as ", CA", which the OpenAddresses parser
#     reads as California, and the Canadian address finder never ran because
#     it was keyed on the region being 'Canada' rather than 'CA'
#   - region => 'IE' had no address finder
#
# The backends are stubbed so that the test needs no database: each records
# the strings it is asked to geocode, and the OpenAddresses stub answers only
# the lookup the test expects to be made.

use strict;
use warnings;
use Test::Most;
use Geo::Location::Point;

BEGIN { use_ok('Geo::Coder::Free') }

{
	package	# hide from CPAN indexer
		RecordingBackend;

	sub new { my ($class, %args) = @_; return bless { calls => [], %args }, $class }

	sub geocode {
		my ($self, $location) = @_;
		push @{$self->{'calls'}}, $location;
		if(my $answer = $self->{'answer'}) {
			return Geo::Location::Point->new(lat => 45.0, long => -75.0) if($location =~ $answer);
		}
		return;
	}

	sub calls { return @{$_[0]->{'calls'}} }
}

# Return the geocoder and its OpenAddresses stub, which answers locations
#	matching $answer
sub geocoder
{
	my $answer = shift;

	my $openaddr = RecordingBackend->new(answer => $answer);
	my $geo = bless {
		openaddr => $openaddr,
		local => RecordingBackend->new(),
		maxmind => RecordingBackend->new(),
		scantext_misses => {},
	}, 'Geo::Coder::Free';

	return ($geo, $openaddr);
}

subtest 'Canada: places are looked up with the country name, not "CA"' => sub {
	my ($geo, $openaddr) = geocoder(qr/^Richibucto, Kent, Canada$/);

	my @rc = $geo->geocode(scantext => 'They settled in Richibucto Kent in about 1830', region => 'CA');

	is(scalar(@rc), 1, 'the place is found');
	ok((grep { /, Canada$/ } $openaddr->calls()), 'candidates are suffixed with "Canada"');
	ok(!(grep { /, CA$/ } $openaddr->calls()), 'no candidate is suffixed with "CA", which reads as California');
};

subtest 'Canada: the Canadian address finder runs' => sub {
	# Only the regional lookup of the full address answers, so finding it
	#	means the address finder ran
	my ($geo, $openaddr) = geocoder(qr/^123 Maple Drive, Ottawa, ON K1A 0A9, Canada$/);

	my @rc = $geo->geocode(scantext => 'He lived at 123 Maple Drive, Ottawa, ON K1A 0A9 until he died', region => 'CA');

	is(scalar(@rc), 1, 'the address is found');
	ok((grep { $_ eq '123 Maple Drive, Ottawa, ON K1A 0A9, Canada' } $openaddr->calls()), 'the full address is looked up in Canada');
};

subtest 'Ireland: places use the country name, and the address finder runs' => sub {
	my ($geo, $openaddr) = geocoder(qr/^12 Main Street, Kinsale, County Cork, Ireland, Ireland$/);

	my @rc = $geo->geocode(scantext => '12 Main Street, Kinsale, County Cork, Ireland.', region => 'IE');

	is(scalar(@rc), 1, 'the address is found');
	ok(!(grep { /, IE$/ } $openaddr->calls()), 'no candidate is suffixed with "IE"');
};

subtest 'Lower-case regions are accepted' => sub {
	my ($geo, $openaddr) = geocoder(qr/^Richibucto, Kent, Canada$/);

	my @rc = $geo->geocode(scantext => 'They settled in Richibucto Kent in about 1830', region => 'ca');

	is(scalar(@rc), 1, 'region "ca" is treated as "CA"');
};

subtest 'GB and US are still appended as codes' => sub {
	my ($geo, $openaddr) = geocoder(qr/^Ramsgate, Kent, GB$/);

	my @rc = $geo->geocode(scantext => 'She was born in Ramsgate Kent in 1900', region => 'GB');
	is(scalar(@rc), 1, 'a GB place is found');

	($geo, $openaddr) = geocoder(qr/^Newark, DE, US$/);
	$geo->geocode(scantext => 'He was born in Newark DE in 1987', region => 'US');
	ok((grep { /, US$/ } $openaddr->calls()), 'US candidates are suffixed with "US"');
};

done_testing();
