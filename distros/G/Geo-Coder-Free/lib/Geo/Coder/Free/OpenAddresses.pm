package Geo::Coder::Free::OpenAddresses;

# Includes both openaddresses and Whos On First data

use strict;
use warnings;

use Geo::Coder::Free;	# for _abbreviate
use Geo::Coder::Free::DB::OpenAddr;	# SQLite database
use Geo::Coder::Free::DB::openaddresses;	# The original CSV files
use Geo::Hash;
use Geo::Location::Point;
use Module::Info;
use Carp;
use File::Spec;
use File::pfopen;
use Locale::CA;
use Locale::US;
use Locale::SubCountry;
use CHI;
use Lingua::EN::AddressParse;
use Locale::Country;
use Geo::StreetAddress::US;
use Digest::MD5;
use Encode;
use Storable;

# Some locations aren't found because of inconsistencies in the way things are stored - these are some values I know
# FIXME: Should be in a configuration file
our %known_locations = (
	'Newport Pagnell, Buckinghamshire, England' => {
		'latitude' => 52.08675,
		'longitude' => -0.72270
	},
);

our %unknown_locations;

use constant	LIBPOSTAL_UNKNOWN => 0;
use constant	LIBPOSTAL_INSTALLED => 1;
use constant	LIBPOSTAL_NOT_INSTALLED => -1;
our $libpostal_is_installed = LIBPOSTAL_UNKNOWN;

=head1 NAME

Geo::Coder::Free::OpenAddresses -
Provides a geocoding functionality to a local SQLite database containing geo-coding data.

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

=head1 SYNOPSIS

    use Geo::Coder::Free::OpenAddresses;

    # Use a local download of http://results.openaddresses.io/
    my $geocoder;
    if(my $openaddr = $ENV{'OPENADDR_HOME'}) {
	$geocoder = Geo::Coder::Free::OpenAddresses->new(openaddr => $openaddr);
    } else {
	$geocoder = Geo::Coder::Free::OpenAddresses->new(openaddr => '/usr/share/geo-coder-free/data');
    }
    my $location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');

    my @matches = $geocoder->geocode({ scantext => 'arbitrary text', region => 'GB' });

=head1 DESCRIPTION

Geo::Coder::Free::OpenAddresses provides an interface to the free geolocation databases at
L<http://results.openaddresses.io>,
L<https://github.com/whosonfirst-data>,
L<https://github.com/dr5hn/countries-states-cities-database.git> and
L<https://download.geofabrik.de/europe-latest.osm.bz2>.
The SQLite database is in a file held in $OPENADDR_HOME/openaddresses.sql.

Refer to the source URL for licencing information for these files.

To install,
run the createdatabases.PL script which imports the data into an SQLite database.
This process will take some time.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Free::OpenAddresses->new(openaddr => $ENV{'OPENADDR_HOME'});

Takes an optional parameter "openaddr", which is the directory of the file
openaddresses.sql.

Takes an optional parameter cache, which points to an object that understands get() and set() messages to store data in

=cut

sub new {
	my($proto, %param) = @_;
	my $class = ref($proto) || $proto;

	# Geo::Coder::Free->new not Geo::Coder::Free::new
	return unless($class);

	if(my $openaddr = $param{'openaddr'}) {
		Carp::croak(__PACKAGE__, ": Can't find the directory $openaddr")
			if((!-d $openaddr) || (!-r $openaddr));
		return bless { openaddr => $openaddr, cache => $param{'cache'} }, $class;
	}
	Carp::croak(__PACKAGE__, ": Usage: new(openaddr => '/path/to/openaddresses')");
}

=head2 geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

    # TODO:
    # @locations = $geocoder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

    @locations = $geo_coder->geocode(scantext => 'arbitrary text', region => 'US', ignore_words => [ 'foo', 'bar' ]);

When looking for a house number in a street, if that address isn't found but that
street is found, a place in the street is given.
So "106 Wells Street, Fort Wayne, Allen, Indiana, USA" isn't found, a match for
"Wells Street, Fort Wayne, Allen, Indiana, USA" will be given instead.
Arguably that's incorrect, but it is the behaviour I want.
If "exact" is not given,
it will go on to look just for the town if the street isn't found.

The word "county" is removed from US county searches,
that either C<Leesburg, Loudoun County, Virginia, US> or C<Leesburg, Loudoun, Virginia, US> will work.

=cut

sub geocode
{
	my $self = shift;

	my %param;
	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: geocode(location => $location|scantext => $text)');
	} elsif(scalar(@_) % 2 == 0) {
		%param = @_;
	} else {
		$param{location} = shift;
	}

	my %ignore_words;
	if($param{'ignore_words'}) {
		%ignore_words = map { lc($_) => 1 } @{$param{'ignore_words'}};
	}

	if(my $scantext = $param{'scantext'}) {
		return if(length($scantext) < 6);
		# FIXME:  wow this is inefficient
		$scantext =~ s/[^\w']+/ /g;
		my @words = split(/\s/, $scantext);
		my $count = scalar(@words);
		my $offset = 0;
		my @rc;
		my $region = $param{'region'};
		if($region) {
			$region = uc($region);
		}
		while($offset < $count) {
			if(length($words[$offset]) < 2) {
				$offset++;
				next;
			}
			if(exists($ignore_words{lc($words[$offset])})) {
				$offset++;
				next;
			}
			my $l;
			if(($l = $self->geocode(location => $words[$offset])) && ref($l)) {
				push @rc, $l;
			}
			if($offset < $count - 1) {
				my $addr = join(', ', $words[$offset], $words[$offset + 1]);
				if(length($addr) == 0) {
					$offset++;
				}
				# https://stackoverflow.com/questions/11160192/how-to-parse-freeform-street-postal-address-out-of-text-and-into-components
				# TODO: Support longer addresses
				if($addr =~ /\s+(\d{2,5}\s+)(?![a|p]m\b)(([a-zA-Z|\s+]{1,5}){1,2})?([\s|\,|.]+)?(([a-zA-Z|\s+]{1,30}){1,4})(court|ct|street|st|drive|dr|lane|ln|road|rd|blvd)([\s|\,|.|\;]+)?(([a-zA-Z|\s+]{1,30}){1,2})([\s|\,|.]+)?\b(AK|AL|AR|AZ|CA|CO|CT|DC|DE|FL|GA|GU|HI|IA|ID|IL|IN|KS|KY|LA|MA|MD|ME|MI|MN|MO|MS|MT|NC|ND|NE|NH|NJ|NM|NV|NY|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VA|VI|VT|WA|WI|WV|WY)([\s|\,|.]+)?(\s+\d{5})?([\s|\,|.]+)/i) {
					unless($region && ($region ne 'US')) {
						if(($l = $self->geocode(location => "$addr, US")) && ref($l)) {
							$l->confidence(0.8);
							$l->country('US');
							$l->location("$addr, USA");
							push @rc, $l;
						}
					}
				} elsif($addr =~ /\s+(\d{2,5}\s+)(?![a|p]m\b)(([a-zA-Z|\s+]{1,5}){1,2})?([\s|\,|.]+)?(([a-zA-Z|\s+]{1,30}){1,4})(court|ct|street|st|drive|dr|lane|ln|road|rd|blvd)([\s|\,|.|\;]+)?(([a-zA-Z|\s+]{1,30}){1,2})([\s|\,|.]+)?\b(AB|BC|MB|NB|NL|NT|NS|ON|PE|QC|SK|YT)([\s|\,|.]+)?(\s+\d{5})?([\s|\,|.]+)/i) {
					unless($region && ($region ne 'CA')) {
						if(($l = $self->geocode(location => "$addr, Canada")) && ref($l)) {
							$l->confidence(0.8);
							$l->country('CA');
							$l->location("$addr, Canada");
							push @rc, $l;
						}
					}
				} elsif($addr =~ /([a-zA-Z|\s+]{1,30}){1,2}([\s|\,|.]+)?\b(AK|AL|AR|AZ|CA|CO|CT|DC|DE|FL|GA|GU|HI|IA|ID|IL|IN|KS|KY|LA|MA|MD|ME|MI|MN|MO|MS|MT|NC|ND|NE|NH|NJ|NM|NV|NY|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VA|VI|VT|WA|WI|WV|WY)/i) {
					unless($region && ($region ne 'US')) {
						if(($l = $self->geocode(location => "$addr, US")) && ref($l)) {
							$l->confidence(0.6);
							$l->city(uc($1));
							$l->state(uc($3));
							$l->country('US');
							$l->location(uc("$addr, USA"));
							push @rc, $l;
						}
					}
				} elsif($addr =~ /([a-zA-Z|\s+]{1,30}){1,2}([\s|\,|.]+)?\b(AB|BC|MB|NB|NL|NT|NS|ON|PE|QC|SK|YT)/i) {
					unless($region && ($region ne 'CA')) {
						if(($l = $self->geocode(location => "$addr, Canada")) && ref($l)) {
							$l->confidence(0.6);
							$l->city(uc($1));
							$l->state(uc($3));
							$l->country('Canada');
							$l->location(uc("$addr, Canada"));
							push @rc, $l;
						}
					}
				}
				if($region && (($l = $self->geocode(location => "$addr, $region")) && ref($l))) {
					$l->confidence(0.2);
					$l->location("$addr, $region");
					# ::diag(__LINE__, ": $addr, $region");
					push @rc, $l;
				} elsif((!$region) && (($l = $self->geocode(location => $addr)) && ref($l))) {
					$l->confidence(0.1);
					$l->location($addr);
					# ::diag(__LINE__, ": $addr");
					push @rc, $l;
				}
				if($offset < $count - 2) {
					$addr = join(', ', $words[$offset], $words[$offset + 1], $words[$offset + 2]);
					if(($l = $self->geocode(location => $addr)) && ref($l)) {
						$l->confidence(1.0);
						$l->location($addr);
						push @rc, $l;
					}
				}
			}
			$offset++;
		}
		return @rc;
		# my @locations;

		# foreach my $l(@rc) {
			# ::diag(__LINE__, ': ', Data::Dumper->new([$l])->Dump());
			# push @locations, Location::GeoTool->create_coord($l->{'latitude'}, $l->{'longitude'}, $l->{'location'}, 'Degree');
		# }

		# return @locations;
	}

	my $location = $param{location}
		or Carp::croak('Usage: geocode(location => $location|scantext => $text)');

	# ::diag($location);

	$location =~ s/,\s+,\s+/, /g;

	if($location =~ /^,\s*(.+)/) {
		$location = $1;
	}

	# Fail when the input is just a set of numbers
	if($location !~ /\D/) {
		# Carp::croak('Usage: ', __PACKAGE__, ": invalid input to geocode(), $location");
		return;
	}
	return if(length($location) <= 1);

	if($location =~ /^(.+),?\s*Washington\s*DC$/i) {
		$location = "$1, Washington, DC, USA";
	} elsif($location =~ /^(.*),?\s*Saint Louis, (Missouri|MO)(.*)$/) {
		# createdatabase.PL also maps this
		$location = "$1, St. Louis, MO$3";
	}

	if(my $rc = $known_locations{$location}) {
		# return $known_locations{$location};
		return Geo::Location::Point->new({
			'lat' => $rc->{'latitude'},
			'long' => $rc->{'longitude'},
			'lng' => $rc->{'longitude'},
			'location' => $location,
			'database' => 'OpenAddresses'
		});
	}

	$self->{'location'} = $location;

	my $county;
	my $state;
	my $country;
	my $street;

	$location =~ s/\.//g;

	if($location !~ /,/) {
		if($location =~ /^(.+?)\s+(United States|USA|US)$/i) {
			my $l = $1;
			$l =~ s/\s+//g;
			if(my $rc = $self->_get($l, 'US')) {
				$rc->{'country'} = 'US';
				return $rc;
			}
		} elsif($location =~ /^(.+?)\s+(England|Scotland|Wales|Northern Ireland|UK|GB)$/i) {
			my $l = $1;
			$l =~ s/\s+//g;
			if(my $rc = $self->_get($l, 'GB')) {
				$rc->{'country'} = 'GB';
				return $rc;
			}
		} elsif($location =~ /^(.+?)\s+Canada$/i) {
			my $l = $1;
			$l =~ s/\s+//g;
			if(my $rc = $self->_get($l, 'CA')) {
				$rc->{'country'} = 'CA';
				return $rc;
			}
		}
	}
	my $ap;
	if(($location =~ /USA$/) || ($location =~ /United States$/)) {
		$ap = $self->{'ap'}->{'us'} // Lingua::EN::AddressParse->new(country => 'US', auto_clean => 1, force_case => 1, force_post_code => 0);
		$self->{'ap'}->{'us'} = $ap;
	} elsif($location =~ /(England|Scotland|Wales|Northern Ireland|UK|GB)$/i) {
		$ap = $self->{'ap'}->{'gb'} // Lingua::EN::AddressParse->new(country => 'GB', auto_clean => 1, force_case => 1, force_post_code => 0);
		$self->{'ap'}->{'gb'} = $ap;
	} elsif($location =~ /Canada$/) {
		$ap = $self->{'ap'}->{'ca'} // Lingua::EN::AddressParse->new(country => 'CA', auto_clean => 1, force_case => 1, force_post_code => 0);
		$self->{'ap'}->{'ca'} = $ap;
	} elsif($location =~ /Australia$/) {
		$ap = $self->{'ap'}->{'au'} // Lingua::EN::AddressParse->new(country => 'AU', auto_clean => 1, force_case => 1, force_post_code => 0);
		$self->{'ap'}->{'au'} = $ap;
	}
	if($ap) {
		my $l = $location;
		if($l =~ /(.+), (England|UK)$/i) {
			$l = "$1, GB";
		}
		if($ap->parse($l)) {
			# Carp::croak($ap->report());
			# ::diag('Address parse failed: ', $ap->report());
		} else {
			my %c = $ap->components();
			# ::diag(Data::Dumper->new([\%c])->Dump());
			my %addr = ( 'location' => $l );
			$street = $c{'street_name'};
			if(my $type = $c{'street_type'}) {
				if(my $a = Geo::Coder::Free::_abbreviate($type)) {
					$street .= " $a";
				} else {
					$street .= " $type";
				}
				if(my $suffix = $c{'street_direction_suffix'}) {
					$street .= " $suffix";
				}
				$street =~ s/^0+//;	# Turn 04th St into 4th St
				$addr{'road'} = $street;
			}
			if(length($c{'subcountry'}) == 2) {
				$addr{'state'} = $c{'subcountry'};
			} else {
				if($c{'country'} =~ /Canada/i) {
					$addr{'country'} = 'CA';
					if(my $twoletterstate = Locale::CA->new()->{province2code}{uc($c{'subcountry'})}) {
						$addr{'state'} = $twoletterstate;
					}
				} elsif($c{'country'} =~ /^(United States|USA|US)$/i) {
					$addr{'country'} = 'US';
					if(my $twoletterstate = Locale::US->new()->{state2code}{uc($c{'subcountry'})}) {
						$addr{'state'} = $twoletterstate;
					}
				} elsif($c{'country'}) {
					$addr{'country'} = $c{'country'};
					if($c{'subcountry'}) {
						$addr{'state'} = $c{'subcountry'};
					}
				}
			}
			$addr{'house_number'} = $c{'property_identifier'};
			$addr{'city'} = $c{'suburb'};
			# ::diag(Data::Dumper->new([\%addr])->Dump());
			if($addr{'house_number'}) {
				if(my $rc = $self->_search(\%addr, ('house_number', 'road', 'city', 'state', 'country'))) {
					return $rc;
				}
			}
			if((!$addr{'house_number'}) || !$param{'exact'}) {
				if(my $rc = $self->_search(\%addr, ('road', 'city', 'state', 'country'))) {
					return $rc;
				}
			}
		}
	}

	if($location =~ /^(.+?)[,\s]+(United States|USA|US)$/i) {
		# Try Geo::StreetAddress::US, which is rather buggy

		my $l = $1;
		$l =~ s/,/ /g;
		$l =~ s/\s\s+/ /g;

		# Work around for RT#122617
		if(($location !~ /\sCounty,/i) && (my $href = (Geo::StreetAddress::US->parse_location($l) || Geo::StreetAddress::US->parse_address($l)))) {
			# ::diag(Data::Dumper->new([$href])->Dump());
			if($state = $href->{'state'}) {
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
					if($href->{'type'} && (my $type = Geo::Coder::Free::_abbreviate($href->{'type'}))) {
						$street .= " $type";
					}
					if($href->{suffix}) {
						$street .= ' ' . $href->{suffix};
					}
					if(my $prefix = $href->{prefix}) {
						$street = "$prefix $street";
					}
					if($href->{'number'}) {
						if(my $rc = $self->_get($href->{'number'}, "$street$city$state", 'US')) {
							$rc->{'country'} = 'US';
							return $rc;
						}
					}
					if(my $rc = $self->_get("$street$city$state", 'US')) {
						$rc->{'country'} = 'US';
						return $rc;
					}
				}
			}
		}

		# Hack to find "name, street, town, state, US"
		my @addr = split(/,\s*/, $location);
		if(scalar(@addr) == 5) {
			# ::diag(__PACKAGE__, ': ', __LINE__, ": $location");
			$state = $addr[3];
			if(length($state) > 2) {
				if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
					$state = $twoletterstate;
				}
			}
			if(length($state) == 2) {
				$addr[1] = Geo::Coder::Free::_normalize($addr[1]);
				# ::diag(Data::Dumper->new([\@addr])->Dump());
				if(my $rc = $self->_get($addr[0], $addr[1], $addr[2], $state, 'US')) {
					# ::diag(Data::Dumper->new([$rc])->Dump());
					$rc->{'country'} = 'US';
					return $rc;
				}
			}
			# Hack to find "street, town, county, state, US"
			if(length($state) == 2) {
				$addr[0] = Geo::Coder::Free::_normalize($addr[0]);
				$addr[2] =~ s/\s+COUNTY$//i;
				# ::diag(Data::Dumper->new([\@addr])->Dump());
				if(my $rc = $self->_get($addr[0], $addr[1], $addr[2], $state, 'US')) {
					# ::diag(Data::Dumper->new([$rc])->Dump());
					$rc->{'country'} = 'US';
					return $rc;
				}
				if(my $rc = $self->_get($addr[0], $addr[1], $state, 'US')) {
					# ::diag(Data::Dumper->new([$rc])->Dump());
					$rc->{'country'} = 'US';
					return $rc;
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

		my $c;

		if((uc($country) eq 'ENGLAND') ||
		   (uc($country) eq 'SCOTLAND') ||
		   (uc($country) eq 'WALES')) {
			$country = 'Great Britain';
			$c = 'gb';
		} else {
			$c = country2code($country);
		}
		if($c) {
			if($c eq 'us') {
				if(length($state) > 2) {
					if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
						$state = $twoletterstate;
					}
				}
				my $rc;

				if($city !~ /,/) {
					$city = uc($city);
					if($city =~ /^(.+)\sCOUNTY$/) {
						# Simple case looking up a county in a state in the US
						if($rc = $self->_get("$1$state", 'US')) {
							$rc->{'country'} = 'US';
							return $rc;
						}
					} else {
						# Simple case looking up a city in a state in the US
						if($rc = $self->_get("$city$state", 'US')) {
							$rc->{'country'} = 'US';
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
					if($href->{city}) {
						$city = uc($href->{city});
					}
					# Unabbreviated - look up both, helps with fallback to Maxmind
					my $fullstreet = $href->{'street'};
					if($street = $fullstreet) {
						$fullstreet .= ' ' . $href->{'type'};
						if(my $type = Geo::Coder::Free::_abbreviate($href->{'type'})) {
							$street .= " $type";
						}
						if($href->{suffix}) {
							$street .= ' ' . $href->{suffix};
							$fullstreet .= ' ' . $href->{suffix};
						}
					}
					if($street) {
						if(my $prefix = $href->{prefix}) {
							$street = "$prefix $street";
							$fullstreet = "$prefix $fullstreet";
						}
						if($href->{'number'}) {
							# ::diag($href->{'number'}, "$street$city$state", 'US');
							if($rc = $self->_get($href->{'number'}, "$street$city$state", 'US')) {
								$rc->{'country'} = 'US';
								return $rc;
							}
							if($rc = $self->_get($href->{'number'}, "$fullstreet$city$state", 'US')) {
								$rc->{'country'} = 'US';
								return $rc;
							}
						}
						# ::diag("$street$city$state", 'US');
						if($rc = $self->_get("$street$city$state", 'US')) {
							$rc->{'country'} = 'US';
							return $rc;
						}
						# ::diag("$fullstreet$city$state", 'US');
						if($rc = $self->_get("$fullstreet$city$state", 'US')) {
							$rc->{'country'} = 'US';
							return $rc;
						}
					}
					warn "Fast lookup of US location '$location' failed";
				} else {
					if($city =~ /^(\d.+),\s*([\w\s]+),\s*([\w\s]+)/) {
						my $lookup = "$1, $2, $state";
						if(my $href = (Geo::StreetAddress::US->parse_address($lookup) || Geo::StreetAddress::US->parse_location($lookup))) {
							# Street, City, County
							# 105 S. West Street, Spencer, Owen, Indiana, USA
							# ::diag(Data::Dumper->new([\$href])->Dump());
							$county = $3;
							$county =~ s/\s*county$//i;
							if($href->{'state'}) {
								$state = $href->{'state'};
							} else {
								Carp::croak(__PACKAGE__, ": Geo::StreetAddress::US couldn't find the state in '$lookup'");
							}
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
								if(my $type = Geo::Coder::Free::_abbreviate($href->{'type'})) {
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
										if($rc = $self->_get($href->{'number'}, "$street$city$county$state", 'US')) {
											$rc->{'country'} = 'US';
											return $rc;
										}
									}
									if($rc = $self->_get($href->{'number'}, "$street$city$state", 'US')) {
										$rc->{'country'} = 'US';
										return $rc;
									}
									if($county) {
										if($rc = $self->_get("$street$city$county$state", 'US')) {
											$rc->{'country'} = 'US';
											return $rc;
										}
									}
									if($rc = $self->_get("$street$city$state", 'US')) {
										$rc->{'country'} = 'US';
										return $rc;
									}
								}
							}
							return;	# Not found
						}
						die $city;	# TODO: do something here
					} elsif($city =~ /^(\w[\w\s]+),\s*([\w\s]+)/) {
						# Perhaps it just has the street's name?
						# Rockville Pike, Rockville, MD, USA
						my $first = uc($1);
						my $second = uc($2);
						if($second =~ /(\d+)\s+(.+)/) {
							$second = "$1$2";
						}
						if($rc = $self->_get("$first$second$state", 'US')) {
							$rc->{'country'} = 'US';
							return $rc;
						}
						# Perhaps it's a city in a county?
						# Silver Spring, Montgomery County, MD, USA
						$second =~ s/\s+COUNTY$//;
						if($rc = $self->_get("$first$second$state", 'US')) {
							$rc->{'country'} = 'US';
							return $rc;
						}
						# Not all the database has the county
						if($rc = $self->_get("$first$state", 'US')) {
							$rc->{'country'} = 'US';
							return $rc;
						}
						# Brute force last ditch approach
						my $copy = uc($location);
						$copy =~ s/,\s+//g;
						$copy =~ s/\s*USA$//;
						if($rc = $self->_get($copy, 'US')) {
							$rc->{'country'} = 'US';
							return $rc;
						}
						if($copy =~ s/(\d+)\s+/$1/) {
							if($rc = $self->_get($copy, 'US')) {
								$rc->{'country'} = 'US';
								return $rc;
							}
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
					if($rc = $self->_get("$city$state", 'CA')) {
						$rc->{'country'} = 'CA';
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
						if(my $type = Geo::Coder::Free::_abbreviate($href->{'type'})) {
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
					warn "Fast lookup of Canadian location '$location' failed";
				} else {
					if($city =~ /^(\w[\w\s]+),\s*([\w\s]+)/) {
						# Perhaps it just has the street's name?
						# Rockville Pike, Rockville, MD, USA
						my $first = uc($1);
						my $second = uc($2);
						if($rc = $self->_get("$first$second$state", 'CA')) {
							$rc->{'country'} = 'CA';
							return $rc;
						}
						# Perhaps it's a city in a county?
						# Silver Spring, Montgomery County, MD, USA
						$second =~ s/\s+COUNTY$//;
						if($rc = $self->_get("$first$second$state", 'CA')) {
							$rc->{'country'} = 'CA';
							return $rc;
						}
						# Not all the database has the county
						if($rc = $self->_get("$first$state", 'CA')) {
							$rc->{'country'} = 'CA';
							return $rc;
						}
						# Brute force last ditch approach
						my $copy = uc($location);
						$copy =~ s/,\s+//g;
						$copy =~ s/\s*Canada$//i;
						if($rc = $self->_get($copy, 'CA')) {
							$rc->{'country'} = 'CA';
							return $rc;
						}
						if($copy =~ s/(\d+)\s+/$1/) {
							if($rc = $self->_get($copy, 'CA')) {
								$rc->{'country'} = 'CA';
								return $rc;
							}
						}
					}
					# warn "Can't yet parse Canadian location '$location'";
				}
			} else {
				# Currently only handles Town, Region, Country
				# TODO: add addresses support
				if(($c eq 'au') && (length($state) > 3)) {
					if(my $abbrev = Locale::SubCountry->new('AU')->code(ucfirst(lc($state)))) {
						if($abbrev ne 'unknown') {
							$state = $abbrev;
						}
					}
				}
				if($city =~ /^(\w[\w\s]+),\s*([,\w\s]+)/) {
					# City includes a street name
					$street = uc($1);
					$city = uc($2);
					my $number;
					if($street =~ /^(\d+)\s+(.+)/) {
						$number = $1;
						$street = $2;
					}

					# TODO: Configurable - or better still remove the need
					if($city eq 'MINSTER, THANET') {
						$city = 'RAMSGATE';
					}
					$street = Geo::Coder::Free::_normalize($street);
					if($number) {
						if(my $rc = $self->_get("$number$street$city$state$c")) {
							return $rc;
						}
						# If we can't find the number, at least find the road
					}
					if(my $rc = $self->_get("$street$city$state$c")) {
						return $rc;
					}
				}
				if((!$street) || !$param{'exact'}) {
					if(my $rc = $self->_get("$city$state$c")) {
						# return {
							# 'number' => undef,
							# 'street' => undef,
							# 'city' => $city,
							# 'state' => $state,
							# 'country' => $country,
							# %{$rc}
						# };
						return $rc;
					}
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
			$rc->{'country'} = $country;
			return $rc;
		}
	}

	# Finally try libpostal,
	# which is good but uses a lot of memory
	# ::diag("try libpostal on $location");
	if($libpostal_is_installed == LIBPOSTAL_UNKNOWN) {
		if(eval { require Geo::libpostal; } ) {
			Geo::libpostal->import();
			$libpostal_is_installed = LIBPOSTAL_INSTALLED;
		} else {
			$libpostal_is_installed = LIBPOSTAL_NOT_INSTALLED;
		}
	}

	# ::diag(__PACKAGE__, ': ', __LINE__, ": libpostal_is_installed = $libpostal_is_installed ($location)");
	# print(__PACKAGE__, ': ', __LINE__, ": libpostal_is_installed = $libpostal_is_installed ($location)\n");

	if(($libpostal_is_installed == LIBPOSTAL_INSTALLED) && (my %addr = Geo::libpostal::parse_address($location))) {
		# print Data::Dumper->new([\%addr])->Dump();
		if($addr{'country'} && $addr{'state'} && ($addr{'country'} =~ /^(Canada|United States|USA|US)$/i)) {
			if($street = $addr{'road'}) {
				$street = Geo::Coder::Free::_normalize($street);
				$addr{'road'} = $street;
			}
			if($addr{'country'} =~ /Canada/i) {
				$addr{'country'} = 'Canada';
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
			if($addr{'state_district'}) {
				$addr{'state_district'} =~ s/^(.+)\s+COUNTY/$1/i;
				if(my $rc = $self->_search(\%addr, ('house_number', 'road', 'city', 'state_district', 'state', 'country'))) {
					return $rc;
				}
			}
			if(my $rc = $self->_search(\%addr, ('house_number', 'road', 'city', 'state', 'country'))) {
				return $rc;
			}
			if($addr{'house_number'}) {
				if(my $rc = $self->_search(\%addr, ('road', 'city', 'state', 'country'))) {
					return $rc;
				}
			}
		}
	}
	if($location =~ s/,//g) {
		return $self->geocode($location);
	}
	undef;
}

# $data is a hashref to data such as returned by Geo::libpostal::parse_address
# @columns is the key names to use in $data
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

# State must be the abbreviated form
sub _get {
	my ($self, @location) = @_;

	my $location = join('', @location);
	$location =~ s/^\s+//;
	$location =~ s/,\s*//g;
	$location =~ tr/ž/z/;	# Remove wide characters
	$location =~ s/\xc5\xbe/z/g;
	$location =~ s/\N{U+017E}/z/g;

	# ::diag(__PACKAGE__, ': ', __LINE__, ": _get: $location");
	my $digest;
	if(length($location) <= 16) {
		$digest = uc($location);
	} else {
		$digest = substr Digest::MD5::md5_base64(uc($location)), 0, 16;
	}
	# print __PACKAGE__, ': ', __LINE__, ': ', uc($location), " = $digest\n";

	if(defined($unknown_locations{$digest})) {
		return;
	}
	# my @call_details = caller(0);
	# print "line ", $call_details[2], "\n";
	# print "$location: $digest\n";
	# ::diag("line " . $call_details[2]);
	# ::diag("$location: $digest");
	if(my $cache = $self->{'cache'}) {
		if(my $rc = $cache->get_object($digest)) {
			# ::diag(__LINE__, ': retrieved from cache');
			return Storable::thaw($rc->value());
		}
	}
	my $openaddr_db = $self->{openaddr_db} ||
		Geo::Coder::Free::DB::openaddresses->new(
			cache => $self->{cache} || CHI->new(driver => 'Memory', datastore => {}),
			directory => $self->{openaddr},
			id => 'md5',
			no_entry => 1,
		);
	$self->{openaddr_db} = $openaddr_db;
	if(my $geohash = $openaddr_db->geohash(md5 => $digest)) {
		$self->{'geo_hash'} ||= Geo::Hash->new();
		my ($latitude, $longitude) = $self->{'geo_hash'}->decode($geohash);

		my $rc = Geo::Location::Point->new({
			'lat' => $latitude,
			'long' => $longitude,
			'lng' => $longitude,
			'location' => $location,
			'database' => 'OpenAddresses'
		});

		if(my $cache = $self->{'cache'}) {
			$cache->set($digest, Storable::freeze($rc), '1 month');
		}

		return $rc;
	}
	$unknown_locations{$digest} = 1;
	return;
}

=head2	reverse_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

To be done.

=cut

# At the moment this can't be supported as the DB only has a hash in it
sub reverse_geocode {
	Carp::croak(__PACKAGE__, ': Reverse lookup is not yet supported');
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
the places listed in the synopsis.

=head1 BUGS

Lots of lookups fail at the moment.

There are die()s where the code path has yet to be written.

The openaddresses data doesn't cover the globe.

Can't parse and handle "London, England".

Currently only searches US and Canadian data.

If you do search in the UK, only look up towns, full addresses aren't
included.  So these will print the same.

    use Geo::Coder::Free::OpenAddresses;

    $location = $geo_coder->geocode(location => '22 Central Road, Ramsgate, Kent, England');
    print $location->{latitude}, "\n";
    print $location->{longitude}, "\n";
    $location = $geo_coder->geocode(location => '7 Hillbrow Road, St Lawrence, Thanet, Kent, England');
    print $location->{latitude}, "\n";
    print $location->{longitude}, "\n";

When I added the WhosOnFirst data I should have renamed this as it contains
data from both sources.

The database shouldn't be called $OPENADDR_HOME/openaddresses.sql,
since the database now also includes data from WhosOnFirst.

The name openaddresses.sql shouldn't be hardcoded,
add support to "new" for the parameter "dbname".

The argument "openaddr",
would be less confusing if it were called "directory",

=head1 SEE ALSO

VWF, openaddresses.

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

=cut

1;
