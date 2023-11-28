package Geo::Location::Point;

use 5.10.0;	# For the //= operator
use strict;
use warnings;

use Carp;
use GIS::Distance;

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

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

Geo::Location::Point stores a place.

    use Geo::Location::Point;

    my $location = Geo::Location::Point->new(latitude => 0.01, longitude => -71);

=head1 SUBROUTINES/METHODS

=head2 new

    $location = Geo::Location::Point->new({ latitude => 0.01, longitude => -71 });

Takes one optional argument 'key' which is an API key for L<https://timezonedb.com> for looking up timezone data.

=cut

sub new {
	my $class = $_[0];

	shift;

	my %args;
	if(ref($_[0]) eq 'HASH') {
		%args = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::carp('Usage: ', __PACKAGE__, '->new(cache => $cache [, object => $object ], %args)');
		return;
	} elsif(@_ % 2 == 0) {
		%args = @_;
	}

	if(!defined($class)) {
		carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		return;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	$args{'lat'} //= $args{'latitude'} // $args{'Latitude'};
	if(!defined($args{'lat'})) {
		Carp::carp(__PACKAGE__, ': latitude not given');
		return;
	}
	$args{'long'} //= $args{'longitude'} // $args{'Longitude'};
	if(!defined($args{'long'})) {
		Carp::carp(__PACKAGE__, ': longitude not given');
		return;
	}

	return bless \%args, $class;
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

=head2 longitude

Synonym for long().

=cut

sub longitude {
	my $self = shift;

	return $self->{'long'};
}

=head2	distance

Determine the distance between two locations,
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

Are two points the same?

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
			require TimeZone::TimeZoneDB;
			TimeZone::TimeZoneDB->import();

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

Prints the object in human-readable format.

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

sub _sortoutcase {
	# my $self = shift;
	# my $field = lc(shift);
	my $field = $_[1];
	my $rc;

	foreach (split(/ /, $field)) {
		if($rc) {
			$rc .= ' ';
		}
		$rc .= ucfirst($_);
	}

	return $rc;
}

=head2	attr

Get/set location attributes, e.g. city

    $location->city('London');
    $location->country('UK');
    print $location->as_string(), "\n";
    print "$location\n";	# Calls as_string

Because of the way that the cache works, the location() value is cleared by this, so
you may wish to manually all location() afterwards to set the value.

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

	return $self->{$key};
}

=head1 AUTHOR

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

=head1 SEE ALSO

L<GIS::Distance>,
L<Geo::Point>,
L<TimeZone::TimeZoneDB>.

=head1 LICENSE AND COPYRIGHT

Copyright 2019-2023 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

=cut

1;
