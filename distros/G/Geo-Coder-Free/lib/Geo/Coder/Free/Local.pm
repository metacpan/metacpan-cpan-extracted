package Geo::Coder::Free::Local;

use strict;
use warnings;

use Geo::Location::Point 0.14;
use Geo::Coder::Free;
use Geo::StreetAddress::US;
use Lingua::EN::AddressParse;
use Locale::CA;
use Locale::US;
use Object::Configure;
use Params::Get;
use Text::xSV::Slurp;

=head1 NAME

Geo::Coder::Free::Local -
Provides an interface to locations that you know yourself,
based on locally known data,
thereby giving a way to geocode locations using self-curated data instead of relying on external APIs.
For example, I have found locations by using GPS apps on a smartphone and by
inspecting GeoTagged photographs using
L<https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/geotag>
or by using the app GPSCF which are included here.

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

use constant	LIBPOSTAL_UNKNOWN => 0;
use constant	LIBPOSTAL_INSTALLED => 1;
use constant	LIBPOSTAL_NOT_INSTALLED => -1;
our $libpostal_is_installed = LIBPOSTAL_UNKNOWN;

# Alternative mappings for ambiguous or inconsistent place names
# See also lib/Geo/Coder/Free.pm
our %alternatives = (
	'ST LAWRENCE, THANET, KENT' => 'RAMSGATE, KENT',
	'ST PETERS, THANET, KENT' => 'ST PETERS, KENT',
	'MINSTER, THANET, KENT' => 'RAMSGATE, KENT',
	'TYNE AND WEAR' => 'BOROUGH OF NORTH TYNESIDE',
);

=head1 SYNOPSIS

    use Geo::Coder::Free::Local;

    my $geocoder = Geo::Coder::Free::Local->new();
    my $location = $geocoder->geocode(location => 'Ramsgate, Kent, UK');

=head1 DESCRIPTION

Geo::Coder::Free::Local provides an interface to your own location data.

=head1 METHODS

=head2 new

Initializes a geocoder object, loading the local data.

    $geocoder = Geo::Coder::Free::Local->new();

=cut

sub new
{
	my $class = shift;
	my $params = Params::Get::get_params(undef, \@_) || {};

	if(!defined($class)) {
		# Geo::Coder::Free::Local->new not Geo::Coder::Free::Local::new
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %{$params} }, ref($class);
	}

	$params = Object::Configure::configure($class, $params);

	# TODO: since 'hoh' doesn't allow a CODEREF as a key,
	#	I could build an hoh manually from this aoh,
	#	it would make searching much quicker
	my $self = bless {
		data => xsv_slurp(
			shape => 'aoh',
			text_csv => {
				allow_loose_quotes => 1,
				blank_is_undef => 1,
				empty_is_undef => 1,
				binary => 1,
				escape_char => '\\',
			},
			string => \join('', grep(!/^\s*(#|$)/, <DATA>))
		),
		%{$params}
	}, $class;

	# Build the hash-based index
	foreach my $row (@{ $self->{data} }) {
		my $key = lc(Geo::Location::Point->new($row)->as_string());
		$self->{index}{$key} = $row;
	}

	# TODO:  Perhaps the cache can be prepopulated, or stored in less volitile location?
	# The cache attribute stores normalized location strings as keys and Geo::Location::Point objects as values
	return $self;
}

# Helper function to normalize location strings
sub _normalize_location {
	my $location = shift;

	$location = lc($location);                 # Convert to lowercase
	$location =~ s/^\s+|\s+$//g;               # Trim leading and trailing whitespace
	$location =~ s/\s+/ /g;                    # Collapse multiple spaces
	return $location;
}

=head2 geocode

Performs the geocoding operation by matching an input location against the local data and attempting different strategies for parsing and resolving the address.

Handles parsing of addresses based on location-specific rules, e.g., U.S., U.K., or Canada.
Uses various parsers for country-specific address normalization.

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

    # TODO:
    # @locations = $geocoder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

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

	# Only used to geolocate full addresses, not states/provinces
	return if($location !~ /,.+,/);

	# ::diag(__PACKAGE__, ': ', __LINE__, ': ', $location);

	# Look for a quick match, we may get lucky
	my $lc = lc($location);
	$lc =~ s/,\susa$/, us/i;

	# Check the cache first
	if(exists $self->{cache}{$lc}) {
		# ::diag("Found $lc in the cache");
		return $self->{cache}{$lc};
	}

	# Use the hash-based index for a quick lookup
	if(exists $self->{index}{$lc}) {
		# Store the result in the cache for future requests
		return $self->{cache}{$lc} = $self->{index}{$lc};	# Geo::Location::Point object
	}
	# ::diag("$location: hash search failed");

	if(0) {
		# Old linear search mode, now replaced by the hash-based index
		foreach my $row(@{$self->{'data'}}) {
			my $rc = Geo::Location::Point->new($row);
			my $str = lc($rc->as_string());

			# ::diag("Compare $str->$lc") if(($location =~ /MINSTER CEME/i) && ($str =~ /MINSTER CEME/i));
			# ::diag("Compare $str->$lc");
			# print "Compare $str->$lc\n";
			if($str eq $lc) {
				# This looks pointless and I can't recall why I put it in
				# foreach my $column ('name', 'state_district') {
					# if((!defined($rc->{$column})) && exists($rc->{$column})) {
						# delete $rc->{$column};
					# }
				# }
				# ::diag("$location: linear search suceeded");
				return $rc;
			}

			if(($str =~ /, us$/) && ("${str}a" eq $lc)) {
				return $rc;
			}

			if(($lc =~ /(.+), (England|UK)$/i) && ($str eq "$1, gb")) {
				return $rc;
			}
		}
		# ::diag("$location: linear search failed");
	}

	# ::diag(__PACKAGE__, ': ', __LINE__, ': ', $location);

	my $ap;
	if(($location =~ /USA$/) || ($location =~ /United States$/)) {
		$ap = $self->{'ap'}->{'us'} // Lingua::EN::AddressParse->new(country => 'US', auto_clean => 1, force_case => 1, force_post_code => 0);
		$self->{'ap'}->{'us'} = $ap;
	} elsif($location =~ /(England|Scotland|Wales|Northern Ireland|UK|GB)$/i) {
		$ap = $self->{'ap'}->{'gb'} // Lingua::EN::AddressParse->new(country => 'GB', auto_clean => 1, force_case => 1, force_post_code => 0);
		$self->{'ap'}->{'gb'} = $ap;
	} elsif($location =~ /Canada$/) {
		# TODO: no Canadian addresses yet
		return;
		$ap = $self->{'ap'}->{'ca'} // Lingua::EN::AddressParse->new(country => 'CA', auto_clean => 1, force_case => 1, force_post_code => 0);
		$self->{'ap'}->{'ca'} = $ap;
	} elsif($location =~ /Australia$/) {
		# TODO: no Australian addresses yet
		return;
		$ap = $self->{'ap'}->{'au'} // Lingua::EN::AddressParse->new(country => 'AU', auto_clean => 1, force_case => 1, force_post_code => 0);
		$self->{'ap'}->{'au'} = $ap;
	}
	if($ap) {
		# ::diag(__PACKAGE__, ': ', __LINE__, ': ', $location);

		my $l = $location;
		if($l =~ /(.+), (England|UK)$/i) {
			$l = "$1, GB";
		}
		# if(my $error = $ap->parse($l)) {
			# Carp::croak($ap->report());
			# ::diag('Address parse failed: ', $ap->report());
		# } else {
		if($ap->parse($l) == 0) {
			# ::diag(__PACKAGE__, ': ', __LINE__, ': ', $location);
			my %c = $ap->components();
			# ::diag(Data::Dumper->new([\%c])->Dump());
			my %addr = ('location' => $l);
			my $street = $c{'street_name'};
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
			$addr{'number'} = $c{'property_identifier'};
			$addr{'city'} = $c{'suburb'};
			# ::diag(Data::Dumper->new([\%addr])->Dump());
			# print Data::Dumper->new([\%addr])->Dump(), "\n";
			if(my $rc = $self->_search(\%addr, ('number', 'road', 'city', 'state', 'country'))) {
			        # Store the result in the cache for future requests
				$self->{cache}{$lc} = $rc;

				return $rc;
			}
			if($addr{'number'}) {
				if(my $rc = $self->_search(\%addr, ('road', 'city', 'state', 'country'))) {
					# Store the result in the cache for future requests
					$self->{cache}{$lc} = $rc;

					return $rc;
				}
			}

			# Decide if it's worth continuing to search
			my $found = 0;
			if(!defined($addr{'country'})) {
				if($l =~ /(United States|USA|US)$/i) {
					$addr{'country'} = 'US';
				} else {
					die "TODO: extract country from $l";
				}
			}
			foreach my $row(@{$self->{'data'}}) {
				if((uc($row->{'state'}) eq uc($addr{'state'})) &&
				   (uc($row->{'country'}) eq uc($addr{'country'}))) {
					$found = 1;
					last;
				}
			}
			if(!$found) {
				# Nothing at all in this state/country,
				#	so let's give up looking
				return;
			}
		}
	}

	if($location =~ /^(.+?)[,\s]+(United States|USA|US)$/i) {
		# Try Geo::StreetAddress::US, which is rather buggy

		my $l = $1;
		$l =~ tr/,/ /;
		$l =~ s/\s\s+/ /g;

		# ::diag(__PACKAGE__, ': ', __LINE__, ": $location ($l)");

		# Work around for RT#122617
		if(($location !~ /\sCounty,/i) && (my $href = (Geo::StreetAddress::US->parse_location($l) || Geo::StreetAddress::US->parse_address($l)))) {
			# ::diag(Data::Dumper->new([$href])->Dump());
			if(my $state = $href->{'state'}) {
				if(length($state) > 2) {
					if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
						$state = $twoletterstate;
					}
				}
				my $city;
				if($href->{city}) {
					$city = uc($href->{city});
				}
				if(my $street = $href->{street}) {
					if($href->{'type'} && (my $type = Geo::Coder::Free::_abbreviate($href->{'type'}))) {
						$street .= " $type";
					}
					if($href->{suffix}) {
						$street .= ' ' . $href->{suffix};
					}
					if(my $prefix = $href->{prefix}) {
						$street = "$prefix $street";
					}
					my %addr = (
						number => $href->{'number'},
						road => $street,
						city => $city,
						state => $state,
						country => 'US'
					);
					if($href->{'number'}) {
						if(my $rc = $self->_search(\%addr, ('number', 'road', 'city', 'state', 'country'))) {
							$rc->{'country'} = 'US';

							# Store the result in the cache for future requests
							$self->{cache}{$lc} = $rc;

							return $rc;
						}
					}
					if(my $rc = $self->_search(\%addr, ('road', 'city', 'state', 'country'))) {
						$rc->{'country'} = 'US';

						# Store the result in the cache for future requests
						$self->{cache}{$lc} = $rc;

						return $rc;
					}
					# ::diag(__PACKAGE__, ': ', __LINE__, ": $location");
					if($street && !$href->{'number'}) {
						# If you give a building with
						# no street to G:S:US it puts
						# the building name into the
						# street field
						$addr{'name'} = $street;
						delete $addr{'road'};

						if(my $rc = $self->_search(\%addr, ('name', 'city', 'state', 'country'))) {
							$rc->{'country'} = 'US';

							# Store the result in the cache for future requests
							$self->{cache}{$lc} = $rc;

							return $rc;
						}
					}
				}
			}
		}

		# Hack to find "name, street, town, state, US"
		my @addr = split(/,\s*/, $location);
		# ::diag(__PACKAGE__, ': ', __LINE__, ' ', scalar(@addr));
		if(scalar(@addr) == 5) {
			# ::diag(__PACKAGE__, ': ', __LINE__, ": $location");
			# ::diag(Data::Dumper->new([\@addr])->Dump());
			my $state = $addr[3];
			if(length($state) > 2) {
				if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
					$state = $twoletterstate;
				}
			}
			if(length($state) == 2) {
				my %addr = (
					city => $addr[2],
					state => $state,
					country => 'US'
				);
				# ::diag(__PACKAGE__, ': ', __LINE__);
				if($addr[0] !~ /^\d/) {
					# ::diag(__PACKAGE__, ': ', __LINE__);
					$addr{'name'} = $addr[0];
					if($addr[1] =~ /^(\d+)\s+(.+)/) {
						# ::diag(__PACKAGE__, ': ', __LINE__);
						$addr{'number'} = $1;
						$addr{'road'} = Geo::Coder::Free::_normalize($2);
						if(my $rc = $self->_search(\%addr, ('name', 'number', 'road', 'city', 'state', 'country'))) {
							# ::diag(Data::Dumper->new([$rc])->Dump());
							$rc->{'country'} = 'US';

							# Store the result in the cache for future requests
							$self->{cache}{$lc} = $rc;

							return $rc;
						}
					} else {
						$addr{'road'} = Geo::Coder::Free::_normalize($addr[1]);
						if(my $rc = $self->_search(\%addr, ('name', 'road', 'city', 'state', 'country'))) {
							# ::diag(Data::Dumper->new([$rc])->Dump());
							$rc->{'country'} = 'US';

							# Store the result in the cache for future requests
							$self->{cache}{$lc} = $rc;

							return $rc;
						}
					}
				} else {
					$addr{'number'} = $addr[0];
					$addr{'road'} = Geo::Coder::Free::_normalize($addr[1]);
					if(my $rc = $self->_search(\%addr, ('number', 'road', 'city', 'state', 'country'))) {
						# ::diag(Data::Dumper->new([$rc])->Dump());
						$rc->{'country'} = 'US';

						# Store the result in the cache for future requests
						$self->{cache}{$lc} = $rc;

						return $rc;
					}
				}
			}
		}
	}

	if(($location =~ /.+,.+,.*England$/) &&
	   ($location !~ /.+,.+,.+,.*England$/)) {
		# Simple "Town, County, England"
		# If we're here, it's not going to be found because the
		# above parsers will have worked
		return;
	}

	# Finally try libpostal,
	# which is good but uses a lot of memory and can take a very long time to parse data
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

	# TODO: cache calls to this
	if(($libpostal_is_installed == LIBPOSTAL_INSTALLED) && (my %addr = Geo::libpostal::parse_address($location))) {
		if($addr{'house_number'} && !$addr{'number'}) {
			$addr{'number'} = delete $addr{'house_number'};
		}
		if($addr{'house'} && !$addr{'name'}) {
			$addr{'name'} = delete $addr{'house'};
		}
		$addr{'location'} = $location;
		if(my $street = $addr{'road'}) {
			$addr{'road'} = Geo::Coder::Free::_normalize($street);
		}
		if(defined($addr{'state'}) && !defined($addr{'country'}) && ($addr{'state'} eq 'england')) {
			delete $addr{'state'};
			$addr{'country'} = 'GB';
		}
		# ::diag(__PACKAGE__, ': ', __LINE__, ': ', Data::Dumper->new([\%addr])->Dump());
		if($addr{'country'} && ($addr{'state'} || $addr{'state_district'})) {
			if($addr{'country'} =~ /Canada/i) {
				$addr{'country'} = 'Canada';
				if(length($addr{'state'}) > 2) {
					if(my $twoletterstate = Locale::CA->new()->{province2code}{uc($addr{'state'})}) {
						$addr{'state'} = $twoletterstate;
					}
				}
			} elsif($addr{'country'} =~ /^(United States|USA|US)$/i) {
				$addr{'country'} = 'US';
				if(length($addr{'state'}) > 2) {
					if(my $twoletterstate = Locale::US->new()->{state2code}{uc($addr{'state'})}) {
						$addr{'state'} = $twoletterstate;
					}
				}
			}
			if($addr{'state_district'}) {
				$addr{'state_district'} =~ s/^(.+)\s+COUNTY/$1/i;
				if(my $rc = $self->_search(\%addr, ('number', 'road', 'city', 'state_district', 'state', 'country'))) {

					# Store the result in the cache for future requests
					$self->{cache}{$lc} = $rc;

					return $rc;
				}
			}
			if(my $rc = $self->_search(\%addr, ('number', 'road', 'city', 'state', 'country'))) {
				# ::diag(__PACKAGE__, ': ', __LINE__, ': ', Data::Dumper->new([$rc])->Dump());

				# Store the result in the cache for future requests
				$self->{cache}{$lc} = $rc;

				return $rc;
			}
			if($addr{'number'}) {
				if(my $rc = $self->_search(\%addr, ('road', 'city', 'state', 'country'))) {

					# Store the result in the cache for future requests
					$self->{cache}{$lc} = $rc;

					return $rc;
				}
			}
		}
	}
	if($location =~ /^(.+?),\s*([\s\w]+),\s*([\s\w]+),\s*([\w\s]+)$/) {
		# >= 5.14 could say:
		# my %addr = (
		#	road => $1,
		#	city => $2,
		#	state => $3 =~ s/\s+$//r,
		#	country => $4 =~ s/\s+$//r
		# );
		my %addr = (
			road => $1,
			city => $2,
			state => $3,
			country => $4,
		);
		$addr{'state'} =~ s/\s$//g;
		$addr{'country'} =~ s/\s$//g;
		if($addr{'road'} =~ /([\w\s]+),*\s+(.+)/) {
			$addr{'name'} = $1;
			$addr{'road'} = $2;
		}
		if($addr{'road'} =~ /^(\d+)\s+(.+)/) {
			$addr{'number'} = $1;
			$addr{'road'} = $2;
			# ::diag(__LINE__, ': ', Data::Dumper->new([\%addr])->Dump());
			if(my $rc = $self->_search(\%addr, ('name', 'number', 'road', 'city', 'state', 'country'))) {

				# Store the result in the cache for future requests
				$self->{cache}{$lc} = $rc;

				return $rc;
			}
		} elsif(my $rc = $self->_search(\%addr, ('name', 'road', 'city', 'state', 'country'))) {

			# Store the result in the cache for future requests
			$self->{cache}{$lc} = $rc;

			return $rc;
		}
		if($addr{'name'} && !defined($addr{'number'})) {
			# We know the name of the building but not the street number
			# ::diag(__LINE__, ': ', $addr{'name'});
			if(my $rc = $self->_search(\%addr, ('name', 'road', 'city', 'state', 'country'))) {
				# ::diag(__PACKAGE__, ': ', __LINE__);

				# Store the result in the cache for future requests
				$self->{cache}{$lc} = $rc;

				return $rc;
			}
		}
	}

	$location = uc($location);
	foreach my $left(keys %alternatives) {
		# ::diag("$location/$left");
		if($location =~ $left) {
			# ::diag($left, '=>', $alternatives{$left});
			$location =~ s/$left/$alternatives{$left}/;
			$params{'location'} = $location;
			# ::diag(__LINE__, ": found alternative '$location'");
			if(my $rc = $self->geocode(\%params)) {
				# ::diag(__LINE__, ": $location");

				# Store the result in the cache for future requests
				$self->{cache}{$lc} = $rc;

				return $rc;
			}
			if($location =~ /(.+), (England|UK)$/i) {
				$params{'location'} = "$1, GB";
				if(my $rc = $self->geocode(\%params)) {
					# ::diag(__LINE__, ": $location");

					# Store the result in the cache for future requests
					$self->{cache}{$lc} = $rc;

					return $rc;
				}
			}
		}
	}
	return;
}

# Match parsed address components against the locally loaded dataset.

# $data is a hashref to data such as returned by Geo::libpostal::parse_address
# @columns is the key names to use in $data
sub _search
{
	my ($self, $data, @columns) = @_;

	# FIXME: linear search is slow
	# ::diag(__LINE__, ': ', Data::Dumper->new([\@columns, $data])->Dump());
	# print Data::Dumper->new([\@columns, $data])->Dump();
	# my @call_details = caller(0);
	# ::diag(__LINE__, ': called from ', $call_details[2]);
	foreach my $row(@{$self->{'data'}}) {
		my $match = 1;
		my $number_of_columns_matched;

		# ::diag(Data::Dumper->new([$self->{data}])->Dump());
		# print Data::Dumper->new([$self->{data}])->Dump();

		foreach my $column(@columns) {
			if(defined($data->{$column})) {
				# ::diag("$column: ", $row->{$column}, '/', $data->{$column});
				# print "$column: ", $row->{$column}, '/', $data->{$column}, "\n";
				if(!defined($row->{$column})) {
					$match = 0;
					last;
				}
				if(uc($row->{$column}) ne uc($data->{$column})) {
					$match = 0;
					last;
				}
				$number_of_columns_matched++;
			} elsif(exists $data->{$column}) {
				delete $data->{$column};
			}
		}
		# ::diag("match: $match");
		if($match && ($number_of_columns_matched >= 3)) {
			my $confidence;
			if($number_of_columns_matched == scalar(@columns)) {
				$confidence = 1.0;
			} elsif($number_of_columns_matched >= 4) {
				$confidence = 0.7;
			} else {
				$confidence = 0.5;
			}
			# ::diag("$number_of_columns_matched -> $confidence");
			return Geo::Location::Point->new(
				# 'latitude' => $row->{'latitude'},
				# 'longitude' => $row->{'longitude'},
				'location' => $data->{'location'},
				'confidence' => $confidence,
				'database' => __PACKAGE__,
				%{$row}
			);
		}
	}
	return;
}

=head2	reverse_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

=cut

sub reverse_geocode {
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

	# ::diag(__LINE__, ": $latitude,$longitude");
	my @rc;
	foreach my $row(@{$self->{'data'}}) {
		if(defined($row->{'latitude'}) && defined($row->{'longitude'})) {
			# ::diag(__LINE__, ': ', $row->{'latitude'}, ', ', $latitude);
			if(_equal($row->{'latitude'}, $latitude, 4) &&
			   _equal($row->{'longitude'}, $longitude, 4)) {
				# ::diag('match');
				my $location = uc($row->as_string());	# Geo::Location::Point object
				if(wantarray) {
					push @rc, $location;
					while(my($left, $right) = each %alternatives) {
						# ::diag("$location/$left");
						if($location =~ $right) {
							# ::diag($right, '=>', $left);
							my $l = $location;
							$l =~ s/$right/$left/;
							# ::diag(__LINE__, ": $location");
							push @rc, $l;
							# Don't add last here
						}
					}
				} else {
					return $location;
				}
			}
		}
	}
	return @rc;
}

# https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch02s03.html
# equal(NUM1, NUM2, ACCURACY) : returns true if NUM1 and NUM2 are
# equal to ACCURACY number of decimal places
sub _equal {
	my ($A, $B, $dp) = @_;

	return sprintf("%.${dp}g", $A) eq sprintf("%.${dp}g", $B);
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

The data are stored in the source,
they should be read in from somewhere else to make it easier for non-authors to add data.

=head1 SEE ALSO

=head1 LICENSE AND COPYRIGHT

Copyright 2020-2024 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

=cut

1;

# Ensure you use abbreviations, e.g. RD not ROAD
__DATA__
"name","number","road","city","state_district","state","country","latitude","longitude"
"ST ANDREWS CHURCH",,"CHURCH HILL","EARLS COLNE",,"ESSEX","GB",51.926793,0.70408
"WESTWOOD CROSS",23,"MARGATE RD","BROADSTAIRS",,"KENT","GB",51.358967,1.391367
"RECULVER ABBEY",,"RECULVER","HERNE BAY",,"KENT","GB",51.37875,1.1955
"NEW INN",2,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.334522,1.314417
"HOLIDAY INN EXPRESS",,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.34320725,1.31680853
"",106,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.33995174,1.31570211
"",114,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.34015944,1.31580976
"MINSTER CEMETERY",116,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.34203083,1.31609075
"RAMSGATE STATION",,"STATION APPROACH RD","RAMSGATE","","KENT","GB",51.340826,1.406519
"ST MARY THE VIRGIN CHURCH",,"CHURCH ST","RAMSGATE",,"KENT","GB",51.33090893,1.31559716
"",20,"MELBOURNE AVE","RAMSGATE",,"KENT","GB",51.34772374,1.39532565
"TOBY CARVERY",,"NEW HAINE RD","RAMSGATE",,"KENT","GB",51.357510,1.388894
"",,"WESTCLIFF PROMENADE","RAMSGATE",,"KENT","GB",51.32711,1.406806
"TOWER OF LONDON",35,"TOWER HILL","LONDON",,"LONDON","GB",51.5082675,-0.0754225
"",5350,"CHILLUM PLACE NE","WASHINGTON",,"DC","US",38.955403,-76.996241
"WALTER E. WASHINGTON CONVENTION CENTER",801,"MT VERNON PL NW","WASHINGTON","","DC","US",38.904022,-77.023113
"",7,"JORDAN MILL COURT","WHITE HALL","BALTIMORE","MD","US",39.6852333333333,-76.6071166666667
"ALL SAINTS EPISCOPAL CHURCH",203,"E CHATSWORTH RD","REISTERSTOWN","BALTIMORE","MD","US",39.467270,-76.823947
"BALLPARK RESTAURANT",3418,"CONOWINGO RD","DUBLIN","HARFORD","MD","US",39.633018,-76.272558
"NCBI",,"MEDLARS DR","BETHESDA","MONTGOMERY","MD","US",38.99516556,-77.09943963
"",,"CENTER DR","BETHESDA","MONTGOMERY","MD","US",38.99698114,-77.10031119
"",,"NORFOLK AVE","BETHESDA","MONTGOMERY","MD","US",38.98939358,-77.09819543
"ROCK BOTTOM RESTAURANT & BREWERY",,"NORFOLK AVE","BETHESDA","MONTGOMERY","MD","US",38.9890861111111,-77.0975722222222
"",3516,"SW MACVICAR AVE","TOPEKA","SHAWNEE","KS","US",39.005175,-95.706681
"THE ATRIUM AT ROCK SPRING PARK",6555,"ROCKLEDGE DR","BETHESDA","MONTGOMERY","MD","US",39.028326,-77.136774
"","","MOUTH OF MONOCACY RD","DICKERSON","MONTGOMERY","MD","US",39.2244603797302,-77.449615439877
"PATAPSCO VALLEY STATE PARK'",8020,"BALTIMORE NATIONAL PK","ELLICOTT CITY","HOWARD","MD","US",39.29491,-76.78051
"",,"ANNANDALE RD","EMMITSBURG","FREDERICK","MD","US",39.683529,-77.349405
"UTICA DISTRICT PARK",,,"FREDERICK","FREDERICK","MD","US",39.5167883333333,-77.4015166666667
"",3923,"SUGARLOAF CT","MONROVIA","FREDERICK","MD","US",39.342986,-77.239770
"ALBERT EINSTEIN HIGH SCHOOL",11135,"NEWPORT MILL RD","KENSINGTON","MONTGOMERY","MD","US",39.03869019,-77.0682871
"",10540,"METROPOLITAN AVE","KENSINGTON","MONTGOMERY","MD","US",39.028404,-77.073227
"POST OFFICE",10325,"KENSINGTON PKWY","KENSINGTON","MONTGOMERY","MD","US",39.02554455,-77.07178215
"NEWPORT MILL MIDDLE SCHOOL",11311,"NEWPORT MILL RD","KENSINGTON","MONTGOMERY","MD","US",39.0416107,-77.06884708
"SAFEWAY",10541,"HOWARD AVE","KENSINGTON","MONTGOMERY","MD","US",39.02822438,-77.0755196
"HAIR CUTTERY",3731,"CONNECTICUT AVE","KENSINGTON","MONTGOMERY","MD","US",39.03323865,-77.07368044
"STROSNIDERS",10504,"CONNECTICUT AVE","KENSINGTON","MONTGOMERY","MD","US",39.02781493,-77.07740792
"",8616,"SAVANNAH RIVER RD","LAUREL","ANNE ARUNDEL","MD","US",39.100869,-76.812162
"DOWNS PARK",,"CHESAPEAKE BAY DRIVE","PASADENA","ANNE ARUNDEL","MD","US",39.110711,-76.434062
"",1559,"GUERDON CT","PASADENA","ANNE ARUNDEL","MD","US",39.102637,-76.456384
"ARCOLA HEALTH AND REHABILITATION CENTER",901,"ARCOLA AVE","SILVER SPRING","MONTGOMERY","MD","US",39.036439,-77.025502
"",9904,"GARDINER AVE","SILVER SPRING","MONTGOMERY","MD","US",39.017633,-77.049551
"CVS",9520,"GEORGIA AVE","SILVER SPRING","MONTGOMERY","MD","US",39.010801,-77.041771
"FOREST GLEN MEDICAL CENTER",9801,"GEORGIA AVE","SILVER SPRING","MONTGOMERY","MD","US",39.016042,-77.042148
"",10009,"GREELEY AVE","SILVER SPRING","MONTGOMERY","MD","US",39.019575,-77.047453
"ADVENTIST HOSPITAL",11886,"HEALING WAY","SILVER SPRING","MONTGOMERY","MD","US",39.049570,-76.956882
"",2232,"HILDAROSE DR","SILVER SPRING","MONTGOMERY","MD","US",39.019385,-77.049779,
"LA CASITA PUPESERIA AND MARKET",8214,"PINEY BRANCH RD","SILVER SPRING","MONTGOMERY","MD","US",38.993369,-77.009501
"NOAA LIBRARY",1315,"EAST-WEST HIGHWAY","SILVER SPRING","MONTGOMERY","MD","US",38.991667,-77.030473
"SNIDERS",1936,"SEMINARY RD","SILVER SPRING","MONTGOMERY","MD","US",39.0088797,-77.04162824
"",1954,"SEMINARY RD","SILVER SPRING","MONTGOMERY","MD","US",39.008961,-77.04303
"",1956,"SEMINARY RD","SILVER SPRING","MONTGOMERY","MD","US",39.008845,-77.043317
"",9315,"WARREN ST","SILVER SPRING","MONTGOMERY","MD","US",39.00881,-77.048953
"",9411,"WARREN ST","SILVER SPRING","MONTGOMERY","MD","US",39.010447,-77.048548
"SILVER DINER",12276,"ROCKVILLE PK","ROCKVILLE","MONTGOMERY","MD","US",39.05798753,-77.12165374
"",1605,"VIERS MILL RD","ROCKVILLE","MONTGOMERY","MD","US",39.07669788,-77.12306436
"",1406,"LANGBROOK PLACE","ROCKVILLE","MONTGOMERY","MD","US",39.075583,-77.123833
"",2225,"FOREST GLEN RD","SILVER SPRING","MONTGOMERY","MD","US",39.015394,-77.048357
"BP",2601,"FOREST GLEN RD","SILVER SPRING","MONTGOMERY","MD","US",39.0147541,-77.05466857
"OMEGA STUDIOS",12412,,"ROCKVILLE","MONTGOMERY","MD","US",39.06412645,-77.11252263
"",10424,"43RD AVE","BELTSVILLE","PRINCE GEORGE","MD","US",39.033075,-76.923859
"NASA",,"TIROS RD","GREENBELT","PRINCE GEORGE","MD","US",38.996764,-76.849323
"",7001,"CRADLEROCK FARM COURT","COLUMBIA","HOWARD","MD","US",39.190009,-76.841152
"BANGOR AIRPORT",,"GODFREY BOULEVARD","BANGOR","PENOBSCOT","ME","US",44.406700,-68.597114
"",86,"ALLEN POINT LANE","BLUE HILLS","HANCOCK","ME","US",44.35378018,-68.57383976
"TRADEWINDS",15,"SOUTH STREET","BLUE HILLS","HANCOCK","ME","US",44.40670019,-68.59711438
"RITE AID",17,"SOUTH STREET","BLUE HILLS","HANCOCK","ME","US",44.40662476,-68.59610059
"",880,"SOUTH GREENSFERRY RD","COUER D'ALENE","KOOTENAI","ID","US",47.693615,-116.915357
"",898,"SOUTH GREENSFERRY RD","COUER D'ALENE","KOOTENAI","ID","US",47.69556,-116.91564
"",,"DOUGLAS AVE","FORT WAYNE","ALLEN","IN","US",41.074247,-85.138531
"JOHN GLENN AIRPORT",4600,,"COLUMBUS","FRANKLIN","OH","US",39.997959,-82.88132
"MIDDLE RIDGE PLAZA",,,"AMHERST","LOHRAIN","OH","US",41.379695,-82.222877
"RESIDENCE INN BY MARRIOTT",6364,"FRANTZ RD","DUBLIN",,"OH","US",40.097097,-83.123745
"TOWPATH TRAVEL PLAZA",,,"BROADVIEW HEIGHTS","CUYAHOGA","OH","US",41.291654,-81.675815
"NEW STANTON SERVICE PLAZA",,,"HEMPFIELD",,"PA","US",40.206267,-79.565682
"",,"","LITITZ","LANCASTER","PA","US",40.154989, -76.304266
"SOUTH SOMERSET SERVICE PLAZA",,,"SOMERSET","SOMERSET","PA","US",39.999154,-79.046526
"HUNTLEY MEADOWS PARK",3701,"LOCKHEED BLVD","ALEXANDRIA","","VA","US",38.75422, -77.1058666666667
"SHENANDOAH COOL SPRINGS BATTLEFIELD",,"","BLUEMONT","CLARKE","VA","US",39.142146,-77.866468
"",14900,"CONFERENCE CENTER DR","CHANTILLY","FAIRFAX","VA","US",38.873934,-77.461939
"THE PURE PASTY COMPANY",128C,"MAPLE AVE W","VIENNA","FAIRFAX","VA","US",44.40662476,-68.59610059
"DIRT FARM BREWERY",18701,"FOGGY BOTTOM RD","BLUEMONT","LOUDON","VA","US",39.099655,-77.836975
"",818,"FERNDALE TERRACE NE","LEESBURG","LOUDOUN","VA","US",39.124843,-77.535445
"",,"OATLANDS PLANTATION LN","OATLANDS","LOUDOUN","VA","US",39.04071,-77.61682
"",,"PURCELLVILLE GATEWAY DR","PURCELLVILLE","LOUDOUN","VA","US",39.136193,-77.693198
"THE CAPITAL GRILLE RESTAURANT",1861,,"MCLEAN","FAIRFAX","VA","US",38.915635,-77.22573
"",,"","COLONIAL BEACH","WESTMORELAND","VA","US",38.25075,-76.9602533333333
