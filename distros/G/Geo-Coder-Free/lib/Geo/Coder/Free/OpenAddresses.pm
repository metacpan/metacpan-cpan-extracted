package Geo::Coder::Free::OpenAddresses;

use strict;
use warnings;

use Geo::Coder::Free::DB::OpenAddr;	# SQLite database
use Geo::Coder::Free::DB::openaddresses;	# The original CSV files
use Module::Info;
use Carp;
use File::Spec;
use File::pfopen;
use Locale::CA;
use Locale::US;
use Locale::SubCountry;
use CHI;
use Locale::Country;
use Geo::StreetAddress::US;
use Digest::MD5;
use Encode;
use Storable;

#  Some locations aren't found because of inconsistencies in the way things are stored - these are some values I know
# FIXME: Should be in a configuration file
my %known_locations = (
	'Newport Pagnell, Buckinghamshire, England' => {
		'latitude' => 52.08675,
		'longitude' => -0.72270
	},
);

our $libpostal_is_installed = 0;

=head1 NAME

Geo::Coder::Free::OpenAddresses - Provides a geocoding functionality to the data from openaddresses.io

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Geo::Coder::Free::OpenAddresses

    # Use a local download of http://results.openaddresses.io/
    my $geocoder = Geo::Coder::Free::OpenAddresses->new(openaddr => $ENV{'OPENADDR_HOME'});
    $location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');

=head1 DESCRIPTION

Geo::Coder::Free::OpenAddresses provides an interface to the free geolocation database at http://openadresses.io

Refer to the source URL for licencing information for these files:

To install:

1. download the data from http://results.openaddresses.io/. You will find licencing information on that page.
2. unzip the data into a directory.
3. point the environment variable OPENADDR_HOME to that directory and save in the profile of your choice.
4. run the createdatabases.PL script which imports the data into an SQLite database.  This process will take some time.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Free::OpenAddresses->new();

Takes an optional parameter openaddr, which is the base directory of
the OpenAddresses data downloaded from http://results.openaddresses.io.

Takes an optional parameter cache, which points to an object that understands get() and set() messages to store data in

=cut

sub new {
	my($proto, %param) = @_;
	my $class = ref($proto) || $proto;

	# Geo::Coder::Free->new not Geo::Coder::Free::new
	return unless($class);

	if(eval { require Geo::libpostal; } ) {
		Geo::libpostal->import();
		$libpostal_is_installed = 1;
	}

	if(my $openaddr = $param{'openaddr'}) {
		Carp::carp "Can't find the directory $openaddr"
			if((!-d $openaddr) || (!-r $openaddr));
		return bless { openaddr => $openaddr, cache => $param{'cache'} }, $class;
	}
	Carp::croak(__PACKAGE__ . ": usage: new(openaddr => '/path/to/openaddresses')");
}

=head2 geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'longitude'}, "\n";

    # TODO:
    # @locations = $geocoder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

When looking for a house number in a street, if that address isn't found but that
street is found, a place in the street is given.
So "106 Wells Street, Fort Wayne, Allen, Indiana, USA" isn't found, a match for
"Wells Street, Fort Wayne, Allen, Indiana, USA" will be given instead.
Arguably that's incorrect, but it is the behaviour I want.

=cut

sub geocode {
	my $self = shift;

	my %param;
	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: geocode(location => $location)');
	} elsif(@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{location} = shift;
	}

	my $location = $param{location}
		or Carp::croak('Usage: geocode(location => $location)');

	# ::diag($location);

	if($location =~ /^(.+),\s*Washington\s*DC,(.+)$/) {
		$location = "$1, Washington, DC, $2";
	}

	if($known_locations{$location}) {
		return $known_locations{$location};
	}

	my $county;
	my $state;
	my $country;
	my $street;
	my $openaddr_db;

	$location =~ s/\.//g;

	if($location !~ /,/) {
		if($location =~ /^(.+?)\s+(United States|USA|US)$/i) {
			my $l = $1;
			$l =~ s/\s+//g;
			if(my $rc = $self->_get($l . 'US')) {
				return $rc;
			}
		}
	}

	if($location =~ /^(.+?)[,\s]+(United States|USA|US)$/i) {
		my $l = $1;
		$l =~ s/,/ /g;
		$l =~ s/\s\s+/ /g;
		if(my $href = Geo::StreetAddress::US->parse_address($l)) {
			# print Data::Dumper->new([$href])->Dump();
			$state = $href->{'state'};
			if(length($state) > 2) {
				if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
					$state = $twoletterstate;
				}
			}
			my $city;
			if($href->{city}) {
				$city = uc($href->{city});
			}
			if($street = $href->{street}) {
				if(my $type = $self->_normalize($href->{'type'})) {
					$street .= " $type";
				}
				if($href->{suffix}) {
					$street .= ' ' . $href->{suffix};
				}
			}
			if($street) {
				if(my $prefix = $href->{prefix}) {
					$street = "$prefix $street";
				}
				my $rc;
				if($href->{'number'}) {
					if($rc = $self->_get($href->{'number'} . "$street$city$state" . 'US')) {
						return $rc;
					}
				}
				if($rc = $self->_get("$street$city$state" . 'US')) {
					return $rc;
				}
			}
		}
	}

	if($libpostal_is_installed) {
		if(my %addr = Geo::libpostal::parse_address($location)) {
			# print Data::Dumper->new([\%addr])->Dump();
			if($addr{'country'} && $addr{'state'} && ($addr{'country'} =~ /^(Canada|United States|USA|US)$/i)) {
				if($street = $addr{'road'}) {
					$street = uc($street);
					if($street =~ /(.+)\s+STREET$/) {
						$street = "$1 ST";
					} elsif($street =~ /(.+)\s+ROAD$/) {
						$street = "$1 RD";
					} elsif($street =~ /(.+)\s+AVENUE$/) {
						$street = "$1 AVE";
					} elsif($street =~ /(.+)\s+AVENUE\s+(.+)/) {
						$street = "$1 AVE $2";
					} elsif($street =~ /(.+)\s+CT$/) {
						$street = "$1 COURT";
					} elsif($street =~ /(.+)\s+CIRCLE$/) {
						$street = "$1 CIR";
					}
					$street =~ s/^0+//;	# Turn 04th St into 4th St
					$addr{'road'} = $street;
				}
				if($addr{'country'} =~ /Canada/i) {
					$addr{'country'} = 'CA';
					if(length($addr{'state'}) > 2) {
						if(my $twoletterstate = Locale::CA->new()->{province2code}{uc($addr{'state'})}) {
							$addr{'state'} = $twoletterstate;
						}
					}
				} else {
					$addr{'country'} = 'US';
					if(length($addr{'state'}) > 2) {
						if(my $twoletterstate = Locale::US->new()->{state2code}{uc($addr{'state'})}) {
							$addr{'state'} = $twoletterstate;
						}
					}
				}
				if(my $rc = $self->_search(\%addr, ('house_number', 'road', 'city', 'state_district', 'state', 'country'))) {
					return $rc;
				}
				if($addr{'state_district'}) {
					if(my $rc = $self->_search(\%addr, ('house_number', 'road', 'city', 'state', 'country'))) {
						return $rc;
					}
					if($addr{'house_number'}) {
						if(my $rc = $self->_search(\%addr, ('road', 'city', 'state', 'country'))) {
							return $rc;
						}
					}
				} elsif($addr{'house_number'}) {
					if(my $rc = $self->_search(\%addr, ('road', 'city', 'state', 'country'))) {
						return $rc;
					}
				}
			}
		}
	}

	if($location =~ /(.+),\s*([\s\w]+),\s*([\w\s]+)$/) {
		my $city = $1;
		$state = $2;
		$country = $3;
		$state =~ s/\s$//g;
		$country =~ s/\s$//g;
		$openaddr_db = $self->{openaddr_db} ||
			Geo::Coder::Free::DB::openaddresses->new(
				directory => $self->{openaddr},
				cache => $self->{cache} || CHI->new(driver => 'Memory', datastore => {})
			);
		$self->{openaddr_db} = $openaddr_db;
		if($openaddr_db && (my $c = country2code($country))) {
			if($c eq 'us') {
				if(length($state) > 2) {
					if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
						$state = $twoletterstate;
					}
				}
				my $rc;

				if($city !~ /,/) {
					$city = uc($city);
					# Simple case looking up a city in a state in the US
					if($city !~ /^\sCOUNTY$/) {
						if($rc = $self->_get("$city$state" . 'US')) {
							return $rc;
						}
					}
				} elsif(my $href = Geo::StreetAddress::US->parse_address("$city, $state")) {
					# Well formed, simple street address in the US
					# ::diag(Data::Dumper->new([\$href])->Dump());
					$state = $href->{'state'};
					if(length($state) > 2) {
						if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
							$state = $twoletterstate;
						}
					}
					my %args = (state => $state, country => 'US');
					if($href->{city}) {
						$city = $args{city} = uc($href->{city});
					}
					if($href->{number}) {
						$args{number} = $href->{number};
					}
					if($street = $href->{street}) {
						if(my $type = $self->_normalize($href->{'type'})) {
							$street .= " $type";
						}
						if($href->{suffix}) {
							$street .= ' ' . $href->{suffix};
						}
					}
					if($street) {
						if(my $prefix = $href->{prefix}) {
							$street = "$prefix $street";
						}
						$args{street} = uc($street);
						if($href->{'number'}) {
							if($rc = $self->_get($href->{'number'} . "$street$city$state" . 'US')) {
								return $rc;
							}
						}
						if($rc = $self->_get("$street$city$state" . 'US')) {
							return $rc;
						}
					}
					warn "Fast lookup of US location' $location' failed";
				} else {
					if($city =~ /^(\d.+),\s*([\w\s]+),\s*([\w\s]+)/) {
						if(my $href = Geo::StreetAddress::US->parse_address("$1, $2, $state")) {
							# Street, City, County
							# 105 S. West Street, Spencer, Owen, Indiana, USA
							# ::diag(Data::Dumper->new([\$href])->Dump());
							$county = $3;
							$county =~ s/\s*county$//i;
							$state = $href->{'state'};
							if(length($state) > 2) {
								if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
									$state = $twoletterstate;
								}
							}
							my %args = (county => uc($county), state => $state, country => 'US');
							if($href->{city}) {
								$city = $args{city} = uc($href->{city});
							}
							if($href->{number}) {
								$args{number} = $href->{number};
							}
							if($street = $href->{street}) {
								if(my $type = $self->_normalize($href->{'type'})) {
									$street .= " $type";
								}
								if($href->{suffix}) {
									$street .= ' ' . $href->{suffix};
								}
								if(my $prefix = $href->{prefix}) {
									$street = "$prefix $street";
								}
								$args{street} = uc($street);
								if($href->{'number'}) {
									if($county) {
										if($rc = $self->_get($href->{'number'} . "$street$city$county$state" . 'US')) {
											return $rc;
										}
									}
									if($rc = $self->_get($href->{'number'} . "$street$city$state" . 'US')) {
										return $rc;
									}
									if($county) {
										if($rc = $self->_get("$street$city$county$state" . 'US')) {
											return $rc;
										}
									}
									if($rc = $self->_get("$street$city$state" . 'US')) {
										return $rc;
									}
								}
							}
							return;	 # Not found
						}
						die $city;	# TODO: do something here
					} elsif($city =~ /^(\w[\w\s]+),\s*([\w\s]+)/) {
						# Perhaps it just has the street's name?
						# Rockville Pike, Rockville, MD, USA
						my $first = uc($1);
						my $second = uc($2);
						if($rc = $self->_get("$first$second$state" . 'US')) {
							return $rc;
						}
						# Perhaps it's a city in a county?
						# Silver Spring, Montgomery County, MD, USA
						$second =~ s/\s+COUNTY$//;
						if($rc = $self->_get("$first$second$state" . 'US')) {
							return $rc;
						}
						# Not all the database has the county
						if($rc = $self->_get("$first$state" . 'US')) {
							return $rc;
						}
					}
					# warn "Can't yet parse US location '$location'";
				}
			} elsif($c eq 'ca') {
				if(length($state) > 2) {
					if(my $twoletterstate = Locale::CA->new()->{province2code}{uc($state)}) {
						$state = $twoletterstate;
					}
				}
				my $rc;
				if($city !~ /,/) {
					# Simple case looking up a city in a state in Canada
					$city = uc($city);
					if($rc = $self->_get("$city$state" . 'CA')) {
						return $rc;
					}
				# } elsif(my $href = Geo::StreetAddress::Canada->parse_address("$city, $state")) {
				} elsif(my $href = 0) {
					# Well formed, simple street address in Canada
					$state = $href->{'province'};
					if(length($state) > 2) {
						if(my $twoletterstate = Locale::CA->new()->{province2code}{uc($state)}) {
							$state = $twoletterstate;
						}
					}
					my %args = (state => $state, country => 'CA');
					if($href->{city}) {
						$args{city} = uc($href->{city});
					}
					if($href->{number}) {
						$args{number} = $href->{number};
					}
					if($street = $href->{street}) {
						if(my $type = $self->_normalize($href->{'type'})) {
							$street .= " $type";
						}
						if($href->{suffix}) {
							$street .= ' ' . $href->{suffix};
						}
					}
					if($street) {
						if(my $prefix = $href->{prefix}) {
							$street = "$prefix $street";
						}
						$args{street} = uc($street);
					}
					warn "Fast lookup of Canadian location' $location' failed";
				} else {
					if($city =~ /^(\w[\w\s]+),\s*([\w\s]+)/) {
						# Perhaps it just has the street's name?
						# Rockville Pike, Rockville, MD, USA
						my $first = uc($1);
						my $second = uc($2);
						if($rc = $self->_get("$first$second$state" . 'CA')) {
							return $rc;
						}
						# Perhaps it's a city in a county?
						# Silver Spring, Montgomery County, MD, USA
						$second =~ s/\s+COUNTY$//;
						if($rc = $self->_get("$first$second$state" . 'CA')) {
							return $rc;
						}
						if($rc = $self->_get("$first$state" . 'CA')) {
							return $rc;
						}
					}
					# warn "Can't yet parse Canadian location '$location'";
				}
			} else {
				# Currently only handles Town, Region, Country
				# FIXME: add addresses support
				my $sc = Locale::SubCountry->new(uc($c));
				if(my $abbrev = $sc->code(ucfirst(lc($state)))) {
					if($abbrev ne 'unknown') {
						$state = $abbrev;
					}
				}
				if(my $rc = $self->_get("$city$state$c")) {
					return $rc;
				}
			}
		}
	} elsif($location =~ /([a-z\s]+),?\s*(United States|USA|US|Canada)$/i) {
		# Looking for a state/province in Canada or the US
		$state = $1;
		$country = $2;
		if($country =~ /Canada/i) {
			$country = 'CA';
			if(length($state) > 2) {
				if(my $twoletterstate = Locale::CA->new()->{province2code}{uc($state)}) {
					$state = $twoletterstate;
				}
			}
		} else {
			$country = 'US';
			if(length($state) > 2) {
				if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
					$state = $twoletterstate;
				}
			}
		}
		if(my $rc = $self->_get("$state$country")) {
			return $rc;
		}
	}
}

sub _search {
	my ($self, $data, @columns) = @_;

	my $location;
	foreach my $column(@columns) {
		if($data->{$column}) {
			$location .= $data->{$column};
		}
	}
	if($location) {
		return $self->_get($location);
	}
}

sub _get {
	my ($self, $location) = @_;

	$location =~ s/,\s*//g;
	my $digest = Digest::MD5::md5_base64(uc($location));
	if(my $cache = $self->{'cache'}) {
		if(my $rc = $cache->get_object($digest)) {
			return Storable::thaw($rc->value());
		}
	}
	my $openaddr_db = $self->{openaddr_db} ||
		Geo::Coder::Free::DB::openaddresses->new(
			directory => $self->{openaddr},
			cache => $self->{cache} || CHI->new(driver => 'Memory', datastore => {})
		);
	$self->{openaddr_db} = $openaddr_db;
	# print "$location: $digest\n";
	# ::diag("$location: $digest");
	# my @call_details = caller(0);
	# print "line " . $call_details[2], "\n";
	# print("$location: $digest\n");
	my $rc = $openaddr_db->fetchrow_hashref(md5 => $digest);
	if($rc && defined($rc->{'lat'})) {
		$rc->{'latitude'} = delete $rc->{'lat'};
		$rc->{'longitude'} = delete $rc->{'lon'};
		# ::diag(Data::Dumper->new([\$rc])->Dump());
		if(my $cache = $self->{'cache'}) {
			$cache->set($digest, Storable::freeze($rc), '1 week');
		}
			
		return $rc;
	}
}

sub _normalize {
	my ($self, $type) = @_;

	$type = uc($type);

	if(($type eq 'AVENUE') || ($type eq 'AVE')) {
		return 'AVE';
	} elsif(($type eq 'STREET') || ($type eq 'ST')) {
		return 'ST';
	} elsif(($type eq 'ROAD') || ($type eq 'RD')) {
		return 'RD';
	} elsif(($type eq 'COURT') || ($type eq 'CT')) {
		return 'COURT';
	} elsif(($type eq 'CIR') || ($type eq 'CIRCLE')) {
		return 'CIR';
	} elsif(($type eq 'FT') || ($type eq 'FORT')) {
		return 'FORT';
	} elsif(($type eq 'CTR') || ($type eq 'CENTER')) {
		return 'CENTER';
	} elsif($type eq 'BLVD') {
		return 'BLVD';
	} elsif($type eq 'PIKE') {
		return 'PIKE';
	}

	warn("Add type $type");
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

The contents of lib/Geo/Coder/Free/OpenAddresses/databases comes from
https://github.com/openaddresses/openaddresses/tree/master/us-data.

=head1 BUGS

Lots of lookups fail at the moment.

The openaddresses.io code has yet to be compeleted.
There are die()s where the code path has yet to be written.

The openaddresses data doesn't cover the globe.

Can't parse and handle "London, England".

Currently only searches US and Canadian data.

=head1 SEE ALSO

VWF, openaddresses.

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2018 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

=cut

1;
