package Geo::Location::Point;

use 5.10.0;	# For the //= operator
use strict;
use warnings;

use Carp;
use GIS::Distance;
use Params::Get 0.13;
use Readonly;
use Scalar::Util;

use overload (
	'==' => \&equal,
	'!=' => \&not_equal,
	'""' => \&as_string,
	bool => sub { 1 },
	fallback => 1	# So that boolean tests don't cause as_string to be called
);

=head1 NAME

Geo::Location::Point - Location information

=head1 VERSION

Version 0.19

=cut

our $VERSION = '0.19';

=head1 SYNOPSIS

Geo::Location::Point encapsulates geographical point data with latitude and longitude.
It supports distance calculations,
comparison between points,
and provides various convenience methods for attributes like latitude, longitude, and related string representations.

    use Geo::Location::Point;

    my $location = Geo::Location::Point->new(latitude => 0.01, longitude => -71);

=head1 SUBROUTINES/METHODS

=head2 new

Initialise a new object, accepting latitude and longitude via a hash or hash reference.
Takes one optional argument 'key' which is an API key for L<https://timezonedb.com> for looking up timezone data.

    $location = Geo::Location::Point->new({ latitude => 0.01, longitude => -71 });

=cut

sub new {
	my $class = shift;
	my $params = Params::Get::get_params(undef, \@_);

	if(!defined($class)) {
		carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		return;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %{$params} }, ref($class);
	}

	$params->{'lat'} //= $params->{'latitude'} // $params->{'Latitude'};
	if(!defined($params->{'lat'})) {
		Carp::carp(__PACKAGE__, ': latitude not given');
		return;
	}
	if(abs($params->{'lat'}) > 90) {
		Carp::carp(__PACKAGE__, ': ', $params->{'lat'}, ': invalid latitude');
		return;
	}

	$params->{'long'} //= $params->{'longitude'} // $params->{'Longitude'};
	if(!defined($params->{'long'})) {
		Carp::carp(__PACKAGE__, ': longitude not given');
		return;
	}
	if(abs($params->{'long'}) > 180) {
		Carp::carp(__PACKAGE__, ': ', $params->{'long'}, ': invalid longitude');
		return;
	}
	$params->{'lng'} = $params->{'long'};

	# Return the blessed object
	return bless $params, $class;
}

=head2 lat

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

=cut

sub lat {
	my $self = shift;

	return $self->{'lat'};
}

=head2 latitude

Synonym for lat().

=cut

sub latitude {
	my $self = shift;

	return $self->{'lat'};
}

=head2 long

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

=cut

sub long {
	my $self = shift;

	return $self->{'long'};
}

=head2	lng

Synonym for long().

=cut

sub lng {
	my $self = shift;

	return $self->{'long'};
}

=head2 longitude

Synonym for long().

=cut

sub longitude {
	my $self = shift;

	return $self->{'long'};
}

=head2	distance

Determine the distance between two geographical points,
returns a L<Class::Measure::Length> object.

=cut

sub distance {
	my ($self, $location) = @_;

	if(!defined($location)) {
		Carp::carp('Usage: ', __PACKAGE__, '->distance($location)');
		return;
	}

	$self->{'gis'} //= GIS::Distance->new();

	return $self->{'gis'}->distance($self->{'lat'}, $self->{'long'}, $location->lat(), $location->long());
}

=head2	equal

Check if two points are identical within a small tolerance.

    my $loc1 = Geo::Location::Point->new(lat => 2, long => 2);
    my $loc2 = Geo::Location::Point->new(lat => 2, long => 2);
    print ($loc1 == $loc2), "\n";	# Prints 1

=cut

sub equal {
	my $self = shift;
	my $other = shift;

	# return ($self->distance($other) <= 1e-5);
	# 1e-5 is about 1m, that's tolerant enough
	return((abs($self->lat() - $other->lat()) <= 1e-5) && (abs(($self->long() - $other->long())) <= 1e-5));
}

=head2	not_equal

Are two points different?

    my $loc1 = Geo::Location::Point->new(lat => 2, long => 2);
    my $loc2 = Geo::Location::Point->new(lat => 2, long => 2);
    print ($loc1 != $loc2), "\n";	# Prints 0

=cut

sub not_equal {
	my $self = shift;

	return(!$self->equal(shift));
}

=head2	tz

Returns the timezone of the location.
Needs L<TimeZone::TimeZoneDB>.

=cut

sub tz {
	my $self = shift;

	if(defined($self->{'key'})) {
		return $self->{'tz'} if(defined($self->{'tz'}));

		if(!defined($self->{'timezonedb'})) {
			unless(TimeZone::TimeZoneDB->can('get_time_zone')) {
				require TimeZone::TimeZoneDB;
				TimeZone::TimeZoneDB->import();
			}

			$self->{'timezonedb'} = TimeZone::TimeZoneDB->new(key => $self->{'key'});
		}
		$self->{'tz'} = $self->{'timezonedb'}->get_time_zone($self)->{'zoneName'};

		return $self->{'tz'};
	}
}

=head2	timezone

Synonym for tz().

=cut

sub timezone {
	my $self = shift;

	return $self->tz();
}

=head2	as_string

Generate a human-readable string describing the point,
incorporating additional attributes like city or country if available.

=cut

sub as_string {
	my $self = shift;

	if($self->{'location'}) {
		return $self->{'location'};
	}

	my $rc = $self->{'name'};
	if($rc) {
		$rc = ucfirst(lc($rc));
	}

	# TODO: make this order configurable
	# foreach my $field('house_number', 'number', 'road', 'street', 'AccentCity', 'city', 'county', 'region', 'state_district', 'state', 'country') {
	foreach my $field('house_number', 'number', 'road', 'street', 'city', 'county', 'region', 'state_district', 'state', 'country') {
		if(my $value = ($self->{$field} || $self->{ucfirst($field)})) {
			if($rc) {
				if(($field eq 'street') || ($field eq 'road')) {
					if($self->{'number'} || $self->{'house_number'}) {
						$rc .= ' ';
					} else {
						$rc .= ', '
					}
				} else {
					$rc .= ', ';
				}
			}
			my $leave_case = 0;
			if(my $country = $self->{'country'} // $self->{'Country'}) {
				if(uc($country) eq 'US') {
					if(($field eq 'state') || ($field eq 'region') || ($field eq 'country')) {
						$leave_case = 1;
						if(lc($field) eq 'country') {
							$value = 'US';
						}
					}
				} elsif(($country eq 'Canada') || ($country eq 'Australia')) {
					if($field eq 'state') {
						$leave_case = 1;
					}
				} elsif(uc($country) eq 'GB') {
					if($field eq 'country') {
						$leave_case = 1;
						$value = 'GB';
					}
				}
			}
			if($leave_case) {
				$rc .= $value;
			} else {
				$rc .= $self->_sortoutcase($value);
				if((($field eq 'street') || ($field eq 'road')) &&
				   ($rc =~ /(.+)\s([NS][ew])$/)) {
					# e.g South Street NW
					$rc = "$1 " . uc($2);
				}
			}
		}
	}

	return $self->{'location'} = $rc;
}

sub _sortoutcase
{
	# Use lc to ensure the input string is in lowercase before capitalisation,
	#	split to break the string into words,
	#	map to capitalise each word and
	#	join to concatenate the capitalised words back into a single string with spaces
	return join ' ', map { ucfirst } split ' ', lc($_[1]);
}

=head2	as_uri

Convert the point to a Geo URI scheme string (geo:latitude,longitude).
See L<https://en.wikipedia.org/wiki/Geo_URI_scheme>.
Arguably it should return a L<URI> object instead.

=cut

sub as_uri
{
	my $self = shift;

	return 'geo:' . $self->{'lat'} . ',' . $self->{'long'};
}

=head2	attr

Get or set arbitrary attributes, such as city or country.
A call with an argument sets the attribute and returns the value that was set;
a call without one reads it back and returns C<undef> if it was never set.

    $location->city('London');
    $location->country('UK');
    print $location->as_string(), "\n";
    print "$location\n";	# Calls as_string

It is the argument list, not the value, that decides whether a call is a read or a write,
so false values are attributes like any other and are stored and returned unchanged:

    $location->confidence(0);
    print 'matched: ', defined($location->confidence()) && $location->confidence(), "\n";

The upper case variant of the key is consulted
(but not overwritten) when the key as given has never been set,
which is how the MaxMind field names are read. An attribute that has been set,
however false, takes precedence over it.

=cut

sub AUTOLOAD {
	our $AUTOLOAD;
	my $key = $AUTOLOAD;

	$key =~ s/.*:://;

	return if($key eq 'DESTROY');

	my $self = shift;

	# The argument list, not the value, decides read or write. Testing the value here
	# (my $value = shift) meant a false value could neither be stored nor read back,
	# so e.g. a confidence of 0 looked like no data at all.
	if(@_) {
		my $value = shift;
		delete $self->{'location'};	# Invalidate the cache
		delete $self->{'tz'};	# Invalidate the cache
		return $self->{$key} = $value;
	}

	# Defined, not true: a stored 0 or empty string is the caller's data, so return it
	return $self->{$key} if(defined($self->{$key}));

	return $self->{ucfirst($key)};
}

# The accuracy levels a point may claim, most precise first.  This is the one
# place the vocabulary is written down: Geo::Coder::Free::Provenance reads it
# from here instead of keeping a copy of its own, so a level added to one of
# them cannot go missing from the other.  It is defined here because
# Geo::Coder::Free depends on this module, and not the other way round.
#
# It is read-only because it is shared.  %IS_ACCURACY_LEVEL below is taken from
# this list when the module loads, so a caller that pushed a level into the list
# would publish a vocabulary that accuracy() still refuses: the module would
# describe one set of levels and accept another, and every module that reads the
# list - Provenance's name for it included - would be speaking the same language
# as the list and not as the points.  A level that belongs in the vocabulary is
# added here, beside the validator it is checked against.
Readonly::Array my @ACCURACY_LEVELS => qw(address street postcode locality city region country);

# The list itself, rather than a copy of it: every module that speaks this
# vocabulary shares this one list, so the levels it reports are the levels a point
# accepts.
sub ACCURACY_LEVELS {
	return \@ACCURACY_LEVELS;
}

my %IS_ACCURACY_LEVEL = map { $_ => 1 } @ACCURACY_LEVELS;

# The fields a backend can match on, and the level each one justifies.  Keyed by
# level, because accuracy_for() walks ACCURACY_LEVELS in order: the most precise
# level with a matched field wins, and a level that is not in the vocabulary
# cannot come out of here.  'city' has no entry of its own - a city match is a
# locality, the most precise claim the centre of a city supports.
#
# This is the other half of the vocabulary, in the same place: the levels a
# point accepts and the rule that turns a backend's matched fields into one of
# them are defined together, so a rule cannot name a level accuracy() refuses,
# and a backend does not have to keep two modules in step to describe a match.
Readonly::Hash my %FIELDS_FOR_ACCURACY => (
	address  => [qw(house_number number)],
	street   => [qw(road street)],
	postcode => [qw(postcode post_code zip)],
	locality => [qw(city town name)],
	region   => [qw(state state_district county region)],
	country  => [qw(country)],
);

sub accuracy_for {
	my %field = map { lc($_) => 1 } @_;

	for my $level (@ACCURACY_LEVELS) {
		next unless(my $fields = $FIELDS_FOR_ACCURACY{$level});

		for my $field (@{$fields}) {
			return $level if($field{$field});
		}
	}

	# A match on a row with none of these fields is still a named place, and
	# every result promises an accuracy, so it is reported as a locality rather
	# than left unsaid.
	return 'locality';
}

# Read a slot the way AUTOLOAD reads it: a lower case key that was never set
# falls back to its upper case spelling, so a field the caller stored under the
# upper case name is still found.
sub _attribute {
	my ($self, $key) = @_;

	return $self->{$key} if(defined($self->{$key}));

	return $self->{ucfirst($key)};
}

# Write a slot the way AUTOLOAD writes it, invalidating the caches derived from
# the attributes: a validated accessor has to keep that promise too, or setting
# a city after reading as_string() would be invisible.
sub _set_attribute {
	my ($self, $key, $value) = @_;

	delete $self->{'location'};
	delete $self->{'tz'};

	return $self->{$key} = $value;
}

# Passing undef clears an attribute, so every validated accessor accepts it;
# anything else has to be the type the field promises.
sub _check_string {
	my ($field, $value) = @_;

	return if(!defined($value));
	Carp::croak(__PACKAGE__, ": $field must be a string, not a ", ref($value)) if(ref($value));

	return $value;
}

sub _check_confidence {
	my ($value) = @_;

	return if(!defined($value));
	Carp::croak(__PACKAGE__, ': confidence must be a number from 0 to 1, not ',
		ref($value) ? ref($value) : $value)
		if(ref($value) || !Scalar::Util::looks_like_number($value) || ($value < 0) || ($value > 1));

	return $value;
}

sub _check_accuracy {
	my ($value) = @_;

	return if(!defined($value));
	Carp::croak(__PACKAGE__, ': unknown accuracy: ', ref($value) ? ref($value) : $value)
		if(ref($value) || !$IS_ACCURACY_LEVEL{$value});

	return $value;
}

=head2	geocoder

The distribution that produced the point, such as C<Geo::Coder::Free>.

    $location->geocoder('Geo::Coder::Free');

=cut

sub geocoder {
	my $self = shift;

	return $self->_attribute('geocoder') unless(@_);

	return $self->_set_attribute('geocoder', _check_string('geocoder', shift));
}

=head2	database

The database the distribution answered from, such as C<OpenAddresses>, C<Local>
or C<MaxMind>.

    $location->database('OpenAddresses');

=cut

sub database {
	my $self = shift;

	return $self->_attribute('database') unless(@_);

	return $self->_set_attribute('database', _check_string('database', shift));
}

=head2	confidence

How good the match is, from C<0> to C<1> inclusive, where C<1> is an exact
match. A confidence that is not a number, or that falls outside that range, is
rejected rather than stored.

    $location->confidence(0);		# Tried and rejected
    $location->confidence(0.8);		# A good match

=cut

sub confidence {
	my $self = shift;

	return $self->_attribute('confidence') unless(@_);

	return $self->_set_attribute('confidence', _check_confidence(shift));
}

=head2	ACCURACY_LEVELS

The accuracy levels a point may claim, most precise first: C<address> (a house
number), C<street>, C<postcode>, C<locality>, C<city>, C<region> and
C<country>.

This is the vocabulary, written down once here and read from here by
L<Geo::Coder::Free::Provenance> rather than copied, so the levels a point
accepts and the levels a backend reports cannot drift apart.  C<accuracy()>
accepts these and refuses anything else.

The rule that turns the fields a backend matched into one of these levels is
L</accuracy_for>, beside the list it returns a level from.

The list is read-only, and a caller that tries to add to it is refused, because
it is the list C<accuracy()> checks against: were it writable, a level pushed
into it would be published to every reader of this list while the module went on
refusing it.

    my $levels = Geo::Location::Point::ACCURACY_LEVELS();

=cut

=head2	accuracy_for

The accuracy a match can claim, from the fields that made it.  The most precise
field present decides: a house number makes it an C<address>, a road a
C<street>, a postcode a C<postcode>, a name or a city a C<locality>, a state or
region a C<region>, and a country a C<country>.  So a dataset row carrying only
a city, state and country is a C<locality>: a named place, not an address.

    my $level = Geo::Location::Point::accuracy_for(qw(house_number road city));

Always returns one of the L</ACCURACY_LEVELS>: a match on a row with none of the
fields above is still a named place, so it is reported as a C<locality> rather
than left unsaid, because every result promises an accuracy.

It is a function, not a method - the fields are what a backend matched, not
something a point carries - and it lives beside the vocabulary it returns a
level from, so the levels a point accepts and the rules that choose one of them
have a single home.

=cut

=head2	accuracy

How precise the coordinates behind a match can claim to be.  The levels are
those in L</ACCURACY_LEVELS>; anything else is rejected, because a reader
deciding what a point may claim about itself has to be able to trust the
value.

    $location->accuracy('city');

=cut

sub accuracy {
	my $self = shift;

	return $self->_attribute('accuracy') unless(@_);

	return $self->_set_attribute('accuracy', _check_accuracy(shift));
}

=head2	country

The country of the point, as the data spells it: C<GB>, C<US>, C<Canada>. It
is stored as given rather than normalised, so it is whatever the backend
matched.

    $location->country('GB');

=cut

sub country {
	my $self = shift;

	return $self->_attribute('country') unless(@_);

	return $self->_set_attribute('country', _check_string('country', shift));
}

=head2	city

The city, town or similar locality of the point.

    $location->city('London');

=cut

sub city {
	my $self = shift;

	return $self->_attribute('city') unless(@_);

	return $self->_set_attribute('city', _check_string('city', shift));
}

=head2	state

The state, province or region of the point.

    $location->state('KY');

=cut

sub state {
	my $self = shift;

	return $self->_attribute('state') unless(@_);

	return $self->_set_attribute('state', _check_string('state', shift));
}

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

There is no validation on the attribute in the AUTOLOAD method,
so typos such as "citty" will not be caught.
C<geocoder>, C<database>, C<confidence>, C<accuracy>, C<country>, C<city> and
C<state> have documented accessors of their own that do check what they are
given,
but they are the only attributes that do,
and C<new()> stores whatever it is handed without checking it,
so a provenance field set through the constructor can still be any value.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Geo-Location-Point/coverage/>

=back

L<GIS::Distance>,
L<Geo::Point>,
L<TimeZone::TimeZoneDB>.

=head1 LICENSE AND COPYRIGHT

Copyright 2019-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
