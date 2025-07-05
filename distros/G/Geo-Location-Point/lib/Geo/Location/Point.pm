package Geo::Location::Point;

use 5.10.0;	# For the //= operator
use strict;
use warnings;

use Carp;
use GIS::Distance;
use Params::Get;
use Scalar::Util;

use overload (
	'==' => \&equal,
	'!=' => \&not_equal,
	'""' => \&as_string,
	bool => sub { 1 },
	fallback => 1	# So that boolean tests don't cause as_string to be called
);

=head1 NAME

Geo::Location::Point - Location information

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

Geo::Location::Point encapsulates geographical point data with latitude and longitude.
It supports distance calculations,
comparison between points,
and provides various convenience methods for attributes like latitude, longitude, and related string representations.

    use Geo::Location::Point;

    my $location = Geo::Location::Point->new(latitude => 0.01, longitude => -71);

=head1 SUBROUTINES/METHODS

=head2 new

Initialise a new object, accepting latitude and longitude via a hash or hash reference.
Takes one optional argument 'key' which is an API key for L<https://timezonedb.com> for looking up timezone data.

    $location = Geo::Location::Point->new({ latitude => 0.01, longitude => -71 });

=cut

sub new {
	my $class = shift;
	my $params = Params::Get::get_params(undef, \@_);

	if(!defined($class)) {
		carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		return;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %{$params} }, ref($class);
	}

	$params->{'lat'} //= $params->{'latitude'} // $params->{'Latitude'};
	if(!defined($params->{'lat'})) {
		Carp::carp(__PACKAGE__, ': latitude not given');
		return;
	}
	if(abs($params->{'lat'}) > 180) {
		Carp::carp(__PACKAGE__, ': ', $params->{'lat'}, ': invalid latitude');
		return;
	}

	$params->{'long'} //= $params->{'longitude'} // $params->{'Longitude'};
	if(!defined($params->{'long'})) {
		Carp::carp(__PACKAGE__, ': longitude not given');
		return;
	}
	if(abs($params->{'long'}) > 180) {
		Carp::carp(__PACKAGE__, ': ', $params->{'long'}, ': invalid longitude');
		return;
	}
	$params->{'lng'} = $params->{'long'};

	# Return the blessed object
	return bless $params, $class;
}

=head2 lat

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

=cut

sub lat {
	my $self = shift;

	return $self->{'lat'};
}

=head2 latitude

Synonym for lat().

=cut

sub latitude {
	my $self = shift;

	return $self->{'lat'};
}

=head2 long

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

=cut

sub long {
	my $self = shift;

	return $self->{'long'};
}

=head2	lng

Synonym for long().

=cut

sub lng {
	my $self = shift;

	return $self->{'long'};
}

=head2 longitude

Synonym for long().

=cut

sub longitude {
	my $self = shift;

	return $self->{'long'};
}

=head2	distance

Determine the distance between two geographical points,
returns a L<Class::Measure::Length> object.

=cut

sub distance {
	my ($self, $location) = @_;

	if(!defined($location)) {
		Carp::carp('Usage: ', __PACKAGE__, '->distance($location)');
		return;
	}

	$self->{'gis'} //= GIS::Distance->new();

	return $self->{'gis'}->distance($self->{'lat'}, $self->{'long'}, $location->lat(), $location->long());
}

=head2	equal

Check if two points are identical within a small tolerance.

    my $loc1 = Geo::Location::Point->new(lat => 2, long => 2);
    my $loc2 = Geo::Location::Point->new(lat => 2, long => 2);
    print ($loc1 == $loc2), "\n";	# Prints 1

=cut

sub equal {
	my $self = shift;
	my $other = shift;

	# return ($self->distance($other) <= 1e-9);
	return((abs($self->lat() - $other->lat()) <= 1e-9) && (abs(($self->long() - $other->long())) <= 1e-9));
}

=head2	not_equal

Are two points different?

    my $loc1 = Geo::Location::Point->new(lat => 2, long => 2);
    my $loc2 = Geo::Location::Point->new(lat => 2, long => 2);
    print ($loc1 != $loc2), "\n";	# Prints 0

=cut

sub not_equal {
	my $self = shift;

	return(!$self->equal(shift));
}

=head2	tz

Returns the timezone of the location.
Needs L<TimeZone::TimeZoneDB>.

=cut

sub tz {
	my $self = shift;

	if(defined($self->{'key'})) {
		return $self->{'tz'} if(defined($self->{'tz'}));

		if(!defined($self->{'timezonedb'})) {
			unless(TimeZone::TimeZoneDB->can('get_time_zone')) {
				require TimeZone::TimeZoneDB;
				TimeZone::TimeZoneDB->import();
			}

			$self->{'timezonedb'} = TimeZone::TimeZoneDB->new(key => $self->{'key'});
		}
		$self->{'tz'} = $self->{'timezonedb'}->get_time_zone($self)->{'zoneName'};

		return $self->{'tz'};
	}
}

=head2	timezone

Synonym for tz().

=cut

sub timezone {
	my $self = shift;

	return $self->tz();
}

=head2	as_string

Generate a human-readable string describing the point,
incorporating additional attributes like city or country if available.

=cut

sub as_string {
	my $self = shift;

	if($self->{'location'}) {
		return $self->{'location'};
	}

	my $rc = $self->{'name'};
	if($rc) {
		$rc = ucfirst(lc($rc));
	}

	# foreach my $field('house_number', 'number', 'road', 'street', 'AccentCity', 'city', 'county', 'region', 'state_district', 'state', 'country') {
	foreach my $field('house_number', 'number', 'road', 'street', 'city', 'county', 'region', 'state_district', 'state', 'country') {
		if(my $value = ($self->{$field} || $self->{ucfirst($field)})) {
			if($rc) {
				if(($field eq 'street') || ($field eq 'road')) {
					if($self->{'number'} || $self->{'house_number'}) {
						$rc .= ' ';
					} else {
						$rc .= ', '
					}
				} else {
					$rc .= ', ';
				}
			} elsif($rc) {
				$rc .= ', ';
			}
			my $leave_case = 0;
			if(my $country = $self->{'country'} // $self->{'Country'}) {
				if(uc($country) eq 'US') {
					if(($field eq 'state') || ($field eq 'region') || ($field eq 'country')) {
						$leave_case = 1;
						if(lc($field) eq 'country') {
							$value = 'US';
						}
					}
				} elsif(($country eq 'Canada') || ($country eq 'Australia')) {
					if($field eq 'state') {
						$leave_case = 1;
					}
				} elsif(uc($country) eq 'GB') {
					if($field eq 'country') {
						$leave_case = 1;
						$value = 'GB';
					}
				}
			}
			if($leave_case) {
				$rc .= $value;
			} else {
				$rc .= $self->_sortoutcase($value);
				if((($field eq 'street') || ($field eq 'road')) &&
				   ($rc =~ /(.+)\s([NS][ew])$/)) {
					# e.g South Street NW
					$rc = "$1 " . uc($2);
				}
			}
		}
	}

	return $self->{'location'} = $rc;
}

sub _sortoutcase
{
	# Use lc to ensure the input string is in lowercase before capitalisation,
	#	split to break the string into words,
	#	map to capitalise each word and
	#	join to concatenate the capitalised words back into a single string with spaces
	return join ' ', map { ucfirst } split ' ', lc($_[1]);
}

=head2	as_uri

Convert the point to a Geo URI scheme string (geo:latitude,longitude).
See L<https://en.wikipedia.org/wiki/Geo_URI_scheme>.
Arguably it should return a L<URI> object instead.

=cut

sub as_uri
{
	my $self = shift;

	return 'geo:' . $self->{'latitude'} . ',' . $self->{'longitude'};
}

=head2	attr

Get or set arbitrary attributes, such as city or country.

    $location->city('London');
    $location->country('UK');
    print $location->as_string(), "\n";
    print "$location\n";	# Calls as_string

=cut

sub AUTOLOAD {
	our $AUTOLOAD;
	my $key = $AUTOLOAD;

	$key =~ s/.*:://;

	return if($key eq 'DESTROY');

	my $self = shift;

	if(my $value = shift) {
		delete $self->{'location'};	# Invalidate the cache
		$self->{$key} = $value;
	}

	return $self->{$key} || $self->{ucfirst($key)}
}

=head1 AUTHOR

Nigel Horne <njh@nigelhorne.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

There is no validation on the attribute in the AUTOLOAD method,
so typos such as "citty" will not be caught.

=head1 SEE ALSO

L<GIS::Distance>,
L<Geo::Point>,
L<TimeZone::TimeZoneDB>.

=head1 LICENSE AND COPYRIGHT

Copyright 2019-2025 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

=cut

1;
