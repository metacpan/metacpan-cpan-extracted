package Geo::Coder::Free::MaxMind;

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

our %admin1cache;
our %admin2cache;	# e.g. maps 'Kent' => 'P5'

# Some locations aren't found because of inconsistencies in the way things are stored - these are some values I know
# FIXME: Should be in a configuration file
my %known_locations = (
	'Newport Pagnell, Buckinghamshire, England' => {
		'latitude' => 52.08675,
		'longitude' => -0.72270
	},
);

=head1 NAME

Geo::Coder::Free::Maxmind - Provides a geocoding functionality using the MaxMind and GeoNames databases

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

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

=cut

sub new {
	my($proto, %param) = @_;
	my $class = ref($proto) || $proto;

	# Geo::Coder::Free->new not Geo::Coder::Free::new
	return unless($class);

	# Geo::Coder::Free::DB::init(directory => 'lib/Geo/Coder/Free/databases');

	my $directory = $param{'directory'} || Module::Info->new_from_loaded(__PACKAGE__)->file();
	$directory =~ s/\.pm$//;

	Geo::Coder::Free::DB::init({
		directory => File::Spec->catfile($directory, 'databases'),
		cache => $param{cache} || CHI->new(driver => 'Memory', datastore => {})
	});

	return bless { }, $class;
}

=head2 geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

    # TODO:
    # @locations = $geocoder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

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

	if($location =~ /^(.+),\s*Washington\s*DC,(.+)$/) {
		$location = "$1, Washington, DC, $2";
	}

	if(my $rc = $known_locations{$location}) {
		# return $known_locations{$location};
		return Geo::Location::Point->new({
			'lat' => $rc->{'latitude'},
			'long' => $rc->{'longitude'},
			'location' => $location,
			'database' => 'Maxmind'
		});
	}

	# ::diag(__LINE__, ": $location");
	return unless(($location =~ /,/) || $param{'region'});	# Not well formed, or an attempt to find the location of an entire country

	my $county;
	my $state;
	my $country;
	my $country_code;
	my $concatenated_codes;
	my ($first, $second, $third);

	if($location =~ /^([\w\s\-]+),([\w\s]+),([\w\s]+)?$/) {
		# Turn 'Ramsgate, Kent, UK' into 'Ramsgate'
		$first = $location = $1;
		$second = $county = $2;
		$third = $country = $3;
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
	} elsif(($location =~ /^[\w\s-]+$/) && (my $region = $param{'region'})) {
		$location =~ s/^\s//g;
		$location =~ s/\s$//g;
		$country = uc($region);
	} elsif($location =~ /^([\w\s-]+),\s*(\w+)$/) {
	# } elsif(0) {
		$county = $1;
		$country = $2;
		$county =~ s/^\s//g;
		$county =~ s/\s$//g;
		# $country =~ s/^\s//g;
		$country =~ s/\s$//g;
	} else {
		# Carp::croak(__PACKAGE__, ' only supports towns, not full addresses');
		return;
	}
	if($country) {
		if(defined($country) && (($country eq 'UK') || ($country eq 'United Kingdom') || ($country eq 'England'))) {
			$country = 'Great Britain';
			$concatenated_codes = 'GB';
		}
		my $countrycode = country2code($country);
		# ::diag(__LINE__, ": country $countrycode, county $county, state $state, location $location");
		# if($county && $countrycode) {
			# ::diag(__LINE__, ": country $countrycode, county $county, location $location");
		# }

		if($state && $admin1cache{$state}) {
			$concatenated_codes = $admin1cache{$state};
		} elsif($admin1cache{$country} && !defined($state)) {
			$concatenated_codes = $admin1cache{$country};
		} else {
			$self->{'admin1'} //= Geo::Coder::Free::DB::MaxMind::admin1->new() or die "Can't open the admin1 database";

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
	if(($country =~ /^(United States|USA|US)$/) && $county && (length($county) > 2)) {
		if(my $twoletterstate = Locale::US->new()->{state2code}{uc($county)}) {
			$county = $twoletterstate;
		}
	} elsif(($country eq 'Canada') && (length($state) > 2)) {
		# ::diag(__LINE__, ": $county");
		if(my $twoletterstate = Locale::CA->new()->{province2code}{uc($state)}) {
			# FIXME:  I can't see that province locations are stored in cities.csv
			return unless(defined($location));	# OK if searching for a city, that works
			# $state = $twoletterstate;
		}
	}

	$self->{'admin2'} //= Geo::Coder::Free::DB::MaxMind::admin2->new() or die "Can't open the admin2 database";

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
		# ::diag(__LINE__);
		if(defined($county) && ($county eq 'London')) {
			@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $location);
		} else {
		# ::diag(__LINE__, ": $county");
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
		# ::diag(__LINE__, ": $location");
		@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $location);
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
		} else {
			# e.g. states in the US
			if(!defined($self->{'admin1'})) {
				$self->{'admin1'} = Geo::Coder::Free::DB::MaxMind::admin1->new() or die "Can't open the admin1 database";
			}
			my @admin1s = $self->{'admin1'}->selectall_hash(asciiname => $county);
			foreach my $admin1(@admin1s) {
				# ::diag(__LINE__, Data::Dumper->new([$admin1])->Dump());
				if($admin1->{'concatenated_codes'} =~ /^$concatenated_codes\./i) {
					$region = $admin1->{'concatenated_codes'};
					$admin1cache{$county} = $region;
					last;
				}
			}
		}
	}

	if(!defined($self->{'cities'})) {
		$self->{'cities'} = Geo::Coder::Free::DB::MaxMind::cities->new(
			cache => $self->{cache} || CHI->new(driver => 'Memory', datastore => {}));
	}

	my $options;
	if(defined($county) && ($county =~ /^[A-Z]{2}$/) && ($country =~ /^(United States|USA|US)$/)) {
		$options = {};
	} else {
		$options = { City => lc($location) };
		$options->{'City'} =~ s/,\s*\w+$//;
	}
	if($region) {
		if($region =~ /^.+\.(.+)$/) {
			$region = $1;
		}
		$options->{'Region'} = $region;
		if($country_code) {
			$options->{'Country'} = lc($country_code);
		}
		if($state) {
			$admin2cache{$state} = $region;
		} elsif($county) {
			$admin2cache{$county} = $region;
		}
	}

	my $confidence = 0.5;
	if(my $c = $param{'region'}) {
		$options->{'Country'} = lc($c);
		$confidence = 0.1;
	}
	# ::diag(__LINE__, ': ', Data::Dumper->new([$options])->Dump());
	# This case nonsense is because DBD::CSV changes the columns to lowercase, wherease DBD::SQLite does not
	if(wantarray) {
		my @rc = $self->{'cities'}->selectall_hash($options);
		if(scalar(@rc) == 0) {
			@rc = $self->{'cities'}->selectall_hash('Region' => $options->{'Region'});
			if(scalar(@rc) == 0) {
	 			# ::diag(__LINE__, ': no matches: ', Data::Dumper->new([$options])->Dump());
				return;
			}
		}
	 	# ::diag(__LINE__, ': ', Data::Dumper->new([\@rc])->Dump());
		foreach my $city(@rc) {
			if($city->{'Latitude'}) {
				$city->{'latitude'} = delete $city->{'Latitude'};
				$city->{'longitude'} = delete $city->{'Longitude'};
			}
			if($city->{'Country'}) {
				$city->{'country'} = uc(delete $city->{'Country'});
			}
			if($city->{'Region'}) {
				$city->{'state'} = uc(delete $city->{'Region'});
			}
			if($city->{'City'}) {
				$city->{'city'} = uc(delete $city->{'City'});
				# Less likely to get false positives with long words
				if(length($city->{'city'}) > 10) {
					if($confidence <= 0.8) {
						$confidence += 0.2;
					} else {
						$confidence = 1.0;
					}
				}
			}
			$city->{'confidence'} = $confidence;
			my $l = $options->{'City'};
			if($options->{'Region'}) {
				$l .= ', ' . $options->{'Region'};
			}
			if($options->{'Country'}) {
				$l .= ', ' . ucfirst($options->{'Country'});
			}
			$city->{'location'} = $l;
		}
		# return @rc;
		my @locations;

		foreach my $l(@rc) {
			push @locations, Geo::Location::Point->new({
				'lat' => $l->{'latitude'},
				'long' => $l->{'longitude'},
				'location' => $location,
				'database' => 'Maxmind'
			});
		}

		return @locations;
	}
	# ::diag(__LINE__, ': ', Data::Dumper->new([$options])->Dump());
	my $city = $self->{'cities'}->fetchrow_hashref($options);
	if(!defined($city)) {
		# ::diag(__LINE__, ': ', scalar(@regions));
		foreach $region(@regions) {
			if($region =~ /^.+\.(.+)$/) {
				$region = $1;
			}
			if($country =~ /^(Canada|United States|USA|US)$/) {
				next unless($region =~ /^[A-Z]{2}$/);
			}
			$options->{'Region'} = $region;
			$city = $self->{'cities'}->fetchrow_hashref($options);
			last if(defined($city));
		}
	}

	# ::diag(__LINE__, ': ', Data::Dumper->new([$city])->Dump());
	if(defined($city) && defined($city->{'Latitude'})) {
		$city->{'confidence'} = $confidence;
		return Geo::Location::Point->new($city);
	}
	# return $city;
	return;
}

=head2	reverse_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

Returns a string, or undef if it can't be found.

=cut

sub reverse_geocode {
	my $self = shift;

	my %param;
	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: reverse_geocode(latlng => $location)');
	} elsif(@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{'latlng'} = shift;
	}

	my $latlng = $param{'latlng'};

	my $latitude;
	my $longitude;

	if($latlng) {
		($latitude, $longitude) = split(/,/, $latlng);
	} else {
		$latitude //= $param{'lat'};
		$longitude //= $param{'lon'};
		$longitude //= $param{'long'};
	}

	if((!defined($latitude)) || !defined($longitude)) {
		Carp::croak('Usage: reverse_geocode(latlng => $location)');
	}

	if(!defined($self->{'cities'})) {
		$self->{'cities'} = Geo::Coder::Free::DB::MaxMind::cities->new(
			cache => $self->{cache} || CHI->new(driver => 'Memory', datastore => {})
		);
	}

	if(wantarray) {
		my @locs = $self->{'cities'}->execute("SELECT * FROM cities WHERE (ABS(Latitude - $latitude) < 0.01) AND (ABS(Longitude - $longitude) < 0.01)");
		foreach my $loc(@locs) {
			$self->_prepare($loc);
		}
		return map { Geo::Location::Point->new($_)->as_string() } @locs;
	}
	# Try close in then zoom out, to a reasonable limit
	foreach my $radius(0.000001, 0.00001, 0.0001, 0.001, 0.01) {
		if(my $rc = $self->{'cities'}->execute("SELECT * FROM cities WHERE (ABS(Latitude - $latitude) < $radius) AND (ABS(Longitude - $longitude) < $radius) LIMIT 1")) {
			$self->_prepare($rc);
			return Geo::Location::Point->new($rc)->as_string();
		}
	}
	return;
}

# Change 'Charing Cross, P5, Gb' to 'Charing Cross, London, Gb'
sub _prepare {
	my ($self, $loc) = @_;

	if(my $region = $loc->{'Region'}) {
		my $county;
		foreach my $c(keys %admin2cache) {
			if($admin2cache{$c} eq $region) {
				$county = $c;
				last;
			}
		}
		if($county) {
			$loc->{'Region'} = $county;
		} else {
			$self->{'admin2'} //= Geo::Coder::Free::DB::MaxMind::admin2->new() or die "Can't open the admin2 database";
			my $row = $self->{'admin2'}->execute("SELECT name FROM admin2 WHERE concatenated_codes LIKE '" . uc($loc->{'Country'}) . '.%.' . uc($region) . "' LIMIT 1");
			if(ref($row) && $row->{'name'}) {
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

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Lots of lookups fail at the moment.

The MaxMind data only contains cities.

Can't parse and handle "London, England".

The database contains Canadian cities, but not provinces, so a search for "New Brunswick, Canada" won't work

The GeoNames admin databases are in this class, they should be in Geo::Coder::GeoNames.

The data at
L<https://github.com/apache/commons-csv/blob/master/src/test/resources/perf/worldcitiespop.txt.gz?raw=true>
are 7 years out of date,
and are unconsistent with the Geonames database.

=head1 SEE ALSO

VWF, MaxMind and geonames.

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2019 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

This product includes GeoLite2 data created by MaxMind, available from
L<https://www.maxmind.com/en/home>.

=cut

1;
