package Geo::Coder::List;

use 5.10.1;

use warnings;
use strict;
use Carp;
use Time::HiRes;
use HTML::Entities;

use constant DEBUG => 0;	# The higher the number, the more is debugged

# TODO: investigate Geo, Coder::ArcGIS

=head1 NAME

Geo::Coder::List - Call many Geo-Coders

=head1 VERSION

Version 0.25

=cut

our $VERSION = '0.25';
our %locations;	# L1 cache, always used

=head1 SYNOPSIS

L<Geo::Coder::All>
and
L<Geo::Coder::Many>
are great routines but neither quite does what I want.
This module's primary use is to allow many backends to be used by
L<HTML::GoogleMaps::V3>

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Geo::Coder::List object.

Takes an optional argument 'cache' which takes an cache object that supports
get() and set() methods.
The licences of some geo coders,
such as Google,
specifically prohibit caching API calls,
so be careful to only use with those services that allow it.

    use Geo::Coder::List;
    use CHI;

    my $geocoder->new(cache => CHI->new(driver => 'Memory', global => 1));

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return bless { %args, geo_coders => [] }, $class;
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

    my $geo_coderlist = Geo::Coder::List->new()
        ->push({ regex => qr/(Canada|USA|United States)$/, geocoder => Geo::Coder::CA->new() })
        ->push(Geo::Coder::OSM->new());

    # Uses Geo::Coder::CA, and if that fails uses Geo::Coder::OSM
    my $location = $geo_coderlist->geocode(location => '1600 Pennsylvania Ave NW, Washington DC, USA');
    # Only uses Geo::Coder::OSM
    if($location = $geo_coderlist->geocode('10 Downing St, London, UK')) {
        print 'The prime minister lives at co-ordinates ',
            $location->{geometry}{location}{lat}, ',',
            $location->{geometry}{location}{lng}, "\n";
    }

    # It is also possible to limit the number of enquires used by a particular encoder
    $geo_coderlist->push({ geocoder => Geo::Coder::GooglePlaces->new(key => '1234'), limit => 100) });

=cut

sub push {
	my($self, $geocoder) = @_;

	push @{$self->{geocoders}}, $geocoder;

	return $self;
}

=head2 geocode

Runs geocode on all of the loaded drivers.
See L<Geo::Coder::GooglePlaces::V3> for an explanation

The name of the Geo-Coder that gave the result is put into the geocode element of the
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
	} elsif(ref($_[0])) {
		Carp::croak('Usage: geocode(location => $location)');
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{'location'} = shift;
	}

	my $location = $params{'location'};

	return if(!defined($location));
	return if(length($location) == 0);

	$location =~ s/\s\s+/ /g;
	$location = decode_entities($location);

	my @call_details = caller(0);
	print "location: $location\n" if(DEBUG);
	if((!wantarray) && (my $rc = $self->_cache($location))) {
		if(ref($rc) eq 'ARRAY') {
			$rc = @{$rc}[0];
		}
		if(ref($rc) eq 'HASH') {
			delete $rc->{'geocoder'};
			my $log = {
				line => $call_details[2],
				location => $location,
				timetaken => 0,
				wantarray => wantarray,
				result => $rc
			};
			CORE::push @{$self->{'log'}}, $log;
			print "cached\n" if(DEBUG);
			return $rc;
		}
	}
	if(defined($self->_cache($location)) && (ref($self->_cache($location)) eq 'ARRAY') && (my @rc = @{$self->_cache($location)})) {
		if(scalar(@rc)) {
			my $allempty = 1;
			foreach (@rc) {
				if((ref($_) eq 'HASH') || (ref($_) eq 'Geo::Location::Point')) {
					$allempty = 0;
					delete $_->{'geocoder'};
				}
			}
			my $log = {
				line => $call_details[2],
				location => $location,
				timetaken => 0,
				wantarray => wantarray,
				result => \@rc
			};
			CORE::push @{$self->{'log'}}, $log;
			print "cached\n" if(DEBUG);
			if($allempty) {
				return;
			}
			return (wantarray) ? @rc : $rc[0];
		}
	}

	my $error;

	ENCODER: foreach my $g(@{$self->{geocoders}}) {
		my $geocoder = $g;
		if(ref($geocoder) eq 'HASH') {
			if(exists($geocoder->{'limit'}) && defined(my $limit = $geocoder->{'limit'})) {
				print "limit: $limit\n" if(DEBUG);
				if($limit <= 0) {
					next;
				}
				$geocoder->{'limit'}--;
			}
			if(my $regex = $geocoder->{'regex'}) {
				print 'consider ', ref($geocoder->{geocoder}), ": $regex\n" if(DEBUG);
				if($location !~ $regex) {
					next;
				}
			}
			$geocoder = $g->{'geocoder'};
		}
		my @rc;
		my $timetaken = Time::HiRes::time();
		eval {
			# e.g. over QUERY LIMIT with this one
			# TODO: remove from the list of geocoders
			print 'trying ', ref($geocoder), "\n" if(DEBUG);
			if(ref($geocoder) eq 'Geo::GeoNames') {
				print 'username => ', $geocoder->username(), "\n" if(DEBUG);
				die 'lost username' if(!defined($geocoder->username()));
				@rc = $geocoder->geocode($location);
			} else {
				@rc = $geocoder->geocode(%params);
			}
		};
		$timetaken = Time::HiRes::time() - $timetaken;
		if($@) {
			my $log = {
				line => $call_details[2],
				location => $location,
				geocoder => ref($geocoder),
				timetaken => $timetaken,
				wantarray => wantarray,
				error => $@
			};
			CORE::push @{$self->{'log'}}, $log;
			Carp::carp(ref($geocoder), " '$location': $@");
			$error = $@;
			next ENCODER;
		}
		if(scalar(@rc) == 0) {
			my $log = {
				line => $call_details[2],
				location => $location,
				timetaken => $timetaken,
				geocoder => ref($geocoder),
				wantarray => wantarray,
				result => 'not found',
			};
			CORE::push @{$self->{'log'}}, $log;
			next ENCODER;
		}
		POSSIBLE_LOCATION: foreach my $l(@rc) {
			if(ref($l) eq 'ARRAY') {
				# Geo::GeoNames
				# FIXME: should consider all locations in the array
				$l = $l->[0];
			}
			if(!defined($l)) {
				my $log = {
					line => $call_details[2],
					location => $location,
					timetaken => $timetaken,
					geocoder => ref($geocoder),
					wantarray => wantarray,
					result => 'not found',
				};
				CORE::push @{$self->{'log'}}, $log;
				next ENCODER;
			}
			print Data::Dumper->new([\$l])->Dump() if(DEBUG >= 2);
			last if(ref($l) eq 'Geo::Location::Point');
			next if(ref($l) ne 'HASH');
			if($l->{'error'}) {
				my $log = {
					line => $call_details[2],
					location => $location,
					timetaken => $timetaken,
					geocoder => ref($geocoder),
					wantarray => wantarray,
					error => $l->{'error'}
				};
				CORE::push @{$self->{'log'}}, $log;
				next ENCODER;
			} else {
				# Try to create a common interface, helps with HTML::GoogleMaps::V3
				if(!defined($l->{geometry}{location}{lat})) {
					if($l->{lat} && defined($l->{lon})) {
						# OSM/RandMcNalley
						$l->{geometry}{location}{lat} = $l->{lat};
						$l->{geometry}{location}{lng} = $l->{lon};
					} elsif($l->{BestLocation}) {
						# Bing
						$l->{geometry}{location}{lat} = $l->{BestLocation}->{Coordinates}->{Latitude};
						$l->{geometry}{location}{lng} = $l->{BestLocation}->{Coordinates}->{Longitude};
					} elsif($l->{point}) {
						# Bing
						$l->{geometry}{location}{lat} = $l->{point}->{coordinates}[0];
						$l->{geometry}{location}{lng} = $l->{point}->{coordinates}[1];
					} elsif($l->{latt}) {
						# geocoder.ca
						$l->{geometry}{location}{lat} = $l->{latt};
						$l->{geometry}{location}{lng} = $l->{longt};
					} elsif($l->{latitude}) {
						# postcodes.io
						# Geo::Coder::Free
						$l->{geometry}{location}{lat} = $l->{latitude};
						$l->{geometry}{location}{lng} = $l->{longitude};
					} elsif($l->{'properties'}{'geoLatitude'}) {
						# ovi
						$l->{geometry}{location}{lat} = $l->{properties}{geoLatitude};
						$l->{geometry}{location}{lng} = $l->{properties}{geoLongitude};
					} elsif($l->{'results'}[0]->{'geometry'}) {
						# DataScienceToolkit
						$l->{'geometry'}{'location'}{'lat'} = $l->{'results'}[0]->{'geometry'}->{'location'}->{'lat'};
						$l->{'geometry'}{'location'}{'lng'} = $l->{'results'}[0]->{'geometry'}->{'location'}->{'lng'};
					} elsif($l->{'RESULTS'}) {
						# GeoCodeFarm
						$l->{geometry}{location}{lat} = $l->{'RESULTS'}[0]{'COORDINATES'}{'latitude'};
						$l->{geometry}{location}{lng} = $l->{'RESULTS'}[0]{'COORDINATES'}{'longitude'};
					} elsif(defined($l->{result}{addressMatches}[0]->{coordinates}{y})) {
						# US Census
						$l->{geometry}{location}{lat} = $l->{result}{addressMatches}[0]->{coordinates}{y};
						$l->{geometry}{location}{lng} = $l->{result}{addressMatches}[0]->{coordinates}{x};
					} elsif($l->{lat}) {
						# Geo::GeoNames
						$l->{geometry}{location}{lat} = $l->{lat};
						$l->{geometry}{location}{lng} = $l->{lng};
					}

					if($l->{'standard'}{'countryname'}) {
						# geocoder.xyz
						$l->{'address'}{'country'} = $l->{'standard'}{'countryname'};
					}
				}
				if(defined($l->{geometry}{location}{lat})) {
					print $l->{geometry}{location}{lat}, '/', $l->{geometry}{location}{lng}, "\n" if(DEBUG);
					$l->{geocoder} = $geocoder;
					my $log = {
						line => $call_details[2],
						location => $location,
						timetaken => $timetaken,
						geocoder => ref($geocoder),
						wantarray => wantarray,
						result => $l
					};
					CORE::push @{$self->{'log'}}, $log;
					last POSSIBLE_LOCATION;
				}
			}
		}

		if(scalar(@rc)) {
			print 'Number of matches from ', ref($geocoder), ': ', scalar(@rc), "\n" if(DEBUG);
			if(wantarray) {
				$self->_cache($location, \@rc);
				return @rc;
			}
			if(scalar($rc[0])) {	# check it's not an empty hash
				$self->_cache($location, $rc[0]);
				return $rc[0];
			}
		}
	}
	# Can't do this because we need to return undef in this case
	# if($error) {
		# return { error => $error };
	# }
	if(wantarray) {
		$self->_cache($location, ());
		return ();
	}
	$self->_cache($location, undef);
}

=head2 ua

Accessor method to set the UserAgent object used internally by each of the Geo-Coders. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    my $geocoder_list = Geo::Coder::List->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoder_list->ua($ua);

Note that unlike Geo::Coders, there is no read method, since that would be pointless.

=cut

sub ua {
	my $self = shift;

	if(my $ua = shift) {
		foreach my $g(@{$self->{geocoders}}) {
			my $geocoder = $g;
			if(ref($g) eq 'HASH') {
				$geocoder = $g->{'geocoder'};
				if(!defined($geocoder)) {
					Carp::croak('No geocoder found');
				}
			}
			$geocoder->ua($ua);
		}
	}
}

=head2 reverse_geocode

Similar to geocode except it expects a latitude/longitude parameter.

    print $geocoder_list->reverse_geocode(latlng => '37.778907,-122.39732');

=cut

sub reverse_geocode {
	my $self = shift;
	my %params = @_;

	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: geocode(location => $location)');
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{'latlng'} = shift;
	}

	my $latlng = $params{'latlng'}
		or Carp::croak('Usage: reverse_geocode(latlng => $location)');

	my $latitude;
	my $longitude;

	if($latlng) {
		($latitude, $longitude) = split(/,/, $latlng);
	} else {
		$latitude //= $params{'lat'};
		$longitude //= $params{'lon'};
		$longitude //= $params{'long'};
	}

	if(my $rc = $self->_cache($latlng)) {
		return $rc;
	}

	foreach my $g(@{$self->{geocoders}}) {
		my $geocoder = $g;
		if(ref($geocoder) eq 'HASH') {
			if(exists($geocoder->{'limit'}) && defined(my $limit = $geocoder->{'limit'})) {
				print "limit: $limit\n" if(DEBUG);
				if($limit <= 0) {
					next;
				}
				$geocoder->{'limit'}--;
			}
			$geocoder = $g->{'geocoder'};
		}
		print 'trying ', ref($geocoder), "\n" if(DEBUG);
		if(wantarray) {
			my @rc;
			if(my @locs = $geocoder->reverse_geocode(%params)) {
				print Data::Dumper->new([\@locs])->Dump() if(DEBUG >= 2);
				foreach my $loc(@locs) {
					if(my $name = $loc->{'display_name'}) {
						# OSM
						CORE::push @rc, $name;
					} elsif($loc->{'city'}) {
						# Geo::Coder::CA
						my $name;
						if(my $usa = $loc->{'usa'}) {
							$name = $usa->{'usstnumber'};
							if(my $staddress = $usa->{'usstaddress'}) {
								$name .= ' ' if($name);
								$name .= $staddress;
							}
							if(my $city = $usa->{'uscity'}) {
								$name .= ', ' if($name);
								$name .= $city;
							}
							if(my $state = $usa->{'state'}) {
								$name .= ', ' if($name);
								$name .= $state;
							}
							$name .= ', ' if($name);
							$name .= 'USA';
						} else {
							$name = $loc->{'stnumber'};
							if(my $staddress = $loc->{'staddress'}) {
								$name .= ' ' if($name);
								$name .= $staddress;
							}
							if(my $city = $loc->{'city'}) {
								$name .= ', ' if($name);
								$name .= $city;
							}
							if(my $state = $loc->{'prov'}) {
								$state .= ', ' if($name);
								$name .= $state;
							}
						}
						CORE::push @rc, $name;
					}
				}
			}
			if(wantarray) {
				$self->_cache($latlng, \@rc);
				return @rc;
			}
			if(scalar($rc[0])) {	# check it's not an empty hash
				$self->_cache($latlng, $rc[0]);
				return $rc[0];
			}
		} elsif(my $rc = $geocoder->reverse_geocode(%params)) {
			return $rc if(!ref($rc));
			print Data::Dumper->new([$rc])->Dump() if(DEBUG >= 2);
			if(my $name = $rc->{'display_name'}) {
				# OSM
				return $self->_cache($latlng, $name);
			} elsif($rc->{'city'}) {
				# Geo::Coder::CA
				my $name;
				if(my $usa = $rc->{'usa'}) {
					$name = $usa->{'usstnumber'};
					if(my $staddress = $usa->{'usstaddress'}) {
						$name .= ' ' if($name);
						$name .= $staddress;
					}
					if(my $city = $usa->{'uscity'}) {
						$name .= ', ' if($name);
						$name .= $city;
					}
					if(my $state = $usa->{'state'}) {
						$name .= ', ' if($name);
						$name .= $state;
					}
					return $self->_cache($latlng, "$name, USA");
				} else {
					$name = $rc->{'stnumber'};
					if(my $staddress = $rc->{'staddress'}) {
						$name .= ' ' if($name);
						$name .= $staddress;
					}
					if(my $city = $rc->{'city'}) {
						$name .= ', ' if($name);
						$name .= $city;
					}
					if(my $state = $rc->{'prov'}) {
						$state .= ', ' if($name);
						return $self->_cache($latlng, "$name $state");
					}
				}
				return $self->_cache($latlng, $name);
			}
		}
	}
	return;
}

=head2 log

Returns the log of events to help you debug failures,
optimize lookup order and fix quota breakage.

    my @log = @{$geocoderlist->log()};

=cut

sub log {
	my $self = shift;

	return $self->{'log'};
}

=head2 flush

Clear the log.

=cut

sub flush {
	my $self = shift;

	delete $self->{'log'};
}

sub _cache {
	my $self = shift;
	my $key = shift;

	if(my $value = shift) {
		$locations{$key} = $value;
		if($self->{'cache'}) {
			if(ref($value) eq 'ARRAY') {
				foreach my $item(@{$value}) {
					if(ref($item) eq 'HASH') {
						foreach my $key(keys(%{$item})) {
							delete $item->{$key} unless ($key eq 'geometry');
						}
					}
				}
			} elsif(ref($value) eq 'HASH') {
				foreach my $key(keys(%{$value})) {
					delete $value->{$key} unless ($key eq 'geometry');
				}
			}
			$self->{'cache'}->set($key, $value, '1 month');
		}
		return $value;
	}

	if(my $rc = $locations{$key}) {
		return $rc;
	}
	if($self->{'cache'}) {
		return $self->{'cache'}->get($key);
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

reverse_geocode() doesn't update the logger.
reverse_geocode() should support L<Geo::Location::Point> objects.

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

Copyright 2016-2019 Nigel Horne.

This program is released under the following licence: GPL

=cut

1;
