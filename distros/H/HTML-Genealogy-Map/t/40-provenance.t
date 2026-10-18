#!/usr/bin/env perl

# Regression test for the reader side of the Geo::Coder::Free contract.
#
# HTML::Genealogy::Map reads the results of an injected geocoder, and the geocoder
# its own POD and tests pass is Geo::Coder::Free, whose backends answer with a
# real Geo::Location::Point carrying lat, long, lng, location, database, geocoder,
# confidence and accuracy
# A Geo::Location::Point has no 'lon' - nothing in Geo::Coder::Free sets it - so
# reading it made every place look like a failed lookup, and the map came out
# empty.  The result was charged the one-second delay meant for a remote service
# as well, because the provenance was read through a key that was not set either.
#
# The stubs below therefore return the real value object, built the way
# Geo::Coder::Free builds it (lib/Geo/Coder/Free/OpenAddresses.pm#L1013-L1018,
# Local.pm#L777-L783), rather than a hash that merely happens to hold lat and lon.

use strict;
use warnings;

use open qw(:std :encoding(UTF-8));
use Test::Most;
use Test::Needs 'Geo::Location::Point';
use Time::HiRes ();

BEGIN {
	use_ok('HTML::Genealogy::Map');
}

# ---------------------------------------------------------------------------
# A GEDCOM with one birth per place, and a geocoder that answers with real
# points.
# ---------------------------------------------------------------------------

{
	package Provenance::Gedcom;

	sub new {
		my $class = shift;
		return bless { individuals => [@_] }, $class;
	}

	sub individuals { return @{$_[0]->{'individuals'}} }
	sub families { return () }
}

{
	package Provenance::Individual;

	sub new {
		my ($class, $name, $birth) = @_;
		return bless { name => $name, birth => $birth }, $class;
	}

	sub name { return $_[0]->{'name'} }
	sub birth { return $_[0]->{'birth'} }
	sub death { return }
}

{
	package Provenance::Event;

	sub new {
		my ($class, $place) = @_;
		return bless { place => $place }, $class;
	}

	sub place { return $_[0]->{'place'} }
	sub date { return '1 JAN 1900' }
}

{
	package Provenance::Geocoder;

	use Geo::Location::Point;

	# $database mirrors the backend Geo::Coder::Free would have asked: 'database'
	# is what says a result came from a local dataset.
	my %POINTS = (
		'Ramsgate, Kent, England' => { lat => 51.3354, long =>  1.4186, database => 'OpenAddresses', accuracy => 'address' },
		'Minster, Kent, England'  => { lat => 51.3359, long =>  1.3141, database => 'MaxMind', accuracy => 'city' },
		'Gulf of Guinea'          => { lat =>  0,      long =>  0,      database => 'Geo::Coder::Free::Local', accuracy => 'address' },
		# A result a wrapper such as Geo::Coder::List stamped: the distribution is
		# named, the backend is not.
		'Wrapper result'          => { lat => 51.5,    long =>  0.1,    database => undef, accuracy => 'street' },
	);

	sub new {
		my $class = shift;
		return bless { asked => {} }, $class;
	}

	sub asked {
		my $self = shift;
		return $self->{'asked'};
	}

	sub geocode {
		my ($self, %args) = @_;
		my $place = $args{'location'};

		$self->{'asked'}{$place}++;

		my $point = $POINTS{$place} or return;

		# Exactly the keys Geo::Coder::Free sets: no 'lon'.
		return Geo::Location::Point->new(
			lat        => $point->{'lat'},
			long       => $point->{'long'},
			lng        => $point->{'long'},
			location   => $place,
			database   => $point->{'database'},
			geocoder   => 'Geo::Coder::Free',
			confidence => 1,
			accuracy   => $point->{'accuracy'},
		);
	}
}

sub _render
{
	my ($places) = @_;

	my $gedcom = Provenance::Gedcom->new(
		map { Provenance::Individual->new('John /Smith/', Provenance::Event->new($_)) } @{$places}
	);
	my $geocoder = Provenance::Geocoder->new;

	my $started = Time::HiRes::time();
	my ($head, $body) = HTML::Genealogy::Map->onload_render(
		gedcom   => $gedcom,
		geocoder => $geocoder,
		height   => '400px',
		width    => '600px',
	);
	my $elapsed = Time::HiRes::time() - $started;

	return ($head . $body, $elapsed, $geocoder);
}# The markers HTML::OSM emits for the points it was given, as [point, popup].
# The built-in search box also calls L.marker([lat, lon]) with variable names, so
# the popup has to be a literal for a marker to count.
sub _markers
{
	my $html = shift;

	my @markers;
	while($html =~ /L\.marker\(\[([^\]]+)\]\)\.addTo\(map\)\.bindPopup\('(.*?)'\);/g) {
		push @markers, { point => $1, popup => $2 };
	}

	return @markers;
}

subtest 'a Geo::Coder::Free result is mapped, not mistaken for a miss' => sub {
	my ($html, $elapsed, $geocoder) = _render(['Ramsgate, Kent, England', 'Minster, Kent, England']);

	ok(defined($html) && length($html), 'the map rendered');

	# The markers come out in hash order, so match them by the place named in the
	# popup rather than by position.
	my %marked;
	for my $marker (_markers($html)) {
		# HTML::OSM escapes solidus in the popup it embeds in the page, so the
		# closing tag arrives as either </b> or <\/b>.
		$marked{$1} = $marker->{'point'} if($marker->{'popup'} =~ m{<b>([^<]+)<\\?/b>});
	}

	is_deeply(\%marked, {
		'Ramsgate, Kent, England' => '51.335400, 1.418600',
		'Minster, Kent, England'  => '51.335900, 1.314100',
	}, 'each place is marked at the coordinates the geocoder returned');

	is(scalar(keys %{$geocoder->asked()}), 2, 'the geocoder was asked once per place');
};

subtest 'a local lookup is not charged a remote lookup delay' => sub {
	my ($html, $elapsed) = _render(['Ramsgate, Kent, England', 'Minster, Kent, England']);

	# The reader used to miss on every result and then sleep a second per place.
	cmp_ok($elapsed, '<', 1, "two local places rendered in $elapsed seconds, with no 1s sleep");
};

subtest 'a result whose provenance is the distribution alone is still local' => sub {
	my ($html, $elapsed) = _render(['Wrapper result']);

	# 'geocoder' names the
	# distribution on every result Geo::Coder::Free returns, and a wrapper such as
	# Geo::Coder::List stamps it too - so a result that carries it came from local
	# data even when nothing named the backend that answered.
	ok(defined($html) && length($html), 'the map rendered');
	is(scalar(_markers($html)), 1, 'the place is marked');
	cmp_ok($elapsed, '<', 1, "a wrapper-stamped place rendered in $elapsed seconds, with no 1s sleep");
};

subtest 'a position of zero is a position' => sub {
	my ($html) = _render(['Gulf of Guinea']);

	my @markers = _markers($html);
	is(scalar(@markers), 1, 'a point on the equator and prime meridian is marked');
	like($markers[0]{'point'}, qr/^0(?:\.0+)?, 0(?:\.0+)?$/, 'the marker is at 0,0');
};

done_testing();
