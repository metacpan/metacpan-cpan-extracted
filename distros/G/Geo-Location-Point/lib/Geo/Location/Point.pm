package Geo::Location::Point;

use 5.10.0;
use strict;
use warnings;

use Carp;
use GIS::Distance;

=head1 NAME

Geo::Location::Point -
Location information

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Geo::Location::Point;

    my $location = Geo::Location::Point->new();

=head1 DESCRIPTION

Geo::Location::Point stores a place.

=head1 METHODS

=head2 new

    $location = Geo::Location::Point->new();

=cut

use Data::Dumper;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Geo::Location::Point->new not Geo::Location::Point::new
	return unless($class);

	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

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

=head2 long

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

=cut

sub long {
	my $self = shift;

	return $self->{'long'};
}

=head2	distance

Determine the distance between two locations,
returns a L<Class::Measure::Length> object.

=cut

sub distance {
	my ($self, $location) = @_;

	die unless $location;

	$self->{'gis'} //= GIS::Distance->new();

	return $self->{'gis'}->distance($self->{'lat'}, $self->{'long'}, $location->lat(), $location->long());
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
					if(($field eq 'state') || ($field eq 'Region') || (lc($field) eq 'country')) {
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
					if(lc($field) eq 'country') {
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
	my $self = shift;
	my $field = lc(shift);
	my $ret;

	foreach (split(/ /, $field)) {
		if($ret) {
			$ret .= ' ';
		}
		$ret .= ucfirst($_);
	}

	$ret;
}

=head2	attr

Get/set location attributes, e.g. city

    $location->city('London');
    $location->country('UK');
    print $location->as_string(), "\n";

=cut

sub AUTOLOAD {
	our $AUTOLOAD;
	my $key = $AUTOLOAD;

	$key =~ s/.*:://;

	return if($key eq 'DESTROY');

	my $self = shift;

	if(my $value = shift) {
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
L<Geo::Point>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

=cut

1;
