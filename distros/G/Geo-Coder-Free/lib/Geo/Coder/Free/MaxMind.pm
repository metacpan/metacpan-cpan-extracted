package Geo::Coder::Free::MaxMind;

use strict;
use warnings;

use Geo::Coder::Free::DB::MaxMind::admin1;
use Geo::Coder::Free::DB::MaxMind::admin2;
use Geo::Coder::Free::DB::MaxMind::cities;
use Module::Info;
use Carp;
use File::Spec;
use Locale::CA;
use Locale::US;
use CHI;
use Locale::Country;

our %admin1cache;
our %admin2cache;

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

Version 0.04

=cut

our $VERSION = '0.04';

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

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'longitude'}, "\n";

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

	if($known_locations{$location}) {
		return $known_locations{$location};
	}

	# ::diag($location);
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
		if(($country =~ /^(United States|USA|US)$/)) {
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
		$country =~ s/^\s//g;
		$country =~ s/\s$//g;
	} elsif($location =~ /^[\w\s-],[\w\s-]/) {
		Carp::carp(__PACKAGE__, ": can't parse and handle $location");
		return;
	} elsif(($location =~ /^[\w\s-]+$/) && (my $region = $param{'region'})) {
		$location =~ s/^\s//g;
		$location =~ s/\s$//g;
		$country = uc($region);
	} else {
		# Carp::croak(__PACKAGE__, ' only supports towns, not full addresses');
		return;
	}
	if($country) {
		my $countrycode = country2code($country);
		if(defined($country) && (($country eq 'UK') || ($country eq 'United Kingdom') || ($country eq 'England'))) {
			$country = 'Great Britain';
			$concatenated_codes = 'GB';
		}

		if($state && $admin1cache{$state}) {
			$concatenated_codes = $admin1cache{$state};
		} elsif($admin1cache{$country} && !defined($state)) {
			$concatenated_codes = $admin1cache{$country};
		} else {
			if(!defined($self->{'admin1'})) {
				$self->{'admin1'} = Geo::Coder::Free::DB::MaxMind::admin1->new() or die "Can't open the admin1 database";
			}
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

	if(!defined($self->{'admin2'})) {
		$self->{'admin2'} = Geo::Coder::Free::DB::MaxMind::admin2->new() or die "Can't open the admin2 database";
	}
	my @admin2s;
	my $region;
	my @regions;
	if(($country =~ /^(United States|USA|US)$/) && $state && (length($state) > 2)) {
		if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
			$state = $twoletterstate;
		}
	} elsif(($country eq 'Canada') && (length($county) > 2)) {
		if(my $twoletterstate = Locale::CA->new()->{province2code}{uc($county)}) {
			$county = $twoletterstate;
		}
	}
	if(defined($county) && ($county =~ /^[A-Z]{2}$/) && ($country =~ /^(United States|USA|US)$/)) {
		# US state. Not Canadian province.
		$region = $county;
	} else {
		if($county && $admin1cache{$county}) {
			$region = $admin1cache{$county};
		} elsif($county && $admin2cache{$county}) {
			$region = $admin2cache{$county};
		} elsif(defined($state) && $admin2cache{$state} && !defined($county)) {
			$region = $admin2cache{$state};
		} else {
			@admin2s = $self->{'admin2'}->selectall_hash(asciiname => $county);
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
	}

	if((scalar(@regions) == 0) && !defined($region)) {
		# e.g. Unitary authorities in the UK
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
			my @admin1s = $self->{'admin1'}->selectall_hash(asciiname => $county);
			foreach my $admin1(@admin1s) {
				if($admin1->{'concatenated_codes'} =~ /^$concatenated_codes\./i) {
					$region = $admin1->{'concatenated_codes'};
					$admin1cache{$county} = $region;
					last;
				}
			}
		}
	}

	if(!defined($self->{'cities'})) {
		$self->{'cities'} = Geo::Coder::Free::DB::MaxMind::cities->new();
	}

	my $options = { City => lc($location) };
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
	# This case nonsense is because DBD::CSV changes the columns to lowercase, wherease DBD::SQLite does not
	if(wantarray) {
		my @rc = $self->{'cities'}->selectall_hash($options);
		if(scalar(@rc) == 0) {
			return;
		}
		# ::diag(__LINE__, Data::Dumper->new([\@rc])->Dump());
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
		return @rc;
	}
	my $city = $self->{'cities'}->fetchrow_hashref($options);
	if(!defined($city)) {
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

	if(defined($city) && defined($city->{'Latitude'})) {
		$city->{'latitude'} = delete $city->{'Latitude'};
		$city->{'longitude'} = delete $city->{'Longitude'};
		$city->{'confidence'} = $confidence;
	}
	return $city;
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

The MaxMind data only contains cities.

Can't parse and handle "London, England".

=head1 SEE ALSO

VWF, MaxMind and geonames.

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2018 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

This product includes GeoLite2 data created by MaxMind, available from
L<https://www.maxmind.com/en/home>.

=cut

1;
