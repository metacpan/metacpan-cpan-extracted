package Geo::Coder::Free::Local;

use strict;
use warnings;

use Geo::Location::Point;
use Geo::StreetAddress::US;
use Lingua::EN::AddressParse;
use Locale::CA;
use Locale::US;
use Text::xSV::Slurp;

=head1 NAME

Geo::Coder::Free::Local -
Provides an interface to locations that you know yourself.
I have found locations by using GPS apps on a smartphone and by
inspecting GeoTagged photographs.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
use constant	LIBPOSTAL_UNKNOWN => 0;
use constant	LIBPOSTAL_INSTALLED => 1;
use constant	LIBPOSTAL_NOT_INSTALLED => -1;
our $libpostal_is_installed = LIBPOSTAL_UNKNOWN;

# See also lib/Geo/Coder/Free.pm
our %alternatives = (
	'ST LAWRENCE, THANET, KENT' => 'RAMSGATE, KENT',
	'ST PETERS, THANET, KENT' => 'ST PETERS, KENT',
	'MINSTER, THANET, KENT' => 'RAMSGATE, KENT',
);

=head1 SYNOPSIS

    use Geo::Coder::Free::Local;

    my $geocoder = Geo::Coder::Free::Local->new();
    my $location = $geocoder->geocode(location => 'Ramsgate, Kent, UK');

=head1 DESCRIPTION

Geo::Coder::Free::Local provides an interface to your own location data.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Free::Local->new();

=cut

sub new {
	my($proto, %param) = @_;
	my $class = ref($proto) || $proto;

	# Geo::Coder::Free::Local->new not Geo::Coder::Free::Local::new
	return unless($class);

	my $rc = {
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
		)
	};

	return bless $rc, $class;
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

	my $lc = lc($location);
	foreach my $row(@{$self->{'data'}}) {
		my $rc = Geo::Location::Point->new($row);
		my $str = lc($rc->as_string());

		if($str eq $lc) {
			return $rc;
		}
		if($str =~ /, us$/) {
			if("${str}a" eq $lc) {
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
		if(my $error = $ap->parse($l)) {
			# Carp::croak($ap->report());
			# ::diag('Address parse failed: ', $ap->report());
		} else {
			my %c = $ap->components();
			# ::diag(Data::Dumper->new([\%c])->Dump());
			my %addr = ( 'location' => $l );
			my $street = $c{'street_name'};
			if(my $type = $c{'street_type'}) {
				$type = uc($type);
				if($type eq 'STREET') {
					$street = "$street ST";
				} elsif($type eq 'ROAD') {
					$street = "$street RD";
				} elsif($type eq 'AVENUE') {
					$street = "$street AVE";
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
			if(my $rc = $self->_search(\%addr, ('number', 'road', 'city', 'state', 'country'))) {
				return $rc;
			}
			if($addr{'number'}) {
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
					if($href->{'type'} && (my $type = Geo::Coder::Free::_normalize($href->{'type'}))) {
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
							return $rc;
						}
					}
					if(my $rc = $self->_search(\%addr, ('road', 'city', 'state', 'country'))) {
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
			my $state = $addr[3];
			if(length($state) > 2) {
				if(my $twoletterstate = Locale::US->new()->{state2code}{uc($state)}) {
					$state = $twoletterstate;
				}
			}
			if(length($state) == 2) {
				my %addr = (
					number => $addr[0],
					road => $addr[1],
					city => $addr[2],
					state => $state,
					country => 'US'
				);
				if(my $rc = $self->_search(\%addr, ('number', 'road', 'city', 'state', 'country'))) {
					# ::diag(Data::Dumper->new([$rc])->Dump());
					$rc->{'country'} = 'US';
					return $rc;
				}
			}
		}
	}

	# Finally try libpostal,
	# which is good but uses a lot of memory
	if($libpostal_is_installed == LIBPOSTAL_UNKNOWN) {
		if(eval { require Geo::libpostal; } ) {
			Geo::libpostal->import();
			$libpostal_is_installed = LIBPOSTAL_INSTALLED;
		} else {
			$libpostal_is_installed = LIBPOSTAL_NOT_INSTALLED;
		}
	}

	if(($libpostal_is_installed == LIBPOSTAL_INSTALLED) && (my %addr = Geo::libpostal::parse_address($location))) {
		# ::diag(Data::Dumper->new([\%addr])->Dump());
		$addr{'location'} = $location;
		if($addr{'country'} && $addr{'state'} && ($addr{'country'} =~ /^(Canada|United States|USA|US)$/i)) {
			if(my $street = $addr{'road'}) {
				$street = uc($street);
				if($street =~ /(.+)\s+STREET$/) {
					$street = "$1 ST";
				} elsif($street =~ /(.+)\s+ROAD$/) {
					$street = "$1 RD";
				} elsif($street =~ /(.+)\s+AVENUE$/) {
					$street = "$1 AVE";
				} elsif($street =~ /(.+)\s+AVENUE\s+(.+)/) {
					$street = "$1 AVE $2";
				} elsif($street =~ /(.+)\s+COURT$/) {
					$street = "$1 CT";
				} elsif($street =~ /(.+)\s+CIRCLE$/) {
					$street = "$1 CIR";
				} elsif($street =~ /(.+)\s+DRIVE$/) {
					$street = "$1 DR";
				} elsif($street =~ /(.+)\s+PARKWAY$/) {
					$street = "$1 PKWY";
				} elsif($street =~ /(.+)\s+GARDENS$/) {
					$street = "$1 GRDNS";
				} elsif($street =~ /(.+)\s+LANE$/) {
					$street = "$1 LN";
				} elsif($street =~ /(.+)\s+PLACE$/) {
					$street = "$1 PL";
				} elsif($street =~ /(.+)\s+CREEK$/) {
					$street = "$1 CRK";
				}
				$street =~ s/^0+//;	# Turn 04th St into 4th St
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
				if(my $rc = $self->_search(\%addr, ('number', 'road', 'city', 'state_district', 'state', 'country'))) {
					return $rc;
				}
			}
			if(my $rc = $self->_search(\%addr, ('number', 'road', 'city', 'state', 'country'))) {
				return $rc;
			}
			if($addr{'number'}) {
				if(my $rc = $self->_search(\%addr, ('road', 'city', 'state', 'country'))) {
					return $rc;
				}
			}
		}
	}

	$location = uc($location);
	foreach my $left(keys %alternatives) {
		# ::diag("$location/$left");
		if($location =~ $left) {
			# ::diag($left, '=>', $alternatives{$left});
			$location =~ s/$left/$alternatives{$left}/;
			$param{'location'} = $location;
			# ::diag(__LINE__, ": $location");
			if(my $rc = $self->geocode(\%param)) {
				# ::diag(__LINE__, ": $location");
				return $rc;
			}
		}
	}
	return;
}

# $data is a hashref to data such as returned by Geo::libpostal::parse_address
# @columns is the key names to use in $data
sub _search {
	my ($self, $data, @columns) = @_;

	my $location;

	# FIXME: linear search is slow
	# ::diag(Data::Dumper->new([\@columns, $data])->Dump());
	foreach my $row(@{$self->{'data'}}) {
		my $match = 1;

		# ::diag(Data::Dumper->new([$self->{data}])->Dump());

		foreach my $column(@columns) {
			# ::diag("$column: ", $row->{$column}, '/', $data->{$column});
			if($data->{$column}) {
				if(!defined($row->{$column})) {
					$match = 0;
					last;
				}
				if(uc($row->{$column}) ne uc($data->{$column})) {
					$match = 0;
					last;
				}
			}
		}
		# ::diag("match: $match");
		if($match) {
			return Geo::Location::Point->new(
				'lat' => $row->{'latitude'},
				'long' => $row->{'longitude'},
				'location' => $data->{'location'}
			);
		}
	}
}

=head2	reverse_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

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

	my @rc;
	foreach my $row(@{$self->{'data'}}) {
		if(defined($row->{'latitude'}) && defined($row->{'longitude'})) {
			if(_equal($row->{'latitude'}, $latitude, 4) &&
			   _equal($row->{'longitude'}, $longitude, 4)) {
				my $point = Geo::Location::Point->new($row);
				if(wantarray) {
					push @rc, $point->as_string();
				} else {
					return $point->as_string();
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

=head1 SEE ALSO

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

=cut

1;

__DATA__
"name","number","road","city","state_district","state","country","latitude","longitude"
"ST ANDREWS CHURCH",,"CHURCH HILL","EARLS COLNE",,"ESSEX","GB",51.926793,0.70408
"WESTWOOD CROSS",23,"MARGATE ROAD","BROADSTAIRS",,"KENT","GB",51.358967,1.391367
"RECULVER ABBEY",,"RECULVER","HERNE BAY",,"KENT","GB",51.37875,1.1955
"NEW INN",2,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.334522,1.314417,
"HOLIDAY INN EXPRESS",,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.34320725,1.31680853
"",106,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.33995174,1.31570211
"",114,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.34015944,1.31580976
"MINSTER CEMETERY",116,"TOTHILL ST","RAMSGATE",,"KENT","GB",51.34203083,1.31609075
"ST MARY THE VIRGIN CHURCH",,"CHURCH ST","RAMSGATE",,"KENT","GB",51.33090893,1.31559716
"",20,"MELBOURNE AVE","RAMSGATE",,"KENT","GB",51.34772374,1.39532565
"TOBY CARVERY",,"NEW HAINE ROAD","RAMSGATE",,"KENT","GB",51.357510,1.388894
"",,"WESTCLIFF PROMENADE","RAMSGATE",,"KENT","GB",51.32711,1.406806
"TOWER OF LONDON",35,"TOWER HILL","LONDON",,"LONDON","GB",51.5082675,-0.0754225
"",5350,"CHILLUM PLACE NE","WASHINGTON",,"DC","US",38.955403,-76.996241
"NCBI",,"MEDLARS DR","BETHESDA","MONTGOMERY","MD","US",38.99516556,-77.09943963
"",,"CENTER DR","BETHESDA","MONTGOMERY","MD","US",38.99698114,-77.10031119
"",,"NORFOLK AVE","BETHESDA","MONTGOMERY","MD","US",38.98939358,-77.09819543
"THE ATRIUM AT ROCK SPRING PARK",6555,"ROCKLEDGE DR","BETHESDA","MONTGOMERY","MD","US",39.028326,-77.136774
"ALBERT EINSTEIN HIGH SCHOOL",11135,"NEWPORT MILL RD","KENSINGTON","MONTGOMERY","MD","US",39.03869019,-77.0682871
"POST OFFICE",10325,"KENSINGTON PKWY","KENSINGTON","MONTGOMERY","MD","US",39.02554455,-77.07178215
"NEWPORT MILL MIDDLE SCHOOL",11311,"NEWPORT MILL RD","KENSINGTON","MONTGOMERY","MD","US",39.0416107,-77.06884708
"SAFEWAY",10541,"HOWARD AVE","KENSINGTON","MONTGOMERY","MD","US",39.02822438,-77.0755196
"HAIR CUTTERY",3731,"CONNECTICUT AVE","KENSINGTON","MONTGOMERY","MD","US",39.03323865,-77.07368044
"STROSNIDERS",10504,"CONNECTICUT AVE","KENSINGTON","MONTGOMERY","MD","US",39.02781493,-77.07740792
"ARCOLA HEALTH AND REHABILITATION CENTER",901,"ARCOLA AVE","SILVER SPRING","MONTGOMERY","MD","US",39.036439,-77.025502
"FOREST GLEN MEDICAL CENTER",9801,"GEORGIA AVE","SILVER SPRING","MONTGOMERY","MD","US",39.016042,-77.042148
"LA CASITA PUPESERIA AND MARKET",8214,"PINEY BRANCH ROAD","SILVER SPRING","MONTGOMERY","MD","US",38.993369,-77.009501
"SNIDERS",1936,"SEMINARY RD","SILVER SPRING","MONTGOMERY","MD","US",39.0088797,-77.04162824
"",1954,"SEMINARY RD","SILVER SPRING","MONTGOMERY","MD","US",39.008961,-77.04303
"",1956,"SEMINARY RD","SILVER SPRING","MONTGOMERY","MD","US",39.008845,-77.043317
"",9315,"WARREN ST","SILVER SPRING","MONTGOMERY","MD","US",39.00881,-77.048953
"",9411,"WARREN ST","SILVER SPRING","MONTGOMERY","MD","US",39.010436,-77.04855
"SILVER DINER",12276,"ROCKVILLE PIKE","ROCKVILLE","MONTGOMERY","MD","US",39.05798753,-77.12165374
"",1605,"VIERS MILL ROAD","ROCKVILLE","MONTGOMERY","MD","US",39.07669788,-77.12306436
"",1406,"LANGBROOK PLACE","ROCKVILLE","MONTGOMERY","MD","US",39.075583,-77.123833
"BP",2601,"FOREST GLEN ROAD","SILVER SPRING","MONTGOMERY","MD","US",39.0147541,-77.05466857
"OMEGA STUDIOS",12412,,"ROCKVILLE","MONTGOMERY","MD","US",39.06412645,-77.11252263
"",7001,"CRADLEROCK FARM COURT","COLUMBIA","HOWARD","MD","US",39.190009,-76.841152
"BANGOR AIRPORT",,"GODFREY BOULEVARD","BANGOR","PENOBSCOT","ME","US",44.406700,-68.597114,
"",86,"ALLEN POINT LANE","BLUE HILLS","HANCOCK","ME","US",44.35378018,-68.57383976
"TRADEWINDS",15,"SOUTH STREET","BLUE HILLS","HANCOCK","ME","US",44.40670019,-68.59711438
"RITE AID",17,"SOUTH STREET","BLUE HILLS","HANCOCK","ME","US",44.40662476,-68.59610059
"",,"DOUGLAS AVE","FORT WAYNE","ALLEN","IN","US",41.074247,-85.138531
"JOHN GLENN AIRPORT",4600,,"COLUMBUS","FRANKLIN","OH","US",39.997959,-82.88132
"MIDDLE RIDGE PLAZA",,,"AMHERST","LOHRAIN","OH","US,41.379695,-82.222877
"RESIDENCE INN BY MARRIOTT",6364,"FRANTZ RD","DUBLIN",,"OH","US",40.097097,-83.123745
"TOWPATH TRAVEL PLAZA",,,"BROADVIEW HEIGHTS","CUYAHOGA","OH","US",41.291654,-81.675815
"NEW STANTON SERVICE PLAZA",,,"HEMPFIELD",,"PA","US",40.206267,-79.565682
"SOUTH SOMERSET SERVICE PLAZA",,,"SOMERSET","SOMERSET","PA","US",39.999154,-79.046526
"THE PURE PASTY COMPANY",128C,"MAPLE AVE W","VIENNA","FAIRFAX","VA","US",44.40662476,-68.59610059
"THE CAPITAL GRILLE RESTAURANT",1861,,"MCLEAN","FAIRFAX","VA","US",38.915635,-77.22573
