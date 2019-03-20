package Geo::Location::Point;

use strict;
use warnings;

use GIS::Distance;

=head1 NAME

Geo::Location::Point -
Location information

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

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

	die unless($args{'lat'});
	die unless($args{'long'});

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

=head2	as_string

Prints the object in human-readable format.

=cut

sub as_string {
	my $self = shift;

	my $rc;

	foreach my $field('number', 'street', 'city', 'county', 'state', 'country') {
		if(my $value = $self->{$field}) {
			$rc .= ', ' if($rc);
			$rc .= $value;
		}
	}

	if($self->{'number'}) {
		$rc =~ s/,//;
	}

	return $rc;
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
