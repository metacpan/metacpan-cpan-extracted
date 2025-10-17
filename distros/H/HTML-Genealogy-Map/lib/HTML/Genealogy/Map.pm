package HTML::Genealogy::Map;

use strict;
use warnings;

use utf8;

use open qw(:std :encoding(UTF-8));

use autodie;
use Date::Cmp;
use HTML::GoogleMaps::V3;
use HTML::OSM;
use Object::Configure 0.15;
use Params::Get 0.13;
use Params::Validate::Strict 0.16;

=head1 NAME

HTML::Genealogy::Map - Extract and map genealogical events from a GEDCOM file

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 DESCRIPTION

This module parses GEDCOM genealogy files and creates an interactive map showing
the locations of births, marriages, and deaths. Events at the same location are
grouped together in a single marker with a scrollable popup.

=head1 SUBROUTINES/METHODS

=head2 onload_render

Render the map.
It takes two mandatory and one optional parameter.
It returns an array of two elements, the items for the C<head> and C<body>.

=over 4

=item B<gedcom>

L<GEDCOM> object to process.

=item B<geocoder>

Geocoder to use.

=item B<google_key>

Key to Google's map API.

=item B<debug>

Enable print statements of what's going on

=back

=head1 FEATURES

=over 4

=item * Extracts births, marriages, and deaths with location data

=item * Geocodes locations using multiple fallback providers

=item * Groups events at the same location (within ~0.1m precision)

=item * Color-coded event indicators (green=birth, blue=marriage, red=death)

=item * Sorts events chronologically within each category

=item * Scrollable popups for locations with more than 5 events

=item * Persistent caching of geocoding results

=item * For OpenStreetMap: centers on location with most events

=back

=head3	API SPECIFICATION

=head4	INPUT

  {
    'gedcom' => { 'type' => 'object', 'can' => 'individuals' },
    'geocoder' => { 'type' => 'object', 'can' => 'geocode' },
    'debug' => { 'type' => 'boolean', optional => 1 },
    'google_key' => { 'type' => 'string', optional => 1, min => 39, max => 39, matches => qr/^AIza[0-9A-Za-z_-]{35}$/ },
    'height' => { optional => 1 },
    'width' => { optional => 1 }
  }

=head4	OUTPUT

Argument error: croak
No matches found: undef

Returns an array of two strings:

  {
    'type' => 'array',
    'min' => 2,
    'max' => 2,
    'schema' => { 'type' => 'string', min => 10 },
  }

=cut

sub onload_render
{
	my $class = shift;

	# Configuration
	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params('gedcom', @_),
		schema => {
			'gedcom' => { 'type' => 'object', 'can' => 'individuals' },
			'geocoder' => { 'type' => 'object', 'can' => 'geocode' },
			'debug' => { 'type' => 'boolean', optional => 1 },
			'google_key' => { 'type' => 'string', optional => 1, min => 39, max => 39, matches => qr/^AIza[0-9A-Za-z_-]{35}$/ },
			'height' => { optional => 1 },
			'width' => { optional => 1 },
		}
	});

	$params = Object::Configure::configure($class, $params);

	my $ged = $params->{'gedcom'};
	my $debug = $params->{'debug'};
	my $google_key = $params->{'google_key'};
	my $geocoder = $params->{'geocoder'};
	my $height = $params->{'height'} || '400px';
	my $width = $params->{'width'} || '600px';

	# Storage for events
	my @events;

	print "Parsing GEDCOM file...\n" if($debug);

	# Process all individuals
	foreach my $indi ($ged->individuals) {
		next unless(ref($indi));
		my $name = $indi->name || 'Unknown';
		$name =~ s/\///g;	# Remove GEDCOM name delimiters
		$name =~ s/'/&apos;/g;	# Probably this is enough HTML::Entities

		# Birth events
		if (my $birth = $indi->birth) {
			if (ref($birth) && (my $place = $birth->place)) {
				push @events, {
					type => 'birth',
					name => $name,
					place => $place,
					date => $birth->date || 'Unknown date',
				};
			}
		}

		# Death events
		if (my $death = $indi->death) {
			if (ref($death) && (my $place = $death->place)) {
				push @events, {
					type => 'death',
					name => $name,
					place => $place,
					date => $death->date || 'Unknown date',
				};
			}
		}
	}

	# Process all families (marriages)
	foreach my $fam ($ged->families) {
		next unless defined($fam) && ref($fam);	# Yes, really

		my $husband = (ref($fam->husband) && $fam->husband->name) ? $fam->husband->name : 'Unknown';
		my $wife = (ref($fam->wife) && $fam->wife->name) ? $fam->wife->name : 'Unknown';

		$husband =~ s/\///g;
		$wife =~ s/\///g;

		if (my $marriage = $fam->marriage) {
			if (ref($marriage) && (my $place = $marriage->place)) {
				$husband =~ s/'/&apos;/;
				$wife =~ s/'/&apos;/;
				push @events, {
					type => 'marriage',
					name => "$husband &amp; $wife",
					place => $place,
					date => $marriage->date || 'Unknown date',
				};
			}
		}
	}

	print 'Found ', scalar(@events), " events with location data.\n" if($debug);
	print "Geocoding locations...\n" if($debug);

	# Geocode all events
	my @geocoded_events;
	my %cache;	# TODO allow use of params->{cache} if given

	foreach my $event (@events) {
		my $place = $event->{place};

		# Check cache
		unless (exists $cache{$place}) {
			my $location = $geocoder->geocode(location => $place);
			if ($location && $location->{lat} && $location->{lon}) {
				$cache{$place} = {
					lat => $location->{lat},
					lon => $location->{lon},
				};
				print "\tGeocoded: $place\n" if($debug);
				sleep 1 if($location->{'geocoder'} !~ /^Geo::Coder::Free/);	# Be nice to geocoding service

			} else {
				print "\tFailed to geocode: $place\n" if($debug);
				$cache{$place} = undef;
				sleep 1;	# Be nice to geocoding service
			}
		}

		if ($cache{$place}) {
			push @geocoded_events, {
				%$event,
				lat => $cache{$place}{lat},
				lon => $cache{$place}{lon},
			};
		}
	}

	print 'Successfully geocoded ', scalar(@geocoded_events), " events.\n" if($debug);

	return('', '') if(scalar(@geocoded_events) == 0);	# Empty

	print "Generating map...\n" if($debug);

	# Group events by location
	my %location_groups;
	foreach my $event (@geocoded_events) {
		my $key = sprintf('%.6f,%.6f', $event->{lat}, $event->{lon});
		push @{$location_groups{$key}}, $event;
	}

	# Generate map based on available API key
	my $map;
	if ($google_key) {
		$map = _generate_google_map(\%location_groups, $height, $width, $google_key);
	} else {
		$map = _generate_osm_map(\%location_groups, $height, $width);
	}

	return $map->onload_render();
}

# Generate HTML for grouped events
sub _generate_popup_html {
	my ($events) = @_;

	my $place = $events->[0]{place};
	my $event_count = scalar(@$events);

	# Add scrollable container if more than 5 events
	my $container_start = '';
	my $container_end = '';
	if ($event_count > 5) {
		$container_start = '<div style="max-height: 300px; overflow-y: auto;">';
		$container_end = '</div>';
	}

	my $html = "<b>$place</b><br><br>$container_start";

	# Group by type
	my %by_type;
	foreach my $event (@$events) {
		push @{$by_type{$event->{type}}}, $event;
	}

	# Sort function for dates
	my $sort_by_date = sub {
		my $date_a = $a->{'date'};
		my $date_b = $b->{'date'};

		# Put unknown dates at the end
		return 1 if $date_a =~ /^Unknown/i && $date_b !~ /^Unknown/i;
		return -1 if $date_b =~ /^Unknown/i && $date_a !~ /^Unknown/i;
		return 0 if $date_a =~ /^Unknown/i && $date_b =~ /^Unknown/i;

		return Date::Cmp::datecmp($date_a, $date_b);
	};

	# Add births
	if ($by_type{birth}) {
		$html .= '<b>Births:</b><br>';
		foreach my $event (sort $sort_by_date @{$by_type{birth}}) {
			$html .= sprintf(
				'<span style="color: green; font-size: 20px;">&#x25CF;</span> %s (%s)<br>',
				$event->{name},
				$event->{date}
			);
		}
		$html .= '<br>';
	}

	# Add marriages
	if ($by_type{marriage}) {
		$html .= '<b>Marriages:</b><br>';
		foreach my $event (sort $sort_by_date @{$by_type{marriage}}) {
			$html .= sprintf(
				'<span style="color: blue; font-size: 20px;">&#x25CF;</span> %s (%s)<br>',
				$event->{name},
				$event->{date}
			);
		}
		$html .= '<br>';
	}

	# Add deaths
	if ($by_type{death}) {
		$html .= '<b>Deaths:</b><br>';
		foreach my $event (sort $sort_by_date @{$by_type{death}}) {
			$html .= sprintf(
				'<span style="color: red; font-size: 20px;">&#x25CF;</span> %s (%s)<br>',
				$event->{name},
				$event->{date}
			);
		}
	}

	$html .= $container_end;

	return $html;
}

# Generate Google Maps
sub _generate_google_map {
	my ($location_groups, $height, $width, $key) = @_;

	my $map = HTML::GoogleMaps::V3->new(
		key => $key,
		height => $height,
		width => $width
	);

	# Add markers for each location
	my $first = 1;
	foreach my $loc_key (keys %$location_groups) {
		my $events = $location_groups->{$loc_key};
		my ($lat, $lon) = split /,/, $loc_key;

		my $html = _generate_popup_html($events);

		$map->add_marker(
			point => [$lat, $lon],
			html => $html,
		);

		# Center on first location
		if ($first) {
			$map->center([$lat, $lon]);
			$map->zoom(4);
			$first = 0;
		}
	}

	return $map;
}

# Generate OpenStreetMap using HTML::OSM
sub _generate_osm_map {
	my ($location_groups, $height, $width) = @_;

	# Create HTML::OSM object
	my $osm = HTML::OSM->new(zoom => 12, height => $height, width => $width);

	# Add markers for each location
	foreach my $loc_key (keys %$location_groups) {
		my $events = $location_groups->{$loc_key};
		my ($lat, $lon) = split /,/, $loc_key;

		my $html = _generate_popup_html($events);

		$osm->add_marker(
			point => [$lat, $lon],
			html => $html,
		);
	}

	# Find location with most events
	my ($center_lat, $center_lon) = (0, 0);
	my $max_events = 0;
	foreach my $loc_key (keys %$location_groups) {
		my $event_count = scalar(@{$location_groups->{$loc_key}});
		if ($event_count > $max_events) {
			$max_events = $event_count;
			($center_lat, $center_lon) = split /,/, $loc_key;
		}
	}

	$osm->center([$center_lat, $center_lon]);

	return $osm;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=over 4

=item * Test coverage report: L<https://nigelhorne.github.io/HTML-Genealogy-Map/coverage/>

=item * L<Object::Configure>

The class is fully configurable at runtime with configuration files.

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/HTML-Genealogy-Map>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-html-genealogy-map at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Genealogy-Map>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc HTML::Genalogy::Map

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/HTML-Genealogy-Map>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Genealogy-Map>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=HTML-Genealogy-Map>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=HTML::Genalogy::Map>

=back

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
