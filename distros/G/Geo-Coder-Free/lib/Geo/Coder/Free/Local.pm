package Geo::Coder::Free::Local;

use strict;
use warnings;
use autodie qw(:all);

use Carp;
use Geo::Location::Point 0.19;	# 0.16 stores false values; 0.19 derives an accuracy from the fields matched
use Geo::Coder::Free::MissCache;
use Geo::Coder::Free::Provenance qw(GEOCODER);
use Geo::Coder::Free::Utils qw(_abbreviate _normalize);
use Geo::StreetAddress::US;
use Lingua::EN::AddressParse;
use Locale::CA;
use Locale::US;
use Object::Configure;
use Params::Get;
use Readonly;
use Text::xSV::Slurp;
# Imported functions are not methods: without this, $obj->croak() and the like
# would resolve.
use namespace::clean;

=encoding utf-8

=head1 NAME

Geo::Coder::Free::Local - Geocode using user-curated local data

=head1 VERSION

Version 0.51

=cut

our $VERSION = '0.51';

=head1 SYNOPSIS

    use Geo::Coder::Free::Local;

    my $geocoder = Geo::Coder::Free::Local->new();
    my $location = $geocoder->geocode(location => 'Ramsgate, Kent, UK');
    printf "lat=%.6f lon=%.6f\n", $location->lat(), $location->long();

=head1 DESCRIPTION

Provides geocoding via a user-curated CSV dataset embedded in the module's
C<__DATA__> section.  Locations in the data were verified by GPS and by
inspecting geotagged photographs.  The data is read once at construction time
and indexed for fast lookup.

This is the highest-priority backend tried by C<Geo::Coder::Free>.

=head1 LIMITATIONS

=over 4

=item * The embedded C<__DATA__> dataset covers only a small set of hand-picked locations.
There is no mechanism for non-authors to contribute data without patching the module.

=item * Canadian and Australian address parsing is not yet implemented; those queries return C<undef>.

=item * C<_search> performs an O(n) linear scan through all rows.  The hash-based
index in C<new()> handles exact string matches; no index exists for partial field matches.

=item * C<our %alternatives> duplicates mappings in C<Geo::Coder::Free::__DATA__>.
Both should be consolidated into a shared external config file.

=item * C<$libpostal_is_installed> is a module-level (effectively global) flag.
Not thread-safe in a forking or threaded Perl deployment.

=item * The C<__DATA__> filehandle is a one-shot resource.  The first call to
C<new()> exhausts it with C<my @data = E<lt>DATAE<gt>>; every subsequent
C<new()> in the same process reads zero rows and builds an empty index.
Construct exactly one C<Local> object per process and share it.

=item * The hash-index key is C<lc(Geo::Location::Point-E<gt>new($row)-E<gt>as_string())>,
which B<includes the C<name> field>.  To get a direct index hit the caller must
supply the full string with the venue/place name as the leading component;
an address that omits the name falls through to the slower O(n) C<_search> path.

=back

=cut

# Libpostal detection states - avoid magic numbers
use constant LIBPOSTAL_UNKNOWN       => 0;
use constant LIBPOSTAL_INSTALLED     => 1;
use constant LIBPOSTAL_NOT_INSTALLED => -1;

# Module-level singleton flags - see LIMITATIONS re: thread safety.
our $libpostal_is_installed = LIBPOSTAL_UNKNOWN;

# Lazily initialised Locale singletons to avoid repeated object construction
# (Locale::US->new() and Locale::CA->new() are called multiple times per geocode;
# caching them reduces object churn on busy lookups).
my $_locale_us;
my $_locale_ca;

# Confidence thresholds for _search results, aligned with OpenAddresses backend
Readonly::Scalar my $CONF_EXACT  => 1.0;
Readonly::Scalar my $CONF_HIGH   => 0.7;
Readonly::Scalar my $CONF_MEDIUM => 0.5;

# Hard-coded place-name aliases for ambiguous or database-inconsistent locations.
# MAINTENANCE NOTE: the same mappings appear in Geo::Coder::Free::__DATA__.
# Both should eventually be replaced by a shared external config file.
our %alternatives = (
	'ST LAWRENCE, THANET, KENT' => 'RAMSGATE, KENT',
	'ST PETERS, THANET, KENT'   => 'ST PETERS, KENT',
	'MINSTER, THANET, KENT'     => 'RAMSGATE, KENT',
	'TYNE AND WEAR'             => 'BOROUGH OF NORTH TYNESIDE',
);

=head1 METHODS

=head2 new

=head3 SYNOPSIS

    my $geocoder = Geo::Coder::Free::Local->new();
    my $geocoder = Geo::Coder::Free::Local->new(cache => $chi_cache);

=head3 DESCRIPTION

Constructor.  Reads the C<__DATA__> CSV block, builds a hash-based lookup
index, and derives the geographic centre of any city/state/country cluster
containing three or more data points.

B<One-shot filehandle>: the C<DATA> handle is consumed on the first call to
C<new()>.  Any subsequent call to C<new()> returns an object whose dataset and
index are both empty.  In code that constructs multiple C<Local> objects (e.g.
in tests) construct B<exactly one> instance and reuse it across all callers.

=head3 API SPECIFICATION

=head4 input

    # Input schema (Params::Validate::Strict)
    cache => { type => 'object', optional => 1, can => ['get', 'set'] }  # CHI-compatible cache object

=head4 output

    # Output schema (Return::Set)
    { type => 'object', isa => 'Geo::Coder::Free::Local' }

=head3 FORMAL SPECIFICATION

    LocalState ::= ⟨⟨ data  : seq Row;
                       index : Map[STRING → Row];
                       cache : Map[STRING → Point] ⟩⟩

    Init : Params → LocalState
    ∀ p : Params •
      let rows    == parse_csv(__DATA__) ∪ geographic_centres(__DATA__) •
      let idx_key == λ r • lc(Point(r).as_string()) •
      LocalState.index = { idx_key(r) ↦ r | r ∈ rows }

=cut

sub new {
	my $class = shift;
	my $params = Params::Get::get_params(undef, @_) // {};

	if (!defined($class)) {
		$class = __PACKAGE__;	# FIXME: only works when no arguments are given
	} elsif (ref($class)) {
		return bless { %{$class}, %{$params} }, ref($class);
	}

	$params = Object::Configure::configure($class, $params);

	my @data = <DATA>;

	my $self = bless {
		data => xsv_slurp(
			shape    => 'aoh',
			text_csv => {
				allow_loose_quotes => 1,
				blank_is_undef     => 1,
				empty_is_undef     => 1,
				binary             => 1,
				escape_char        => '\\',
			},
			string => \join('', grep { !/^\s*(#|$)/ } @data),
		),
		%{$params},
	}, $class;

	# Derive geographic centres from clusters of 3+ co-located data points,
	# adding implicit town/city records to the dataset.
	my $towns = _find_geographic_centres($self->{'data'});
	push @{$self->{'data'}}, @{$towns} if $towns;

	# Build a hash index on the stringified Geo::Location::Point representation
	# so that exact-match lookups avoid the O(n) scan in _search.
	for my $row (@{$self->{'data'}}) {
		my $key = lc(Geo::Location::Point->new($row)->as_string());
		$self->{'index'}{$key} = $row;
	}

	# Build an O(1) region existence index used by geocode() to skip the O(n)
	# grep before _search when no rows for the requested state/country exist.
	# Major: every (state|country) pair in the dataset is represented here.
	# Minor: if geocode's target pair is absent, _search can never match.
	# Conclusion: early return is safe - eliminates the O(n) grep per call.
	for my $row (@{$self->{'data'}}) {
		my $rk = uc($row->{'state'} // '') . '|' . uc($row->{'country'} // '');
		$self->{'region_index'}{$rk} = 1;
	}

	return $self;
}

# What this backend counts as a miss, and where the whole process remembers
# it.  The data is in __DATA__, so every instance has the same data and a miss
# found by one is a miss for all of them.
sub _miss_scope {
	return Geo::Coder::Free::MissCache->scope_for('Local');
}

sub _missed {
	my ($self, $lc) = @_;

	return Geo::Coder::Free::MissCache->missed($self->_miss_scope(), $lc);
}

sub _remember_miss {
	my ($self, $lc) = @_;

	Geo::Coder::Free::MissCache->remember($self->_miss_scope(), $lc);
	return;
}

=head2 reads

    my $count = $geocoder->reads();

How many times this backend has searched its dataset since the object was
created.  A lookup answered from the index, from the result cache or from the
shared miss cache does not increase it, so C<geocode_many()> can take the count
before and after a value to tell a lookup that cost a search from one that was
answered from a cache.

=head3 API SPECIFICATION

=head4 input

    # Input schema (Params::Validate::Strict)
    # none

=head4 output

    # Output schema (Return::Set)
    { type => 'integer', min => 0 }   # 0 for a new object

=cut

sub reads {
	my $self = shift;

	return $self->{'reads'} // 0;
}

=head2 geocode

=head3 SYNOPSIS

    my $pt = $geocoder->geocode(location => '203 E Chatsworth Rd, Reisterstown, Baltimore, MD, US');
    print $pt->lat(), "\n";

    # All calling forms are accepted:
    $geocoder->geocode('203 E Chatsworth Rd, Reisterstown, MD, US');
    $geocoder->geocode({ location => '203 E Chatsworth Rd, Reisterstown, MD, US' });

=head3 API SPECIFICATION

=head4 input

    # Input schema (Params::Validate::Strict)
    location => { type => 'scalar' }  # address string; must contain at least two commas

=head4 output

    # Output schema (Return::Set)
    { type => 'object', isa => 'Geo::Location::Point', optional => 1 }

=head3 PROVENANCE

Every result carries C<geocoder>, C<database>, C<confidence> and C<accuracy>
(section 2.1 of F<BI-Phase6-Dependency-Specs.md>).  This backend reports
C<database> as C<Geo::Coder::Free::Local>, and C<accuracy> is what the matched
columns justify: a house number makes it an C<address>, a road a C<street>, a
name or city a C<locality>, a state a C<region> and a country a C<country>.  A
lookup answered from the index, which matches a whole row, is an exact match
(C<confidence> of 1.0) whose accuracy comes from the row's own fields - so a
derived geographic centre, which carries a city, state and country and nothing
narrower, is a C<locality>.

=head3 MESSAGES

    Usage: ...::geocode(...)   No location argument given.

=head3 FORMAL SPECIFICATION

    Geocode : STRING → Point?
    ∀ addr : STRING •
      let norm == lc(replace_usa(addr)) •
      (norm ∈ cache ⟹ result = cache[norm]) ∧
      (norm ∈ index ⟹ result = index[norm]) ∧
      (¬ result ⟹ result = parse_and_search(addr))

=head3 PSEUDOCODE

    normalise @_ into %params
    reject if location does not contain two or more commas (not a full address)
    check cache; return hit
    check hash index; return hit and cache it
    # index key includes the 'name' field; supply the venue/place name as the
    # leading address component to guarantee an index hit
    attempt country-specific parser (US, GB; skip CA/AU pending implementation)
    attempt Geo::StreetAddress::US for "..., USA" addresses
    attempt Geo::Address::Parser
    attempt Geo::libpostal (large memory footprint; loaded lazily)
    attempt 4-part regex decomposition (name/road/city/state/country)
    attempt %alternatives mapping
    return undef

=cut

sub geocode {
	my $self = shift;

	# Handle being called as a function rather than a method
	if (!ref($self)) {
		if (scalar @_) {
			return __PACKAGE__->new()->geocode(@_);
		} elsif (!defined($self)) {
			Carp::croak('Usage: ', __PACKAGE__, '::geocode(location => $location)');
		} elsif ($self eq __PACKAGE__) {
			Carp::croak("Usage: $self", '::geocode(location => $location)');
		}
		return __PACKAGE__->new()->geocode($self);
	} elsif (ref($self) eq 'HASH') {
		return __PACKAGE__->new()->geocode($self);
	}

	my %params = _normalize_args(
		'Usage: ' . __PACKAGE__ . '::geocode(location => $location)',
		'location', @_
	);

	my $location = $params{'location'}
		or Carp::croak('Usage: geocode(location => $location)');

	# Normalise the lookup key - "USA" is treated the same as "US"
	my $lc = lc($location);
	$lc =~ s/,\s*usa$/, us/i;

	return $self->{'cache'}{$lc}  if exists $self->{'cache'}{$lc};
	return $self->_cache_and_return($lc, $self->_result_for($self->{'index'}{$lc}))
		if exists $self->{'index'}{$lc};

	# A miss found by an earlier instance, or an earlier call through this
	# one, means the same search would find nothing again: the data does not
	# change while the process runs.  clear_miss_cache() is for when it has.
	return if $self->_missed($lc);

	# This backend only handles full addresses (at least "road, city, country")
	return $self->_remember_miss($lc) if $location !~ /,.+,/;

	my $ap;
	if ($location =~ /USA?$/ || $location =~ /United States$/) {
		$ap = $self->{'ap'}{'us'} //= Lingua::EN::AddressParse->new(
			country => 'US', auto_clean => 1, force_case => 1, force_post_code => 0
		);
	} elsif ($location =~ /(England|Scotland|Wales|Northern Ireland|UK|GB)$/i) {
		$ap = $self->{'ap'}{'gb'} //= Lingua::EN::AddressParse->new(
			country => 'GB', auto_clean => 1, force_case => 1, force_post_code => 0
		);
	} elsif ($location =~ /Canada$/) {
		# TODO: Canadian address parsing not yet implemented
		return $self->_remember_miss($lc);
	} elsif ($location =~ /Australia$/) {
		# TODO: Australian address parsing not yet implemented
		return $self->_remember_miss($lc);
	}

	if ($ap) {
		my $l = $location;
		$l =~ s/(.+), (England|UK)$/$1, GB/i;

		if ($ap->parse($l) == 0) {
			my %c = $ap->components();
			my %addr = (location => $l);

			if (my $street = $c{'street_name'}) {
				if (my $type = $c{'street_type'}) {
					my $abbrev = _abbreviate($type);
					$street .= ' ' . ($abbrev || $type);
					$street .= ' ' . $c{'street_direction_suffix'}
						if $c{'street_direction_suffix'};
					$street =~ s/^0+//;
					$addr{'road'} = $street;
				}
			}

			if (length($c{'subcountry'}) == 2) {
				$addr{'state'} = $c{'subcountry'};
			} else {
				my $country_raw = $c{'country'} // '';
				if ($country_raw =~ /Canada/i) {
					$addr{'country'} = 'CA';
					$addr{'state'}   = _to_two_letter_state('Canada', $c{'subcountry'});
				} elsif ($country_raw =~ /^(United States|USA|US)$/i) {
					$addr{'country'} = 'US';
					$addr{'state'}   = _to_two_letter_state('US', $c{'subcountry'});
				} elsif ($country_raw) {
					$addr{'country'} = $country_raw;
					$addr{'state'}   = $c{'subcountry'} if $c{'subcountry'};
				}
			}
			$addr{'number'} = $c{'property_identifier'};
			$addr{'city'}   = $c{'suburb'};

			if (my $rc = $self->_search(\%addr, qw(number road city state country))) {
				return $self->_cache_and_return($lc, $rc);
			}
			if ($addr{'number'}) {
				if (my $rc = $self->_search(\%addr, qw(road city state country))) {
					return $self->_cache_and_return($lc, $rc);
				}
			}

			# Abort early if no data at all matches this state/country -
			# saves traversing the full dataset for every remaining strategy.
			if (!defined($addr{'country'})) {
				$addr{'country'} = $l =~ /(United States|USA|US)$/i ? 'US'
					: Carp::croak("TODO: extract country from $l");
			}
			# O(1) region check via index built in new() - replaces the former
			# O(n) grep across all rows.
			# Major: region_index maps every (state|country) pair in the dataset.
			# Minor: if target pair is absent, no _search call can match.
			# Conclusion: early return is equivalent and faster.
			my $rk = uc($addr{'state'} // '') . '|' . uc($addr{'country'} // '');
			return $self->_remember_miss($lc) unless $self->{'region_index'}{$rk};
		}
	}

	if ($location =~ /^(.+?)[,\s]+(United States|USA|US)$/i) {
		my $l = $1;
		$l =~ tr/,/ /;
		$l =~ s/\s{2,}/ /g;

		# Geo::StreetAddress::US is buggy (RT#122617) - skip county-style addresses
		if ($location !~ /\sCounty,/i) {
			my $href = Geo::StreetAddress::US->parse_location($l)
			        // Geo::StreetAddress::US->parse_address($l);

			if ($href) {
				if (my $state = $href->{'state'}) {
					$state = _to_two_letter_state('US', $state) if length($state) > 2;
					my $city   = uc($href->{'city'} // '');
					if (my $street = $href->{'street'}) {
						if ($href->{'type'}) {
							$street .= ' ' . _abbreviate($href->{'type'});
						}
						$street .= ' ' . $href->{'suffix'}  if $href->{'suffix'};
						$street  = $href->{'prefix'} . " $street" if $href->{'prefix'};
						my %addr = (
							number  => $href->{'number'},
							road    => $street,
							city    => $city,
							state   => $state,
							country => 'US',
						);
						if ($href->{'number'}) {
							if (my $rc = $self->_search(\%addr, qw(number road city state country))) {
								$rc->{'country'} = 'US';
								return $self->_cache_and_return($lc, $rc);
							}
						}
						if (my $rc = $self->_search(\%addr, qw(road city state country))) {
							$rc->{'country'} = 'US';
							return $self->_cache_and_return($lc, $rc);
						}
						# G:S:US puts building name into street when number is absent
						if ($street && !$href->{'number'}) {
							$addr{'name'} = delete $addr{'road'};
							if (my $rc = $self->_search(\%addr, qw(name city state country))) {
								$rc->{'country'} = 'US';
								return $self->_cache_and_return($lc, $rc);
							}
						}
					}
				}
			}
		}

		# Fallback: try "name, street, town, state, US" split
		my @parts = split(/,\s*/, $location);
		if (scalar(@parts) == 5) {
			my $state = _to_two_letter_state('US', $parts[3]);
			if (length($state) == 2) {
				my %addr = (city => $parts[2], state => $state, country => 'US');
				if ($parts[0] !~ /^\d/) {
					$addr{'name'} = $parts[0];
					if ($parts[1] =~ /^(\d+)\s+(.+)/) {
						$addr{'number'} = $1;
						$addr{'road'}   = _normalize($2);
						if (my $rc = $self->_search(\%addr, qw(name number road city state country))) {
							$rc->{'country'} = 'US';
							return $self->_cache_and_return($lc, $rc);
						}
					} else {
						$addr{'road'} = _normalize($parts[1]);
						if (my $rc = $self->_search(\%addr, qw(name road city state country))) {
							$rc->{'country'} = 'US';
							return $self->_cache_and_return($lc, $rc);
						}
					}
				} else {
					$addr{'number'} = $parts[0];
					$addr{'road'}   = _normalize($parts[1]);
					if (my $rc = $self->_search(\%addr, qw(number road city state country))) {
						$rc->{'country'} = 'US';
						return $self->_cache_and_return($lc, $rc);
					}
				}
			}
		}
	}

	# Simple "Town, County, England" - no further sub-parsers will help
	if (($location =~ /[^,]+,[^,]+,.*England$/) && ($location !~ /[^,]+,[^,]+,[^,]+,.*England$/)) {
		return $self->_remember_miss($lc);
	}

	# Geo::Address::Parser - optional; load lazily, skip if not installed
	unless (Geo::Address::Parser->can('parse')) {
		eval { require Geo::Address::Parser; Geo::Address::Parser->import() };
	}
	if (Geo::Address::Parser->can('parse')) {
		my $addr_parser = Geo::Address::Parser->new(country => 'UK');
		if (my $fields = $addr_parser->parse($location)) {
			# Remove undef fields so _search only matches defined columns
			delete $fields->{$_} for grep { !defined $fields->{$_} } keys %{$fields};
			if (my $rc = $self->_search($fields, keys %{$fields})) {
				$rc->{'country'} = 'UK';
				return $self->_cache_and_return($lc, $rc);
			}
		}
	}

	# Geo::libpostal - accurate but uses enormous RAM; initialise at most once
	if ($libpostal_is_installed == LIBPOSTAL_UNKNOWN) {
		if (eval { require Geo::libpostal; 1 }) {
			Geo::libpostal->import();
			$libpostal_is_installed = LIBPOSTAL_INSTALLED;
		} else {
			$libpostal_is_installed = LIBPOSTAL_NOT_INSTALLED;
		}
	}

	if ($libpostal_is_installed == LIBPOSTAL_INSTALLED) {
		my %addr = Geo::libpostal::parse_address($location);
		if (%addr) {
			# Normalise field names to match our data schema
			$addr{'number'} = delete $addr{'house_number'} if $addr{'house_number'} && !$addr{'number'};
			$addr{'name'}   = delete $addr{'house'}        if $addr{'house'}        && !$addr{'name'};
			$addr{'location'} = $location;

			if (my $street = $addr{'road'}) {
				$addr{'road'} = _normalize($street);
			}

			# libpostal returns "england" as a state - map to country code
			if (defined($addr{'state'}) && !defined($addr{'country'})
			    && $addr{'state'} eq 'england') {
				delete $addr{'state'};
				$addr{'country'} = 'GB';
			}

			if ($addr{'country'} && ($addr{'state'} || $addr{'state_district'})) {
				if ($addr{'country'} =~ /Canada/i) {
					$addr{'country'} = 'Canada';
					$addr{'state'}   = _to_two_letter_state('Canada', $addr{'state'})
						if $addr{'state'} && length($addr{'state'}) > 2;
				} elsif ($addr{'country'} =~ /^(United States|USA|US)$/i) {
					$addr{'country'} = 'US';
					$addr{'state'}   = _to_two_letter_state('US', $addr{'state'})
						if $addr{'state'} && length($addr{'state'}) > 2;
				}

				if ($addr{'state_district'}) {
					$addr{'state_district'} =~ s/^(.+)\s+COUNTY\s*$/$1/i;
					if (my $rc = $self->_search(\%addr, qw(number road city state_district state country))) {
						return $self->_cache_and_return($lc, $rc);
					}
				}
				if (my $rc = $self->_search(\%addr, qw(number road city state country))) {
					return $self->_cache_and_return($lc, $rc);
				}
				if ($addr{'number'}) {
					if (my $rc = $self->_search(\%addr, qw(road city state country))) {
						return $self->_cache_and_return($lc, $rc);
					}
				}
			}
		}
	}

	# Last resort: decompose "road, city, state, country" with a regex
	if ($location =~ /^(.+?),\s*([\s\w]+),\s*([\s\w]+),\s*([\w\s]+)$/) {
		my %addr = (
			road    => $1,
			city    => $2,
			state   => $3,
			country => $4,
		);
		$addr{'state'}   =~ s/\s+$//g;
		$addr{'country'} =~ s/\s+$//g;

		if ($addr{'road'} =~ /([\w\s]+),*\s+(.+)/) {
			$addr{'name'} = $1;
			$addr{'road'} = $2;
		}
		if ($addr{'road'} =~ /^(\d+)\s+(.+)/) {
			$addr{'number'} = $1;
			$addr{'road'}   = $2;
			if (my $rc = $self->_search(\%addr, qw(name number road city state country))) {
				return $self->_cache_and_return($lc, $rc);
			}
		} elsif (my $rc = $self->_search(\%addr, qw(name road city state country))) {
			return $self->_cache_and_return($lc, $rc);
		}
		if ($addr{'name'} && !defined($addr{'number'})) {
			if (my $rc = $self->_search(\%addr, qw(name road city state country))) {
				return $self->_cache_and_return($lc, $rc);
			}
		}
	}

	# Try the alternatives table - curated mappings for inconsistent names
	$location = uc($location);
	for my $left (keys %alternatives) {
		next unless $location =~ $left;
		(my $mapped = $location) =~ s/$left/$alternatives{$left}/;
		$params{'location'} = $mapped;
		if (my $rc = $self->geocode(\%params)) {
			return $self->_cache_and_return($lc, $rc);
		}
		if ($mapped =~ /(.+), (England|UK)$/i) {
			$params{'location'} = "$1, GB";
			if (my $rc = $self->geocode(\%params)) {
				return $self->_cache_and_return($lc, $rc);
			}
		}
		$params{'location'} = $location;
	}

	return $self->_remember_miss($lc);
}

=head2 reverse_geocode

=head3 SYNOPSIS

    my $loc = $geocoder->reverse_geocode(latlng => '51.3341,-1.4159');
    # Returns the location string(s) for that lat/lon pair.

=head3 API SPECIFICATION

=head4 input

    # Input schema (Params::Validate::Strict) - latlng or lat+lon required
    latlng => { type => 'scalar', optional => 1 }  # "$lat,$long" comma-separated decimal degrees
    lat    => { type => 'scalar', optional => 1 }  # latitude  (alternative to latlng)
    lon    => { type => 'scalar', optional => 1 }  # longitude (alternative to latlng)
    long   => { type => 'scalar', optional => 1 }  # alias for lon

=head4 output

    # Output schema (Return::Set)
    # scalar context: { type => 'scalar',   optional => 1 }  # location string
    # list context:   { type => 'arrayref', of => { type => 'scalar' } }

=cut

sub reverse_geocode {
	my $self = shift;

	if (!ref($self)) {
		if (scalar @_) {
			return __PACKAGE__->new()->reverse_geocode(@_);
		} elsif (!defined($self)) {
			Carp::croak('Usage: ', __PACKAGE__, '::reverse_geocode(latlng => "$lat,$long")');
		} elsif ($self eq __PACKAGE__) {
			Carp::croak("Usage: $self", '::reverse_geocode(latlng => "$lat,$long")');
		}
		return __PACKAGE__->new()->reverse_geocode($self);
	} elsif (ref($self) eq 'HASH') {
		return __PACKAGE__->new()->reverse_geocode($self);
	}

	my %params = _normalize_args(
		'Usage: ' . __PACKAGE__ . '::reverse_geocode(latlng => "$lat,$long")',
		'latlng', @_
	);

	my ($latitude, $longitude);
	if (my $latlng = $params{'latlng'}) {
		($latitude, $longitude) = split /,/, $latlng;
	} else {
		$latitude  = $params{'lat'};
		$longitude = $params{'lon'} // $params{'long'};
	}

	if (!defined($latitude) || !defined($longitude)) {
		Carp::croak('Usage: ', __PACKAGE__, '::reverse_geocode(latlng => "$lat,$long")');
	}

	my @rc;
	for my $row (@{$self->{'data'}}) {
		next unless defined($row->{'latitude'}) && defined($row->{'longitude'});
		next unless _equal($row->{'latitude'}, $latitude, 4)
		         && _equal($row->{'longitude'}, $longitude, 4);

		# Rows in $self->{'data'} are blessed as Geo::Location::Point by
		# the index-building loop in new() - calling as_string() is safe here.
		my $location = uc($row->as_string());
		if (wantarray) {
			push @rc, $location;
			# Add any reverse-alternative mappings for this location
			# keys, not each(): %alternatives is package-wide, and an each()
			# iterator left part-way would make the next pass skip entries
			foreach my $left (sort keys %alternatives) {
				my $right = $alternatives{$left};
				if ($location =~ $right) {
					(my $l = $location) =~ s/$right/$left/;
					push @rc, $l;
				}
			}
		} else {
			return $location;
		}
	}
	return @rc;
}

=head2 ua

Does nothing - present for drop-in compatibility with other Geo::Coder::* modules.

=head3 API SPECIFICATION

=head4 input

    # Input schema (Params::Validate::Strict)
    # any arguments are accepted and ignored

=head4 output

    # Output schema (Return::Set)
    # nothing: an empty list, or undef in scalar context

=cut

sub ua { }

# -----------------------------------------------------------------------
# Private helpers
# -----------------------------------------------------------------------

# Purpose:  Normalise the four calling conventions used by geocode/reverse_geocode:
#           hashref, even-length key-val list, single bare string.
# Entry:    $error_msg  - croak message if an unsupported ref type is passed.
#           $bare_key   - hash key to use when a single bare string is given
#                         ('location' for geocode, 'latlng' for reverse_geocode).
#           @args       - raw @_ after $self has been shifted.
# Exit:     Flat %params hash.
# Side Effects: None; croaks on non-hash reference arguments.
sub _normalize_args {
	my ($error_msg, $bare_key, @args) = @_;
	return %{$args[0]}               if ref($args[0]) eq 'HASH';
	Carp::croak($error_msg)          if ref($args[0]);
	return @args                     if @args && @args % 2 == 0;
	return ($bare_key => $args[0])   if @args == 1;
	# M7 (logic-gap closure): odd-count > 1 is not a valid calling convention.
	# Fail fast rather than silently discarding trailing arguments.
	Carp::croak($error_msg)          if @args;
	return ();
}

# Purpose:  Store $rc in the lookup cache under $key and return it.
#           Reduces the repeated "$self->{cache}{$k} = $r; return $r;" pattern
#           that appeared ~12 times across geocode.
# Entry:    $self, $key (lc string), $rc (Geo::Location::Point or undef).
# Exit:     $rc (returned transparently).
# Side Effects: Writes to $self->{cache}.
sub _cache_and_return {
	my ($self, $key, $rc) = @_;
	$self->{'cache'}{$key} = $rc;
	return $rc;
}

# Purpose:  Resolve a full state/province name to its two-letter code using
#           the appropriate Locale:: module.  Returns the original string if
#           no mapping is found or the input is already two characters.
#           Locale::US and Locale::CA objects are cached as module-level
#           singletons to avoid repeated construction overhead.
# Entry:    $country - country name or ISO code; $state - state/province name.
# Exit:     Two-letter code or $state unchanged.
# Side Effects: May initialise $_locale_us or $_locale_ca singletons.
sub _to_two_letter_state {
	my ($country, $state) = @_;
	return $state // '' if !defined($state) || length($state) <= 2;

	if ($country =~ /^(United States|USA|US)$/i) {
		$_locale_us //= Locale::US->new();
		return $_locale_us->{'state2code'}{uc($state)} // $state;
	} elsif ($country =~ /Canada/i) {
		$_locale_ca //= Locale::CA->new();
		return $_locale_ca->{'province2code'}{uc($state)} // $state;
	}
	return $state;
}

# Purpose:  Match parsed address components against all data rows.
#           Each named column must match (case-insensitively) the corresponding
#           data field; a minimum of 3 columns must match for a result.
# Entry:    $self, $data - hashref of address components,
#           @columns - ordered list of keys to compare.
# Exit:     Geo::Location::Point on match; undef otherwise.
# Side Effects: May delete undef entries from $data (for undefined optional fields).
sub _search {
	my ($self, $data, @columns) = @_;

	$self->{'reads'}++;

	# M5 (boolean reduction): the $failed flag was set-and-break in the inner loop
	# then tested in the outer loop - eliminated by using a labeled 'next ROW'
	# that short-circuits directly, removing one boolean gate per iteration.
	ROW: for my $row (@{$self->{'data'}}) {
		my $matched = 0;
		my @matched_columns;

		for my $column (@columns) {
			if (defined($data->{$column})) {
				next ROW unless defined($row->{$column});
				next ROW if uc($row->{$column}) ne uc($data->{$column});
				$matched++;
				# The accuracy is reported from the columns that matched, not
				# every column this call site offered: a caller trying
				# 'number road city...' for a town that has no road must not have
				# its match described as an address.
				push @matched_columns, $column;
			} elsif (exists $data->{$column}) {
				delete $data->{$column};
			}
		}

		next if $matched < 3;

		# Assign confidence based on how many columns contributed to the match
		my $confidence = $matched == scalar(@columns) ? $CONF_EXACT
		               : $matched >= 4                ? $CONF_HIGH
		               :                               $CONF_MEDIUM;

		# Provenance (Phase 6 dependency specs section 2.1).  Set after %{$row}
		# so that a dataset column that happens to be called accuracy cannot stand
		# in for the match this code actually made.
		return Geo::Location::Point->new(
			location   => $data->{'location'},
			confidence => $confidence,
			database   => __PACKAGE__,
			%{$row},
			geocoder   => GEOCODER,
			accuracy   => Geo::Location::Point::accuracy_for(@matched_columns),
		);
	}
	return;
}

=head2 _result_for

Build the result for a dataset row that the index matched.  The index holds the
rows themselves - the same hashrefs C<_search> scans - so the object is built
as a copy rather than blessed in place, and the provenance keys every result
carries (section 2.1 of F<BI-Phase6-Dependency-Specs.md>) are added where the
row does not already record them.

An index hit is an exact match on the row's string, so the confidence is
C<$CONF_EXACT>, and the accuracy is what the row's own fields justify, through
C<Geo::Location::Point::accuracy_for()>.

=cut

sub _result_for {
	my ($self, $row) = @_;

	my %attributes = %{$row};
	$attributes{'geocoder'}   = GEOCODER;
	$attributes{'database'}   = __PACKAGE__;
	$attributes{'confidence'} = $CONF_EXACT;
	$attributes{'accuracy'}   = Geo::Location::Point::accuracy_for(keys %attributes);

	return Geo::Location::Point->new(\%attributes);
}

# Purpose:  Calculate the geographic centres (centroids) of all city/state/country
#           clusters in the parsed dataset that contain three or more data points.
#           Clusters with fewer than 3 entries are too sparse to be meaningful.
# Entry:    $rows - arrayref of hashrefs with latitude/longitude/city/state/country.
# Exit:     Arrayref of hashrefs (one per qualifying cluster), or undef if none.
# Side Effects: None.
sub _find_geographic_centres {
	my $rows = $_[0];

	# Group rows by normalised city|state|country key
	my %groups;
	for my $row (@{$rows}) {
		next unless defined($row->{'latitude'})  && defined($row->{'longitude'});
		next unless $row->{'latitude'}  =~ /^-?\d+\.?\d*$/;
		next unless $row->{'longitude'} =~ /^-?\d+\.?\d*$/;
		my $key = join '|',
			$row->{'city'}    // '',
			$row->{'state'}   // '',
			$row->{'country'} // '';
		push @{$groups{$key}}, $row;
	}

	my @centres;
	for my $key (keys %groups) {
		my $locs = $groups{$key};
		next if @{$locs} < 3;

		my ($city, $state, $country) = split /\|/, $key;
		my ($lat, $lon) = _calculate_centre($locs);

		push @centres, {
			city      => $city,
			state     => $state,
			country   => $country,
			lat       => $lat,
			latitude  => $lat,
			longitude => $lon,
			long      => $lon,
			lng       => $lon,
		};
	}

	return @centres ? \@centres : undef;
}

# Purpose:  Compute the arithmetic mean of latitude and longitude for a group
#           of locations.  Accurate for small geographic areas; for large areas
#           or locations crossing the antimeridian, a vector-mean is needed.
# Entry:    $locs - arrayref of hashrefs each with 'latitude' and 'longitude'.
# Exit:     ($centre_lat, $centre_lon) as decimal degree strings to 6dp.
# Side Effects: None.
sub _calculate_centre {
	my $locs  = $_[0];
	my ($sum_lat, $sum_lon) = (0, 0);
	$sum_lat += $_->{'latitude'}, $sum_lon += $_->{'longitude'} for @{$locs};
	my $n = scalar @{$locs};
	return (sprintf('%.6f', $sum_lat / $n), sprintf('%.6f', $sum_lon / $n));
}

# https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch02s03.html
# Equal within $dp decimal places - avoids floating-point equality pitfalls.
sub _equal {
	my ($A, $B, $dp) = @_;
	return sprintf("%.${dp}g", $A) eq sprintf("%.${dp}g", $B);
}

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 BUGS

The data are stored in the module source and must be maintained by the author.
A future version should load them from an external file to allow community contributions.

See also: L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Free>

=head1 SEE ALSO

L<Geo::Coder::Free>, L<Geo::Coder::Free::OpenAddresses>, L<Geo::Coder::Free::MaxMind>

=head1 LICENSE AND COPYRIGHT

Copyright 2020-2026 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, and Government)
must apply in writing for a licence for use from Nigel Horne at C<< <njh at nigelhorne.com> >>.

=cut

1;

# Use abbreviations in the data: RD not ROAD, ST not STREET, etc.
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
"",5350,"CHILLUM PL NE","WASHINGTON",,"DC","US",38.955403,-76.996241
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
"",1406,"LANGBROOK PL","ROCKVILLE","MONTGOMERY","MD","US",39.075583,-77.123833
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
"",404,"BRINDLEY PL SW","LEESBURG","LOUDOUN","VA","US",39.092207,-77.591987
"",818,"FERNDALE TERRACE NE","LEESBURG","LOUDOUN","VA","US",39.124843,-77.535445
"",,"OATLANDS PLANTATION LN","OATLANDS","LOUDOUN","VA","US",39.04071,-77.61682
"",,"PURCELLVILLE GATEWAY DR","PURCELLVILLE","LOUDOUN","VA","US",39.136193,-77.693198
"THE CAPITAL GRILLE RESTAURANT",1861,,"MCLEAN","FAIRFAX","VA","US",38.915635,-77.22573
"",,"","COLONIAL BEACH","WESTMORELAND","VA","US",38.25075,-76.9602533333333
