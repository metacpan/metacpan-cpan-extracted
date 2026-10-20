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
use autodie qw(:all);

use Geo::Coder::Free::MissCache;
use Geo::Coder::Free::DB::MaxMind::admin1;
use Geo::Coder::Free::DB::MaxMind::admin2;
use Geo::Coder::Free::DB::MaxMind::cities;
use Geo::Coder::Free::Provenance qw(GEOCODER);
use Geo::Location::Predicate qw(_valid_location);
use Geo::Location::Point;
use Module::Info;
use Carp;
use File::Spec;
use Params::Get;
use Locale::CA;
use Locale::US;
use CHI;
use Locale::Country;
use Scalar::Util;

our %admin1cache;
our %admin2cache;     # name → region code (e.g. 'Kent' → 'P5')
our %admin2cache_rev; # region code → name (inverse; avoids O(N) scan in _prepare)

# Lazily-initialised Locale singletons — constructing Locale::US / Locale::CA
# on every geocode call for US/Canadian addresses was the top object-churn
# hotspot.  These are module-level my-variables (not exported) so they survive
# across object instances and avoid the construction cost after the first call.
my $_locale_us;
my $_locale_ca;

sub _prepare;

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

Version 0.48

=cut

our $VERSION = '0.48';

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
	my $args = Params::Get::get_params(undef, @_);

	if(!defined($class)) {
		# Geo::Coder::Free::Local->new not Geo::Coder::Free::Local::new
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %{$args} }, ref($class);
	}

	my $directory = $args->{'directory'} || Module::Info->new_from_loaded(__PACKAGE__)->file();
	$directory =~ s/\.pm$//;

	if(!-d $directory) {
		Carp::croak(ref($class), ": directory $directory doesn't exist");
	}

	Database::Abstraction::init({
		cache_duration => '1 day',
		%{$args},
		directory => File::Spec->catfile($directory, 'databases'),
		cache => $args->{'cache'} || CHI->new(driver => 'Memory', global => 1)
	});

	# Return the blessed object.  The directory is kept so that misses can be
	# remembered per data set: two installs, or two directories, do not share
	# an answer.
	return bless {
		cache => $args->{'cache'} || CHI->new(driver => 'Memory', global => 1),
		directory => $directory,
	}, $class;
}

=head2 reads

    my $count = $geocoder->reads();

How many times this backend has read its databases since the object was
created - a query on cities, admin1 or admin2.  A lookup answered without
reading anything - from the result cache, or from a hand-curated
C<%known_locations> entry - does not increase it.  C<geocode_many()> takes the
count before and after a value to tell a lookup that cost a read from one that
was answered from a cache.

=cut

sub reads {
	my $self = shift;

	return $self->{'reads'} // 0;
}

sub _read {
	my $self = shift;

	$self->{'reads'}++;
	return;
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

=head3 provenance

Every result carries C<geocoder>, C<database>, C<confidence> and C<accuracy>
(section 2.1 of F<BI-Phase6-Dependency-Specs.md>).  This backend reports
C<database> as C<MaxMind>.  C<accuracy> is C<city> when the row was chosen by
city name, C<region> when the lookup named only a region or a country - the row
is then the first match in that region, not a city the caller asked for - and
C<locality> for a hand-curated C<%known_locations> entry, whose coordinate is a
town's.

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

	# Fail when the input is just a set of numbers.  The rule is the one
	# Geo::Location::Predicate defines and the facade applies too, so what this
	# backend refuses cannot drift away from what valid_location() answers.
	if(!_valid_location($location)) {
		Carp::croak('Usage: ', __PACKAGE__, ": invalid input to geocode(), $location");
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
			'geocoder' => GEOCODER,
			'database' => 'MaxMind',
			# A hand-curated entry: the string matched it exactly, and the
			# coordinate it carries is a town's, not an address's.
			'confidence' => 1.0,
			'accuracy' => 'locality'
		});
	}

	return unless(($location =~ /,/) || $params{'region'});	# Not well formed, or an attempt to find the location of an entire country

	# Check cache first
	my $cached_result = $self->{'cache'}->get($location);
	return $cached_result if($cached_result);

	# A miss is remembered for the whole process.  The key is the location as
	# given (it is rewritten below into its component parts) together with the
	# region hint, which is part of what the lookup asks: a bare town name in
	# one region can be found where the same name in another is not.
	my $miss_scope = Geo::Coder::Free::MissCache->scope_for('MaxMind', $self->{'directory'} // '');
	my $miss_key = join("\0", $location, $params{'region'} // '');
	return if Geo::Coder::Free::MissCache->missed($miss_scope, $miss_key);

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
		Geo::Coder::Free::MissCache->remember($miss_scope, $miss_key);
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
		$region_only = 1;	# Will only return one match, not every match in the region
	} else {
		# Carp::croak(__PACKAGE__, ' only supports towns, not full addresses');
		Geo::Coder::Free::MissCache->remember($miss_scope, $miss_key);
		return;
	}
	my $countrycode;
	if($country) {
		if(defined($country) && (($country eq 'UK') || ($country eq 'United Kingdom') || ($country eq 'England'))) {
			$country = 'Great Britain';
			$concatenated_codes = 'GB';
		}
		$countrycode = country2code($country);
		# if($county && $countrycode) {
		# }

		if($state && $admin1cache{$state}) {
			$concatenated_codes = $admin1cache{$state};
		} elsif($admin1cache{$country} && !defined($state)) {
			$concatenated_codes = $admin1cache{$country};
		} else {
			$self->{'admin1'} //= Geo::Coder::Free::DB::MaxMind::admin1->new(no_entry => 1) or Carp::croak("Can't open the admin1 database");

			$self->_read();
			if(my $admin1 = $self->{'admin1'}->fetchrow_hashref(asciiname => $country)) {
				$concatenated_codes = $admin1->{'concatenated_codes'};
				$admin1cache{$country} = $concatenated_codes;
			} elsif($state) {
				$concatenated_codes = uc($countrycode);
				if($state =~ /^[A-Z]{2}$/) {
					$concatenated_codes .= ".$state";
				} else {
					$country_code = $concatenated_codes;
					$self->_read();
					my @admin1s = @{$self->{'admin1'}->selectall_hashref(asciiname => $state)};
					foreach my $admin1(@admin1s) {
						if($admin1->{'concatenated_codes'} =~ /^\Q$concatenated_codes\E\./i) {
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
	if(!defined($concatenated_codes)) {
		Geo::Coder::Free::MissCache->remember($miss_scope, $miss_key);
		return;
	}

	my @admin2s;
	my $region;
	my @regions;
	if($country =~ /^(United States|USA|US)$/) {
		if($county && (length($county) > 2)) {
			if(my $twoletterstate = ($_locale_us //= Locale::US->new())->{state2code}{uc($county)}) {
				$county = $twoletterstate;
			}
		}
		if($state && (length($state) > 2)) {
			if(my $twoletterstate = ($_locale_us //= Locale::US->new())->{state2code}{uc($state)}) {
				$state = $twoletterstate;
			}
		}
	} elsif(($country eq 'Canada') && $state && (length($state) > 2)) {
		if(($_locale_ca //= Locale::CA->new())->{province2code}{uc($state)}) {
			# FIXME:  I can't see that province locations are stored in cities.csv
			if(!defined($location)) {	# OK if searching for a city, that works
				Geo::Coder::Free::MissCache->remember($miss_scope, $miss_key);
				return;
			}
		}
	}

	$self->{'admin2'} //= Geo::Coder::Free::DB::MaxMind::admin2->new(no_entry => 1) or Carp::croak("Can't open the admin2 database");

	if(defined($county) && ($county =~ /^[A-Z]{2}$/) && ($country =~ /^(United States|USA|US)$/)) {
		# US state. Not Canadian province.
		$region = $county;
	} elsif($county && $admin1cache{$county}) {
		$region = $admin1cache{$county};
	} elsif($county && $admin2cache{$county}) {
		$region = $admin2cache{$county};
	} elsif(defined($state) && $admin2cache{$state} && !defined($county)) {
		$region = $admin2cache{$state};
	} else {
		if(defined($county) && ($county eq 'London')) {
			$self->_read();
			@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $location);
		} elsif(defined($county)) {
			$self->_read();
			@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $county);
		}
		foreach my $admin2(@admin2s) {
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
				$self->_read();
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
		$self->_read();
		@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $location);
		if((scalar(@admin2s) == 0) && ($country =~ /^(Canada|United States|USA|US)$/) && ($location !~ /\sCounty/i)) {
			$location .= ' County';
			$self->_read();
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
			# e.g. states in the US
			if(!defined($self->{'admin1'})) {
				$self->{'admin1'} = Geo::Coder::Free::DB::MaxMind::admin1->new(no_entry => 1) or Carp::croak("Can't open the admin1 database");
			}
			$self->_read();
			my @admin1s = $self->{'admin1'}->selectall_hash(asciiname => $county);
			foreach my $admin1(@admin1s) {
				if($admin1->{'concatenated_codes'} =~ /^\Q$concatenated_codes\E\./i) {
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
		$region =~ s/^.*\.//;    # keep only the rightmost dot-delimited component
		$options->{'Region'} = $region;
		if($country_code) {
			$options->{'Country'} = lc($country_code);
		}
		# If there's more than one match, don't cache as we don't
		# know which one will be matched later
		if(scalar(@admin2s) == 1) {
			if($state) {
				$admin2cache{$state}     = $region;
				$admin2cache_rev{$region} = $state;
			} elsif($county) {
				$admin2cache{$county}    = $region;
				$admin2cache_rev{$region} = $county;
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
	# This case nonsense is because DBD::CSV changes the columns to lowercase, whereas DBD::SQLite does not
	# if(wantarray && (!$options->{'City'}) && !$region_only) {
	# if(0) {	# We don't need to find all the cities in a state, which is what this would do
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
					# return;
				# }
			# }
		# }
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
	$self->_read();
	my $city = $self->{'cities'}->fetchrow_hashref($options);
	if(!defined($city)) {
		foreach $region(@regions) {
			$region =~ s/^.*\.//;    # keep only the rightmost dot-delimited component
			if($country =~ /^(United States|USA|US)$/) {
				next unless($region =~ /^[A-Z]{2}$/);	# In the US, the regions are the states
			}
			$options->{'Region'} = $region;
			$self->_read();
			$city = $self->{'cities'}->fetchrow_hashref($options);
			last if(defined($city));
		}
	}

	if(defined($city) && defined($city->{'Latitude'})) {
		# Cache and return result
		delete $city->{'Region'} if(defined($city->{'Region'}) && ($city->{'Region'} =~ /^[A-Z]\d$/));	# E.g. Region = G5
		delete $city->{'Population'} if(defined($city->{'Population'}) && (length($city->{'Population'}) == 0));
		my $rc = Geo::Location::Point->new({
			%{$city},
			('geocoder' => GEOCODER,
			 'database' => 'MaxMind',
			 'confidence' => $confidence,
			 # A row chosen for its city name is a city; one chosen by region or
			 # country alone is the first match in that region.
			 'accuracy' => $options->{'City'} ? 'city' : 'region')
		});
		$self->{cache}->set($location, $rc);
		return $rc;
	}
	# return $city;
	Geo::Coder::Free::MissCache->remember($miss_scope, $miss_key);
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

	# Validate coordinates before interpolating into SQL — prevents injection
	# if a caller passes a non-numeric latlng string.
	for my $c ($latitude, $longitude) {
		Carp::croak('Invalid coordinate value for reverse_geocode')
			unless defined($c) && $c =~ /^-?\d+\.?\d*$/;
	}

	if(wantarray) {
		$self->_read();
		my @locs = $self->{'cities'}->execute("SELECT * FROM cities WHERE ((ABS(Latitude - $latitude)) < 0.01) AND ((ABS(Longitude - $longitude)) < 0.01)");
		foreach my $loc(@locs) {
			$self->_prepare($loc);
		}
		return map { Geo::Location::Point->new($_)->as_string() } @locs;
	}

	# Performance: the former code issued 5 sequential SQL queries with ever-
	# widening radii (0.000001 → 0.01).  Replace with a single query that
	# orders by Manhattan distance and caps at the maximum radius (0.01°).
	# This eliminates 4 round-trips to SQLite on the common miss-until-last case.
	$self->_read();
	my $rc = $self->{'cities'}->execute(
		"SELECT * FROM cities" .
		" WHERE ABS(Latitude - $latitude) < 0.01 AND ABS(Longitude - $longitude) < 0.01" .
		" ORDER BY (ABS(Latitude - $latitude) + ABS(Longitude - $longitude)) ASC" .
		" LIMIT 1"
	);
	if($rc) {
		$self->_prepare($rc);
		return Geo::Location::Point->new($rc)->as_string();
	}
	return;
}

# Change 'Charing Cross, P5, Gb' to 'Charing Cross, London, Gb'
sub _prepare {
	my ($self, $loc) = @_;

	if(my $region = $loc->{'Region'}) {
		# O(1) reverse lookup — the former O(N) `while each %admin2cache` scan
		# walked the entire cache comparing values.  %admin2cache_rev is kept in
		# sync at every write site, giving a constant-time code→name translation.
		my $county = $admin2cache_rev{$region};
		if($county) {
			$loc->{'Region'} = $county;
		} else {
			$self->{'admin2'} //= Geo::Coder::Free::DB::MaxMind::admin2->new(no_entry => 1) or Carp::croak("Can't open the admin2 database");

			# Validate both tokens before interpolating into SQL.
			# $loc->{'Country'} is DB-sourced (ISO 3166-1 alpha-2 = two
			# uppercase letters) and $region is user-supplied.  Unvalidated
			# interpolation into a LIKE predicate would allow SQL injection.
			my $_country = uc($loc->{'Country'} // '');
			my $_reg     = uc($region // '');
			my $row;
			if($_country =~ /^[A-Z]{2}$/ && $_reg =~ /^[A-Z0-9]{1,10}$/) {
				$self->_read();
				$row = $self->{'admin2'}->execute("SELECT name FROM admin2 WHERE concatenated_codes LIKE '$_country.%.$_reg' LIMIT 1");
			}
			if(ref($row) && $row->{'name'}) {
				# Write to both forward and reverse caches in one go
				$admin2cache{$row->{'name'}}  = $region;
				$admin2cache_rev{$region}      = $row->{'name'};
				$loc->{'Region'}               = $row->{'name'};
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
