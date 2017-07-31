package Geo::Coder::List;

use warnings;
use strict;
use Carp;

=head1 NAME

Geo::Coder::List - Call many geocoders

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';
our %locations;

=head1 SYNOPSIS

L<Geo::Coder::All> and L<Geo::Coder::Many> are great routines but neither quite does what I want.
This module's primary use is to allow many backends to be used by L<HTML::GoogleMaps::V3>

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Geo::Coder::List object.
=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	# my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# return bless { %args, geocoders => [] }, $class;
	return bless { geocoders => [] }, $class;
}

=head2 push

Add an encoder to list of encoders.

    use Geo::Coder::List;
    use Geo::Coder::GooglePlaces;
    # ...
    my $list = Geo::Coder::List->new()->push(Geo::Coder::GooglePlaces->new());

Different encoders can be preferred for different locations.
For example this code uses geocode.ca for Canada and US addresses,
and OpenStreetMap for other places:

    my $geocoderlist = Geo::Coder::List->new()
        ->push({ regex => qr/(Canada|USA|United States)$/, geocoder => new_ok('Geo::Coder::CA') })
        ->push(new_ok('Geo::Coder::OSM'));

    # Uses Geo::Coder::CA, and if that fails uses Geo::Coder::OSM
    my $location = $geocoderlist->geocode(location => '1600 Pennsylvania Ave NW, Washington DC, USA');
    # Only uses Geo::Coder::OSM
    if($location = $geocoderlist->geocode('10 Downing St, London, UK')) {
        print 'The prime minister lives at co-ordinates ', 
            $location->{geometry}{location}{lat}, ',',
            $location->{geometry}{location}{lng}, "\n";
    }

=cut

sub push {
	my($self, $geocoder) = @_;

	push @{$self->{geocoders}}, $geocoder;

	return $self;
}

=head2 geocode

Runs geocode on all of the loaded drivers.
See L<Geo::Coder::GooglePlaces::V3> for an explanation

The name of the geocoder that gave the result is put into the geocode element of the
return value, if the value was retrieved from the cache the value will be undefined.

    if(defined($location->{'geocoder'})) {
        print 'Location information retrieved using ', $location->{'geocoder'}, "\n";
    }
=cut

sub geocode {
	my $self = shift;
	my %params;
	
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{'location'} = shift;
	}

	my $location = $params{'location'};

	return unless(defined($location));
	return unless(length($location) > 0);

	if((!wantarray) && (my $rc = $locations{$location})) {
		if(ref($rc) eq 'HASH') {
			delete $rc->{'geocoder'};
			return $rc;
		}
	}
	if(wantarray && defined($locations{$location}) && (ref($locations{$location}) eq 'ARRAY') && (my @rc = @{$locations{$location}})) {
		if(scalar(@rc)) {
			foreach (@rc) {
				delete $_->{'geocoder'};
			}
			return @rc;
		}
	}

	foreach my $g(@{$self->{geocoders}}) {
		my $geocoder = $g;
		if(ref($g) eq 'HASH') {
			my $regex = $g->{'regex'};
			if($location =~ $regex) {
				$geocoder = $g->{'geocoder'};
			} else {
				next;
			}
		}
		my @rc;
		eval {
			# e.g. over QUERY LIMIT with this one
			# TODO: remove from the list of geocoders
			@rc = $geocoder->geocode(%params);
		};
		if($@) {
			Carp::carp(ref($geocoder) . " '$location': $@");
			next;
		}
		foreach my $location(@rc) {
			if($location->{'error'}) {
				@rc = ();
			} else {
				# Try to create a common interface, helps with HTML::GoogleMaps::V3
				if(!defined($location->{geometry}{location}{lat})) {
					if($location->{lat}) {
						# OSM
						$location->{geometry}{location}{lat} = $location->{lat};
						$location->{geometry}{location}{lng} = $location->{lon};
					} elsif($location->{BestLocation}) {
						# Bing
						$location->{geometry}{location}{lat} = $location->{BestLocation}->{Coordinates}->{Latitude};
						$location->{geometry}{location}{lng} = $location->{BestLocation}->{Coordinates}->{Longitude};
					} elsif($location->{point}) {
						# Bing
						$location->{geometry}{location}{lat} = $location->{point}->{coordinates}[0];
						$location->{geometry}{location}{lng} = $location->{point}->{coordinates}[1];
					} elsif($location->{latt}) {
						# geocoder.ca
						$location->{geometry}{location}{lat} = $location->{latt};
						$location->{geometry}{location}{lng} = $location->{longt};
					}

					if($location->{'standard'}{'countryname'}) {
						# XYZ
						$location->{'address'}{'country'} = $location->{'standard'}{'countryname'};
					}
				}
				if(defined($location->{geometry}{location}{lat})) {
					$location->{geocoder} = $geocoder;
					last;
				}
			}
		}

		if(scalar(@rc)) {
			if(wantarray) {
				$locations{$location} = \@rc;
				return @rc;
			}
			if(length($rc[0])) {
				$locations{$location} = $rc[0];
				return $rc[0];
			}
		}
	}
	undef;
}

=head2 ua

Accessor method to set the UserAgent object used internally by each of the geocoders. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    my $geocoderlist = Geo::Coder::List->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoderlist->ua($ua);

Note that unlike Geo::Coders, there is no read method, since that would be pointless.

=cut

sub ua {
	my $self = shift;

	if(my $ua = shift) {
		foreach my $g(@{$self->{geocoders}}) {
			my $geocoder = $g;
			if(ref($g) eq 'HASH') {
				$geocoder = $g->{'geocoder'};
			}
			$geocoder->ua($ua);
		}
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-coder-list at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

There is no reverse_geocode() yet.

=head1 SEE ALSO

L<Geo::Coder::Many>
L<Geo::Coder::All>
L<Geo::Coder::GooglePlaces>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::List

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-List>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-List>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-List>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-List/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2017 Nigel Horne.

This program is released under the following licence: GPL

=cut

1;
