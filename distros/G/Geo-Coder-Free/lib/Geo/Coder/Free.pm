package Geo::Coder::Free;

use strict;
use warnings;

use lib '.';

use Geo::Coder::Free::MaxMind;
use Geo::Coder::Free::OpenAddresses;

=head1 NAME

Geo::Coder::Free - Provides a geocoding functionality using free databases

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Geo::Coder::Free;

    my $geocoder = Geo::Coder::Free->new();
    my $location = $geocoder->geocode(location => 'Ramsgate, Kent, UK');

    # Use a local download of http://results.openaddresses.io/
    my $openaddr_geocoder = Geo::Coder::Freee->new(openaddr => $ENV{'OPENADDR_HOME'});
    $location = $openaddr_geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');

=head1 DESCRIPTION

Geo::Coder::Free provides an interface to free databases by acting as a front-end to
Geo::Coder::Free::MaxMind and Geo::Coder::Free::OpenAddresses.

The cgi-bin directory contains a simple DIY geocoding website:

    curl 'http://localhost/~user/cgi-bin/page.fcgi?page=query&q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA'

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Free->new();

Takes one optional parameter, openaddr, which is the base directory of
the OpenAddresses data downloaded from L<http://results.openaddresses.io>.

Takes one optional parameter, directory,
which tells the library where to find the MaxMind and GeoNames files admin1db, admin2.db and cities.[sql|csv.gz].
If that parameter isn't given, the module will attempt to find the databases, but that can't be guaranteed.

=cut

sub new {
	my($proto, %param) = @_;
	my $class = ref($proto) || $proto;

	# Geo::Coder::Free->new not Geo::Coder::Free::new
	return unless($class);

	my $rc = {
		maxmind => Geo::Coder::Free::MaxMind->new(%param)
	};

	if($param{'openaddr'}) {
		$rc->{'openaddr'} = Geo::Coder::Free::OpenAddresses->new(%param);
	}
	if(my $cache = $param{'cache'}) {
		$rc->{'cache'} = $cache;
	}

	return bless $rc, $class;
}

=head2 geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

    # TODO:
    # @locations = $geocoder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

=cut

sub geocode {
	my $self = shift;

	if($self->{'openaddr'}) {
		if(my $rc = $self->{'openaddr'}->geocode(@_)) {
			return $rc;
		}
	}

	return $self->{'maxmind'}->geocode(@_);
}

=head2 reverse_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

To be done.

=cut

sub reverse_geocode {
	Carp::croak('Reverse lookup is not yet supported');
}

=head2	ua

Does nothing, here for compatibility with other geocoders

=cut

sub ua {
}

=head1 AUTHOR

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Lots of lookups fail at the moment.

The openaddresses.io code has yet to be completed.
There are die()s where the code path has yet to be written.

The MaxMind data only contains cities.
The openaddresses data doesn't cover the globe.

Can't parse and handle "London, England".

See L<Geo::Coder::Free::OpenAddresses> for instructions creating its SQLite database from
L<http://results.openaddresses.io/>.

=head1 SEE ALSO

VWF, openaddresses, MaxMind and geonames.

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2018 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

This product includes GeoLite2 data created by MaxMind, available from
L<http://www.maxmind.com>.

=cut

1;
