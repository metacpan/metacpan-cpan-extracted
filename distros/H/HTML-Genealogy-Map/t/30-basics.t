#!/usr/bin/env perl

use strict;
use warnings;

use open qw(:std :encoding(UTF-8));
use Test::Most tests => 20;

BEGIN {
	use_ok('HTML::Genealogy::Map');
}

# Mock Gedcom object
{
	package Mock::Gedcom;

	sub new {
		my $class = shift;
		return bless {}, $class;
	}

	sub individuals {
		my $self = shift;
		return @{$self->{individuals} || []};
	}

	sub families {
		my $self = shift;
		return @{$self->{families} || []};
	}
}

# Mock Individual
{
	package Mock::Individual;

	sub new {
		my ($class, %args) = @_;
		return bless \%args, $class;
	}

	sub name { return $_[0]->{name}; }
	sub birth { return $_[0]->{birth}; }
	sub death { return $_[0]->{death}; }
}

# Mock Event
{
	package Mock::Event;

	sub new {
		my ($class, %args) = @_;
		return bless \%args, $class;
	}

	sub place { return $_[0]->{place}; }
	sub date { return $_[0]->{date}; }
}

# Mock Family
{
	package Mock::Family;

	sub new {
		my ($class, %args) = @_;
		return bless \%args, $class;
	}

	sub husband { return $_[0]->{husband}; }
	sub wife { return $_[0]->{wife}; }
	sub marriage { return $_[0]->{marriage}; }
}

# Mock Geocoder
{
	package Mock::Geocoder;

	sub new {
		my $class = shift;
		return bless {}, $class;
	}

	sub geocode {
		my ($self, %args) = @_;
		my $location = $args{location};

		# Return mock coordinates based on location
		if ($location eq 'London, England') {
			return {
				lat => 51.5074,
				lon => -0.1278,
				geocoder => 'Mock::Geocoder'
			};
		} elsif ($location eq 'New York, USA') {
			return {
				lat => 40.7128,
				lon => -74.0060,
				geocoder => 'Mock::Geocoder'
			};
		} elsif ($location eq 'Paris, France') {
			return {
				lat => 48.8566,
				lon => 2.3522,
				geocoder => 'Geo::Coder::Free::Local'
			};
		}

		return undef;  # Failed geocoding
	}
}

# Module loads
ok(1, 'Module loaded');

# onload_render requires gedcom parameter
throws_ok {
	HTML::Genealogy::Map->onload_render();
} qr/gedcom/, 'onload_render requires gedcom parameter';

# onload_render requires geocoder parameter
throws_ok {
	my $ged = Mock::Gedcom->new();
	HTML::Genealogy::Map->onload_render(gedcom => $ged);
} qr/geocoder/, 'onload_render requires geocoder parameter';

# Basic functionality with empty GEDCOM
{
	my $ged = Mock::Gedcom->new();
	my $geocoder = Mock::Geocoder->new();

	my ($head, $body) = HTML::Genealogy::Map->onload_render(
		gedcom => $ged,
		geocoder => $geocoder
	);

	ok(defined $head, 'Returns head HTML');
	ok(defined $body, 'Returns body HTML');
}

# GEDCOM with one birth event
{
	my $ged = Mock::Gedcom->new();
	my $birth = Mock::Event->new(
		place => 'London, England',
		date => '1 JAN 1900'
	);
	my $indi = Mock::Individual->new(
		name => 'John /Smith/',
		birth => $birth
	);
	$ged->{individuals} = [$indi];

	my $geocoder = Mock::Geocoder->new();

	my ($head, $body) = HTML::Genealogy::Map->onload_render(
		gedcom => $ged,
		geocoder => $geocoder
	);

	ok(defined $head, 'Head HTML generated for single birth');
	ok(defined $body, 'Body HTML generated for single birth');
	like($body, qr/London, England/, 'Location appears in map');
}

# GEDCOM with death event
{
	my $ged = Mock::Gedcom->new();
	my $death = Mock::Event->new(
		place => 'New York, USA',
		date => '31 DEC 1950'
	);
	my $indi = Mock::Individual->new(
		name => 'Jane /Doe/',
		death => $death
	);
	$ged->{individuals} = [$indi];

	my $geocoder = Mock::Geocoder->new();

	my ($head, $body) = HTML::Genealogy::Map->onload_render(
		gedcom => $ged,
		geocoder => $geocoder
	);

	like($body, qr/New York, USA/, 'Death location appears in map');
	like($body, qr/Jane Doe/, 'Name without slashes appears in map');
}

# GEDCOM with marriage event
{
	my $ged = Mock::Gedcom->new();
	my $marriage = Mock::Event->new(
		place => 'Paris, France',
		date => '15 JUN 1925'
	);
	my $husband = Mock::Individual->new(name => 'John /Smith/');
	my $wife = Mock::Individual->new(name => 'Mary /Jones/');
	my $fam = Mock::Family->new(
		husband => $husband,
		wife => $wife,
		marriage => $marriage
	);
	$ged->{families} = [$fam];

	my $geocoder = Mock::Geocoder->new();

	my ($head, $body) = HTML::Genealogy::Map->onload_render(
		gedcom => $ged,
		geocoder => $geocoder
	);

	like($body, qr/Paris, France/, 'Marriage location appears in map');
}

# Multiple events at same location
{
	my $ged = Mock::Gedcom->new();
	my $birth1 = Mock::Event->new(
		place => 'London, England',
		date => '1 JAN 1900'
	);
	my $birth2 = Mock::Event->new(
		place => 'London, England',
		date => '15 MAR 1905'
	);
	my $indi1 = Mock::Individual->new(
		name => 'John /Smith/',
		birth => $birth1
	);
	my $indi2 = Mock::Individual->new(
		name => 'Mary /Smith/',
		birth => $birth2
	);
	$ged->{individuals} = [$indi1, $indi2];

	my $geocoder = new_ok('Mock::Geocoder');

	my ($head, $body) = HTML::Genealogy::Map->onload_render(
		gedcom => $ged,
		geocoder => $geocoder
	);

	like($body, qr/John Smith/, 'First person in grouped location');
	like($body, qr/Mary Smith/, 'Second person in grouped location');
}

# Debug mode
{
	my $ged = Mock::Gedcom->new();
	my $geocoder = Mock::Geocoder->new();

	my $output = '';
	{
		local *STDOUT;
		open STDOUT, '>', \$output;

		HTML::Genealogy::Map->onload_render(
			gedcom => $ged,
			geocoder => $geocoder,
			debug => 1
		);
	}

	like($output, qr/Parsing GEDCOM/, 'Debug output generated');
}

# Invalid Google key format
throws_ok {
	my $ged = Mock::Gedcom->new();
	my $geocoder = Mock::Geocoder->new();

	HTML::Genealogy::Map->onload_render(
		gedcom => $ged,
		geocoder => $geocoder,
		google_key => 'invalid_key'
	);
} qr/google_key/, 'Rejects invalid Google API key';

# Valid Google key format
{
	my $ged = Mock::Gedcom->new();
	my $geocoder = Mock::Geocoder->new();

	my ($head, $body) = HTML::Genealogy::Map->onload_render(
		gedcom => $ged,
		geocoder => $geocoder,
		google_key => 'AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ0123456'
	);

	ok(defined $head, 'Accepts valid Google API key format');
}

# Events without location data are skipped
{
	my $ged = Mock::Gedcom->new();
	my $birth_no_place = Mock::Event->new(
		place => undef,
		date => '1 JAN 1900'
	);
	my $indi = Mock::Individual->new(
		name => 'John /Smith/',
		birth => $birth_no_place
	);
	$ged->{individuals} = [$indi];

	my $geocoder = Mock::Geocoder->new();

	my ($head, $body) = HTML::Genealogy::Map->onload_render(
		gedcom => $ged,
		geocoder => $geocoder
	);

	ok(defined $body, 'Handles events without location gracefully');
}

# Failed geocoding is handled
{
	my $ged = Mock::Gedcom->new();
	my $birth = Mock::Event->new(
		place => 'Unknown Place',
		date => '1 JAN 1900'
	);
	my $indi = Mock::Individual->new(
		name => 'John /Smith/',
		birth => $birth
	);
	$ged->{individuals} = [$indi];

	my $geocoder = Mock::Geocoder->new();

	my ($head, $body) = HTML::Genealogy::Map::onload_render({
		gedcom => $ged,
		geocoder => $geocoder
	});

	ok(defined $body, 'Handles failed geocoding gracefully');
}

done_testing();
