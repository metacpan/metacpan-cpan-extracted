package Geo::Coder::Free::MaxMind;

# sqlite3 cities.sql
#	select * from cities where City like '%north shields%';
# - note 'J5'
# grep 'GB.ENG.J5' admin2.db

# FIXME: If you search for something like "Sheppy, Kent, England" in list
#	context, it returns them all.  That's a lot! Should limit to, say
#	10 results (that number should be tuneable, and be a LIMIT in DB.pm)
#	And as the correct spelling in Sheppey, arguably it should return nothing

use strict;
use warnings;

use Geo::Coder::Free::DB::MaxMind::admin1;
use Geo::Coder::Free::DB::MaxMind::admin2;
use Geo::Coder::Free::DB::MaxMind::cities;
use Geo::Location::Point;
use Module::Info;
use Carp;
use File::Spec;
use Locale::CA;
use Locale::US;
use CHI;
use Locale::Country;
use Scalar::Util;

our %admin1cache;
our %admin2cache;	# e.g. maps 'Kent' => 'P5'

sub _prepare($$);

# Some locations aren't found because of inconsistencies in the way things are stored - these are some values I know
# FIXME: Should be in a configuration file
my %known_locations = (
	'Newport Pagnell, Buckinghamshire, England' => {
		'latitude' => 52.08675,
		'longitude' => -0.72270
	},
);

=head1 NAME

Geo::Coder::Free::MaxMind - Provides a geocoding functionality using the MaxMind and GeoNames databases

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

=head1 SYNOPSIS

    use Geo::Coder::Free::MaxMind;

    my $geocoder = Geo::Coder::Free::MaxMind->new();
    my $location = $geocoder->geocode(location => 'Ramsgate, Kent, UK');

=head1 DESCRIPTION

Geo::Coder::Free::MaxMind provides an interface to free databases.

Refer to the source URL for licencing information for these files:
cities.csv is from L<https://www.maxmind.com/en/free-world-cities-database>;
admin1.db is from L<http://download.geonames.org/export/dump/admin1CodesASCII.txt>;
admin2.db is from L<http://download.geonames.org/export/dump/admin2Codes.txt>;

See also L<http://download.geonames.org/export/dump/allCountries.zip>

To significantly speed this up,
gunzip cities.csv and run it through the db2sql script to create an SQLite file.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Free::MaxMind->new();

Takes one optional parameter, directory,
which tells the library where to find the files admin1db, admin2.db and cities.[sql|csv.gz].
If that parameter isn't given, the module will attempt to find the databases, but that can't be guaranteed

There are 3 levels to the Maxmind database.
Here's the method to find the location of Sittingbourne, Kent, England:
1) admin1.db contains admin areas such as counties, states and provinces
   A typical line is:
     US.MD	Maryland	Maryland	4361885
   So a look-up of 'Maryland' will get the concatenated code 'US.MD'
   Note that GB has England, Scotland and Wales at this level, not the counties
     GB.ENG	England	England	6269131
   So a look-up of England will give the concatenated code of GB.ENG for use in admin2.db
2) admin2.db contains admin areas drilled down from the admin1 database such as US counties
   Note that GB has counties
   A typical line is:
    GB.ENG.G5	Kent	Kent	3333158
   So a look-up of 'Kent' with a concatenated code to start with 'GB.ENG' will code the region G5 for use in cities.sql
3) cities.sql contains the latitude and longitude of the place we want, so a search for 'sittingbourne' in the
   region 'g5' will give
     gb,sittingbourne,Sittingbourne,G5,41148,51.333333,.75

The admin2.db is far from comprehensive, see Makefile.PL for some entries that are added manually.

=cut

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if(!defined($class)) {
		# Geo::Coder::Free::Local->new not Geo::Coder::Free::Local::new
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %args }, ref($class);
	}

	my $directory = $args{'directory'} || Module::Info->new_from_loaded(__PACKAGE__)->file();
	$directory =~ s/\.pm$//;

	if(!-d $directory) {
		Carp::croak(ref($class), ": directory $directory doesn't exist");
	}

	Database::Abstraction::init({
		cache_duration => '1 day',
		%args,
		directory => File::Spec->catfile($directory, 'databases'),
		cache => $args{cache} || CHI->new(driver => 'Memory', global => 1)
	});

	# Return the blessed object
	return bless {
		cache => $args{cache} || CHI->new(driver => 'Memory', global => 1),
	}, $class;
}

=head2 geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

    # TODO:
    # @locations = $geocoder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

    # This will return one place in New Brunwsick, not them all
    # TODO: Arguably it should get them all from the database (or at least say the first 100) and return the central location
    my @locations = $geocoder->geocode({ location => 'New Brunswick, Canada' });
    die if(scalar(@locations) != 1);

=cut

sub geocode {
	my $self = shift;
	my %params;

	# Try hard to support whatever API that the user wants to use
	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->geocode(@_));
		} elsif(!defined($self)) {
			# Geo::Coder::Free->geocode()
			Carp::croak('Usage: ', __PACKAGE__, '::geocode(location => $location|scantext => $text)');
		} elsif($self eq __PACKAGE__) {
			Carp::croak("Usage: $self", '::geocode(location => $location|scantext => $text)');
		}
		return(__PACKAGE__->new()->geocode($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->geocode($self));
	} elsif(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	# } elsif(ref($_[0]) && (ref($_[0] !~ /::/))) {
	} elsif(ref($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '::geocode(location => $location|scantext => $text)');
	} elsif(scalar(@_) && (scalar(@_) % 2 == 0)) {
		%params = @_;
	} else {
		$params{'location'} = shift;
	}

	my $location = $params{location}
		or Carp::croak('Usage: geocode(location => $location)');

	# Fail when the input is just a set of numbers
	if($location !~ /\D/) {
		Carp::croak('Usage: ', __PACKAGE__, ": invalid input to geocode(), $location");
		return;
	}

	if($location =~ /^(.+),\s*Washington\s*DC,(.+)$/) {
		$location = "$1, Washington, DC, $2";
	}

	if(my $rc = $known_locations{$location}) {
		# return $known_locations{$location};
		return Geo::Location::Point->new({
			'lat' => $rc->{'latitude'},
			'long' => $rc->{'longitude'},
			'lon' => $rc->{'longitude'},
			'lng' => $rc->{'longitude'},
			'location' => $location,
			'database' => 'MaxMind'
		});
	}

	# ::diag(__LINE__, ": $location");
	return unless(($location =~ /,/) || $params{'region'});	# Not well formed, or an attempt to find the location of an entire country

	# Check cache first
	my $cached_result = $self->{'cache'}->get($location);
	return $cached_result if($cached_result);

	my $county;
	my $state;
	my $country;
	my $country_code;
	my $concatenated_codes;
	my $region_only;

	if($location =~ /^([\w\s\-]+),([\w\s]+),([\w\s]+)?$/) {
		# Turn 'Ramsgate, Kent, UK' into 'Ramsgate'
		$location = $1;
		$county = $2;
		$country = $3;
		$location =~ s/\-/ /g;
		$county =~ s/^\s//g;
		$county =~ s/\s$//g;
		$country =~ s/^\s//g;
		$country =~ s/\s$//g;
		if($location =~ /^St\.? (.+)/) {
			$location = "Saint $1";
		}
		if(($country =~ /^(Canada|United States|USA|US)$/)) {
			$state = $county;
			$county = undef;
		}
	} elsif($location =~ /^([\w\s\-]+),([\w\s]+),([\w\s]+),\s*(Canada|United States|USA|US)?$/) {
		$location = $1;
		$county = $2;
		$state = $3;
		$country = $4;
		$county =~ s/^\s//g;
		$county =~ s/\s$//g;
		$state =~ s/^\s//g;
		$state =~ s/\s$//g;
		# $country =~ s/^\s//g;
		$country =~ s/\s$//g;
	} elsif($location =~ /^[\w\s-],[\w\s-]/) {
		Carp::carp(__PACKAGE__, ": can't parse and handle $location");
		return;
	} elsif(($location =~ /^[\w\s-]+$/) && (my $region = $params{'region'})) {
		$location =~ s/^\s//g;
		$location =~ s/\s$//g;
		$country = uc($region);
	} elsif($location =~ /^([\w\s-]+),\s*(\w+)$/) {
		# e.g. a county in the UK or a state in the US
		$county = $1;
		$country = $2;
		$county =~ s/^\s//g;
		$county =~ s/\s$//g;
		# $country =~ s/^\s//g;
		$country =~ s/\s$//g;
		# ::diag(__LINE__, "$county, $country");
		$region_only = 1;	# Will only return one match, not every match in the region
	} else {
		# Carp::croak(__PACKAGE__, ' only supports towns, not full addresses');
		return;
	}
	my $countrycode;
	if($country) {
		if(defined($country) && (($country eq 'UK') || ($country eq 'United Kingdom') || ($country eq 'England'))) {
			$country = 'Great Britain';
			$concatenated_codes = 'GB';
		}
		$countrycode = country2code($country);
		# ::diag(__LINE__, ": country $countrycode, county $county, state $state, location $location");
		# if($county && $countrycode) {
			# ::diag(__LINE__, ": country $countrycode, county $county, location $location");
		# }

		if($state && $admin1cache{$state}) {
			$concatenated_codes = $admin1cache{$state};
		} elsif($admin1cache{$country} && !defined($state)) {
			$concatenated_codes = $admin1cache{$country};
		} else {
			$self->{'admin1'} //= Geo::Coder::Free::DB::MaxMind::admin1->new(no_entry => 1) or die "Can't open the admin1 database";

			if(my $admin1 = $self->{'admin1'}->fetchrow_hashref(asciiname => $country)) {
				$concatenated_codes = $admin1->{'concatenated_codes'};
				$admin1cache{$country} = $concatenated_codes;
			} elsif($state) {
				$concatenated_codes = uc($countrycode);
				if($state =~ /^[A-Z]{2}$/) {
					$concatenated_codes .= ".$state";
				} else {
					$country_code = $concatenated_codes;
					my @admin1s = @{$self->{'admin1'}->selectall_hashref(asciiname => $state)};
					foreach my $admin1(@admin1s) {
						if($admin1->{'concatenated_codes'} =~ /^$concatenated_codes\./i) {
							$concatenated_codes = $admin1->{'concatenated_codes'};
							last;
						}
					}
				}
				$admin1cache{$state} = $concatenated_codes;
			} elsif($countrycode) {
				$concatenated_codes = uc($countrycode);
				$admin1cache{$country} = $concatenated_codes;
			} elsif(Locale::Country::code2country($country)) {
				$concatenated_codes = uc($country);
				$admin1cache{$country} = $concatenated_codes;
			}
		}
	}
	return unless(defined($concatenated_codes));
	# ::diag(__LINE__, ": $concatenated_codes");

	my @admin2s;
	my $region;
	my @regions;
	# ::diag(__LINE__, ": $country");
	if($country =~ /^(United States|USA|US)$/) {
		if($county && (length($county) > 2)) {
			if(my $twoletterstate = Locale::US->new()->{state2code}{uc($county)}) {
				$county = $twoletterstate;
			}
			# ::diag(__LINE__, ": $location, $county, $country");
		}
		if($state && (length($state) > 2)) {
			if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
				$state = $twoletterstate;
			}
			# ::diag(__LINE__, ": $location, $state, $country");
		}
	} elsif(($country eq 'Canada') && $state && (length($state) > 2)) {
		# ::diag(__LINE__, ": $state");
		if(Locale::CA->new()->{province2code}{uc($state)}) {
			# FIXME:  I can't see that province locations are stored in cities.csv
			return unless(defined($location));	# OK if searching for a city, that works
		}
	}

	$self->{'admin2'} //= Geo::Coder::Free::DB::MaxMind::admin2->new(no_entry => 1) or die "Can't open the admin2 database";

	if(defined($county) && ($county =~ /^[A-Z]{2}$/) && ($country =~ /^(United States|USA|US)$/)) {
		# US state. Not Canadian province.
		$region = $county;
	} elsif($county && $admin1cache{$county}) {
		# ::diag(__LINE__);
		$region = $admin1cache{$county};
	} elsif($county && $admin2cache{$county}) {
		$region = $admin2cache{$county};
		# ::diag(__LINE__, ": $county");
	} elsif(defined($state) && $admin2cache{$state} && !defined($county)) {
		# ::diag(__LINE__);
		$region = $admin2cache{$state};
	} else {
		# ::diag(__PACKAGE__, ': ', __LINE__);
		if(defined($county) && ($county eq 'London')) {
			@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $location);
		} elsif(defined($county)) {
			# ::diag(__PACKAGE__, ': ', __LINE__, ": $county");
			@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $county);
		}
		# ::diag(__LINE__, Data::Dumper->new([\@admin2s])->Dump());
		foreach my $admin2(@admin2s) {
			# ::diag(__LINE__, Data::Dumper->new([$admin2])->Dump());
			if($admin2->{'concatenated_codes'} =~ $concatenated_codes) {
				$region = $admin2->{'concatenated_codes'};
				if($region =~ /^[A-Z]{2}\.([A-Z]{2})\./) {
					my $rc = $1;
					if(defined($state) && ($state =~ /^[A-Z]{2}$/)) {
						if($state eq $rc) {
							$region = $rc;
							@regions = ();
							last;
						}
					} else {
						push @regions, $region;
						push @regions, $rc;
					}
				} else {
					push @regions, $region;
				}
			}
		}
		if($state && !defined($region)) {
			if($state =~ /^[A-Z]{2}$/) {
				$region = $state;
				@regions = ();
			} else {
				@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $state);
				foreach my $admin2(@admin2s) {
					if($admin2->{'concatenated_codes'} =~ $concatenated_codes) {
						$region = $admin2->{'concatenated_codes'};
						last;
					}
				}
			}
		}
	}

	if((scalar(@regions) == 0) && !defined($region)) {
		# e.g. Unitary authorities in the UK
		# admin[12].db columns are labelled ['concatenated_codes', 'name', 'asciiname', 'geonameId']
		# ::diag(__PACKAGE__, ': ', __LINE__, ": $location");
		@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $location);
		if((scalar(@admin2s) == 0) && ($country =~ /^(Canada|United States|USA|US)$/) && ($location !~ /\sCounty/i)) {
			$location .= ' County';
			# ::diag(__PACKAGE__, ': ', __LINE__, ": $location");
			@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $location);
		}
		if(scalar(@admin2s) && defined($admin2s[0]->{'concatenated_codes'})) {
			foreach my $admin2(@admin2s) {
				my $concat = $admin2->{'concatenated_codes'};
				if($concat =~ /^CA\.(\d\d)\./) {
					# Canadian provinces are not stored in the same way as US states
					$region = $1;
					last;
				} elsif($concat =~ $concatenated_codes) {
					$region = $concat;
					last;
				}
			}
		} elsif(defined($county)) {
			# ::diag(__PACKAGE__, ': ', __LINE__, ": county $county");
			# e.g. states in the US
			if(!defined($self->{'admin1'})) {
				$self->{'admin1'} = Geo::Coder::Free::DB::MaxMind::admin1->new(no_entry => 1) or die "Can't open the admin1 database";
			}
			my @admin1s = $self->{'admin1'}->selectall_hash(asciiname => $county);
			foreach my $admin1(@admin1s) {
				# ::diag(__LINE__, Data::Dumper->new([$admin1])->Dump());
				if($admin1->{'concatenated_codes'} =~ /^$concatenated_codes\./i) {
					$region = $admin1->{'concatenated_codes'};
					if(scalar(@admin1s) == 1) {
						$admin1cache{$county} = $region;
					}
					last;
				}
			}
		}
	}

	if(!defined($self->{'cities'})) {
		$self->{'cities'} = Geo::Coder::Free::DB::MaxMind::cities->new(
			cache => $self->{cache} || CHI->new(driver => 'Memory', datastore => {}),
			no_entry => 1,
		);
	}

	my $options;
	if(defined($county) && ($county =~ /^[A-Z]{2}$/) && ($country =~ /^(United States|USA|US)$/)) {
		$options = { Country => 'us' };
	} else {
		if($region_only) {
			$options = {};
		} else {
			$options = { City => lc($location) };
			$options->{'City'} =~ s/,\s*\w+$//;
		}
	}
	if($region) {
		if($region =~ /^.+\.(.+)$/) {
			$region = $1;
		}
		$options->{'Region'} = $region;
		if($country_code) {
			$options->{'Country'} = lc($country_code);
		}
		# If there's more than one match, don't cache as we don't
		# know which one will be matched later
		if(scalar(@admin2s) == 1) {
			if($state) {
				$admin2cache{$state} = $region;
			} elsif($county) {
				$admin2cache{$county} = $region;
			}
		}
	}

	my $confidence = 0.5;
	if(my $c = $params{'region'}) {
		$options->{'Country'} = lc($c);
		$confidence = 0.1;
	} elsif($countrycode) {
		$options->{'Country'} = $countrycode;
		$confidence = 0.1;
	}
	# ::diag(__PACKAGE__, ': ', __LINE__, ': ', Data::Dumper->new([$options])->Dump());
	# This case nonsense is because DBD::CSV changes the columns to lowercase, whereas DBD::SQLite does not
	# if(wantarray && (!$options->{'City'}) && !$region_only) {
	# if(0) {	# We don't need to find all the cities in a state, which is what this would do
		# # ::diag(__PACKAGE__, ': ', __LINE__);
		# my @rc = $self->{'cities'}->selectall_hash($options);
		# if(scalar(@rc) == 0) {
			# if((!defined($region)) && !defined($params{'region'})) {
				# # Add code for this area to Makefile.PL and rebuild
				# Carp::carp(__PACKAGE__, ": didn't determine region from $location");
				# return;
			# }
			# # This would return all of the cities in the wrong region
			# if($countrycode) {
				# @rc = $self->{'cities'}->selectall_hash('Region' => ($region || $params{'region'}), 'Country' => $countrycode);
				# if(scalar(@rc) == 0) {
					# # ::diag(__PACKAGE__, ': ', __LINE__, ': no matches: ', Data::Dumper->new([$options])->Dump());
					# return;
				# }
			# }
			# # ::diag(__LINE__, ': ', Data::Dumper->new([\@rc])->Dump());
		# }
		# # ::diag(__LINE__, ': ', Data::Dumper->new([\@rc])->Dump());
		# foreach my $city(@rc) {
			# if($city->{'Latitude'}) {
				# $city->{'latitude'} = delete $city->{'Latitude'};
				# $city->{'longitude'} = delete $city->{'Longitude'};
			# }
			# if($city->{'Country'}) {
				# $city->{'country'} = uc(delete $city->{'Country'});
			# }
			# if($city->{'Region'}) {
				# $city->{'state'} = uc(delete $city->{'Region'});
			# }
			# if($city->{'City'}) {
				# $city->{'city'} = uc(delete $city->{'AccentCity'});
				# delete $city->{'City'};
				# # Less likely to get false positives with long words
				# if(length($city->{'city'}) > 10) {
					# if($confidence <= 0.8) {
						# $confidence += 0.2;
					# } else {
						# $confidence = 1.0;
					# }
				# }
			# }
			# $city->{'confidence'} = $confidence;
			# my $l = $options->{'City'};
			# if($options->{'Region'}) {
				# $l .= ', ' . $options->{'Region'};
			# }
			# if($options->{'Country'}) {
				# $l .= ', ' . ucfirst($options->{'Country'});
			# }
			# $city->{'location'} = $l;
		# }
		# # return @rc;
		# my @locations;
		#
		# foreach my $l(@rc) {
			# if(exists($l->{'latitude'})) {
				# push @locations, Geo::Location::Point->new({
					# 'lat' => $l->{'latitude'},
					# 'long' => $l->{'longitude'},
					# 'lon' => $l->{'longitude'},
					# 'location' => $location,
					# 'database' => 'MaxMind',
					# 'maxmind' => $l,
				# });
			# # } else {
				# # Carp::carp(__PACKAGE__, ": $location has latitude of 0");
				# # return;
			# }
		# }
		#
		# return @locations;
	# }
	# ::diag(__PACKAGE__, ': ', __LINE__, ': ', Data::Dumper->new([$options])->Dump());
	my $city = $self->{'cities'}->fetchrow_hashref($options);
	if(!defined($city)) {
		# ::diag(__LINE__, ': ', scalar(@regions));
		foreach $region(@regions) {
			if($region =~ /^.+\.(.+)$/) {
				$region = $1;
			}
			if($country =~ /^(United States|USA|US)$/) {
				next unless($region =~ /^[A-Z]{2}$/);	# In the US, the regions are the states
			}
			$options->{'Region'} = $region;
			$city = $self->{'cities'}->fetchrow_hashref($options);
			last if(defined($city));
		}
	}

	# ::diag(__LINE__, ': ', Data::Dumper->new([$city])->Dump());
	if(defined($city) && defined($city->{'Latitude'})) {
		# Cache and return result
		delete $city->{'Region'} if(defined($city->{'Region'}) && ($city->{'Region'} =~ /^[A-Z]\d$/));	# E.g. Region = G5
		delete $city->{'Population'} if(defined($city->{'Population'}) && (length($city->{'Population'}) == 0));
		my $rc = Geo::Location::Point->new({
			%{$city},
			('database' => 'MaxMind', 'confidence' => $confidence)
		});
		$self->{cache}->set($location, $rc);
		return $rc;
	}
	# return $city;
	return;
}

=head2	reverse_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

Returns a string, or undef if it can't be found.

=cut

sub reverse_geocode
{
	my $self = shift;
	my %params;

	# Try hard to support whatever API that the user wants to use
	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->reverse_geocode(@_));
		} elsif(!defined($self)) {
			# Geo::Coder::Free->reverse_geocode()
			Carp::croak('Usage: ', __PACKAGE__, '::reverse_geocode(latlng => "$lat,$long")');
		} elsif($self eq __PACKAGE__) {
			Carp::croak("Usage: $self", '::reverse_geocode(latlng => "$lat,$long")');
		}
		return(__PACKAGE__->new()->reverse_geocode($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->reverse_geocode($self));
	} elsif(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	# } elsif(ref($_[0]) && (ref($_[0] !~ /::/))) {
	} elsif(ref($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '::reverse_geocode(latlng => "$lat,$long")');
	} elsif(scalar(@_) && (scalar(@_) % 2 == 0)) {
		%params = @_;
	} else {
		$params{'latlng'} = shift;
	}

	my $latlng = $params{'latlng'};

	my $latitude;
	my $longitude;

	if($latlng) {
		($latitude, $longitude) = split(/,/, $latlng);
	} else {
		$latitude //= $params{'lat'};
		$longitude //= $params{'lon'};
		$longitude //= $params{'long'};
	}

	if((!defined($latitude)) || !defined($longitude)) {
		Carp::croak('Usage: ', __PACKAGE__, '::reverse_geocode(latlng => "$lat,$long")');
	}

	if(!defined($self->{'cities'})) {
		$self->{'cities'} = Geo::Coder::Free::DB::MaxMind::cities->new(
			cache => $self->{cache} || CHI->new(driver => 'Memory', datastore => {}),
			no_entry => 1,
		);
	}

	if(wantarray) {
		my @locs = $self->{'cities'}->execute("SELECT * FROM cities WHERE ((ABS(Latitude - $latitude)) < 0.01) AND ((ABS(Longitude - $longitude)) < 0.01)");
		foreach my $loc(@locs) {
			$self->_prepare($loc);
		}
		return map { Geo::Location::Point->new($_)->as_string() } @locs;
	}
	# Try close in then zoom out, to a reasonable limit
	foreach my $radius(0.000001, 0.00001, 0.0001, 0.001, 0.01) {
		if(my $rc = $self->{'cities'}->execute("SELECT * FROM cities WHERE ((ABS(Latitude - $latitude)) < $radius) AND ((ABS(Longitude - $longitude)) < $radius) LIMIT 1")) {
			$self->_prepare($rc);
			return Geo::Location::Point->new($rc)->as_string();
		}
	}
	return;
}

# Change 'Charing Cross, P5, Gb' to 'Charing Cross, London, Gb'
sub _prepare($$) {
	my ($self, $loc) = @_;

	if(my $region = $loc->{'Region'}) {
		my $county;

		# Check if region is already cached in admin2cache
		while(my ($key, $value) = each %admin2cache) {
			if($value eq $region) {
				$county = $key;
				last;
			}
		}
		if($county) {
			$loc->{'Region'} = $county;
		} else {
			# Initialize admin2 object if not already initialized
			$self->{'admin2'} //= Geo::Coder::Free::DB::MaxMind::admin2->new(no_entry => 1) or die "Can't open the admin2 database";

			# Prepare and execute SQL query

			my $row = $self->{'admin2'}->execute("SELECT name FROM admin2 WHERE concatenated_codes LIKE '" . uc($loc->{'Country'}) . '.%.' . uc($region) . "' LIMIT 1");
			if(ref($row) && $row->{'name'}) {
				# Cache the result for future calls and update the location's region
				$admin2cache{$row->{'name'}} = $region;
				$loc->{'Region'} = $row->{'name'};
			}
		}
	}
}

=head2	ua

Does nothing, here for compatibility with other geocoders

=cut

sub ua {
}

=head1 AUTHOR

Nigel Horne, C<< <njh@bandsman.co.uk> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Lots of lookups fail at the moment.

The MaxMind data only contains cities.

Can't parse and handle "London, England".

The database contains Canadian cities, but not provinces, so a search for "New Brunswick, Canada" won't work

The GeoNames admin databases are in this class, they should be in Geo::Coder::GeoNames.

The data at
L<https://github.com/apache/commons-csv/blob/master/src/test/resources/org/apache/commons/csv/perf/worldcitiespop.txt.gz?raw=true>
are 7 years out of date,
and are inconsistent with the Geonames database.

If you search for something like "Sheppy, Kent, England" in list context,
it returns them all.
That's a lot!
It should be limited to,
say 10 results (that number should be tuneable, and be a LIMIT in DB.pm),
and as the correct spelling in Sheppey, arguably it should return nothing.

=head1 SEE ALSO

VWF, MaxMind and geonames.

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

This product includes GeoLite2 data created by MaxMind, available from
L<https://www.maxmind.com/en/home>.
(Note that this currently gives a 403 error - I need to find the latest URL).

=cut

1;
