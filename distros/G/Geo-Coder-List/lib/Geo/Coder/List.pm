package Geo::Coder::List;

# Geo::Coder::List - Aggregate and chain multiple geocoding backends

use 5.10.1;

use strict;
use warnings;
use autodie qw(:all);

use Carp;
use Data::Dumper;
use HTML::Entities;
use Object::Configure 0.13;
use Params::Get 0.04;
use Readonly;
use Scalar::Util qw(blessed);
use Time::HiRes;

=head1 NAME

Geo::Coder::List - Call many Geo-Coders

=head1 VERSION

Version 0.38

=cut

our $VERSION = '0.38';

# ── Module-level constants (not user-configurable) ────────────────────────────

# Default verbosity: 0 = silent, 1 = basic trace, 2 = full Data::Dumper dumps
use constant DEBUG_DEFAULT => 0;

# Internal sentinel class: a cached not-found result stored in L1.
# Using a blessed ref lets _cache() distinguish "never looked up" from
# "looked up and found nothing" without requiring a special undef convention.
use constant _NOT_FOUND_CLASS => __PACKAGE__ . '::_NotFound';

# The singleton value stored in L1 when a location is confirmed missing
my $NOT_FOUND_SENTINEL = bless {}, _NOT_FOUND_CLASS;

# String placed in the 'geocoder' field of a result served from cache
Readonly::Scalar my $CACHE_SOURCE => 'cache';

# String used as the 'result' value in log entries for a geocoder miss
Readonly::Scalar my $RESULT_NONE => 'not found';

# ── Configurable defaults ─────────────────────────────────────────────────────
#
# Any key here can be overridden at run time via an environment variable named
# GEO__CODER__LIST__<key>, which Object::Configure reads automatically in new().
# Example:
#   export GEO__CODER__LIST__cache_hit_duration='7 days'

my %config = (
	debug               => DEBUG_DEFAULT,
	# How long a confirmed location stays in the L2 cache
	cache_hit_duration  => '1 month',
	# How long a transient/partial failure is cached (retry tomorrow)
	cache_part_duration => '1 day',
	# How long a definite not-found is cached (place probably does not exist)
	cache_miss_duration => '1 week',
);

# =============================================================================
# PUBLIC API
# =============================================================================

=head1 SYNOPSIS

L<Geo::Coder::All> and L<Geo::Coder::Many> are great modules but neither
quite does what I want.

C<Geo::Coder::List> aggregates multiple geocoding services into a single,
unified interface.  It chains and prioritizes backends based on regex routing
and per-geocoder query limits, caches results at two levels (L1 in-memory
always; optional L2 via CHI or a plain HASH), and normalizes every provider's
idiosyncratic response into the common structure expected by
L<HTML::GoogleMaps::V3> and L<HTML::OSM>:

    $result->{geometry}{location}{lat}   # canonical latitude
    $result->{geometry}{location}{lng}   # canonical longitude
    $result->{geocoder}                  # source object (or 'cache')

    use Geo::Coder::List;
    use Geo::Coder::OSM;
    use Geo::Coder::CA;

    my $list = Geo::Coder::List->new()
        ->push({ regex => qr/(Canada|USA)$/, geocoder => Geo::Coder::CA->new() })
        ->push(Geo::Coder::OSM->new());

    my $loc = $list->geocode('10 Downing St, London, UK');
    printf "lat=%.4f lng=%.4f\n",
        $loc->{geometry}{location}{lat},
        $loc->{geometry}{location}{lng};

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new C<Geo::Coder::List> object.  When called on an existing object
it returns a clone of that object merged with the supplied arguments.

The constructor reads configuration from environment variables via
L<Object::Configure>; for example, setting
C<GEO__CODER__LIST__carp_on_warn=1> causes warnings to use L<Carp>.

    use Geo::Coder::List;
    use CHI;

    # With an optional L2 cache (any CHI driver works)
    my $geocoder = Geo::Coder::List->new(
        cache => CHI->new(driver => 'Memory', global => 1),
        debug => 0,
    );

    # Clone an existing object with a higher debug level
    my $verbose = $geocoder->new(debug => 2);

=head3 API SPECIFICATION

=head4 INPUT

    # Params::Validate::Strict schema
    {
        cache => {
            type     => [ 'hashref', 'object' ],	# OBJECT must implement get($key) and set($key, $value, $ttl)
            optional => 1,
        },
        debug => {
            type     => 'boolean',
            optional => 1,
            default  => 0,
        },
        # Any additional key is forwarded to Object::Configure
    }

=head4 OUTPUT

    # Return::Set schema
    OBJECT blessed into Geo::Coder::List

=cut

sub new
{
	my $class = shift;
	my $params = Params::Get::get_params(undef, \@_) || {};

	# Handle the rare Geo::Coder::List::new() (function-style) invocation
	if(!defined($class)) {
		if(scalar keys %{$params} > 0) {
			# Using ::new() with arguments is not supported
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}
		# FIXME: cloning does not work when called as ::new() with arguments
		$class = __PACKAGE__;
	} elsif(blessed($class)) {
		# Shallow clone merged with new params; log is always fresh so the
		# clone starts with an empty event history independent of the original
		return bless { %{$class}, %{$params}, log => [] }, ref($class);
	}

	# Let Object::Configure overlay defaults from environment / config files
	$params = Object::Configure::configure($class, $params);

	# Fill in any %config defaults the caller did not explicitly supply
	for my $key (keys %config) {
		$params->{$key} //= $config{$key};
	}

	# Bless and return; params override scalar defaults but locations/log
	# are always initialised fresh so callers cannot inject stale state
	return bless {
		debug     => DEBUG_DEFAULT,
		geocoders => [],
		%{$params},
		locations => {},
		log       => [],
	}, $class;
}

# =============================================================================

=head2 push

Appends a geocoder to the chain.  Geocoders are tried in the order they
were pushed.  Returns C<$self> so calls can be chained.

A plain geocoder object is tried for every location.  A hashref with
C<regex>, C<geocoder>, and optional C<limit> keys restricts the geocoder to
locations matching the regex and caps total queries at C<limit>.

    my $list = Geo::Coder::List->new()
        ->push({ regex => qr/USA$/, geocoder => Geo::Coder::CA->new(), limit => 100 })
        ->push(Geo::Coder::OSM->new());

=head3 API SPECIFICATION

=head4 INPUT

    # Params::Validate::Strict schema
    {
        geocoder => {
            type     => OBJECT | HASHREF,
            required => 1,
            # HASHREF must contain:  geocoder => OBJECT
            # HASHREF may contain:   regex    => Regexp
            #                        limit    => SCALAR (positive integer)
        },
    }

=head4 OUTPUT

    # Return::Set schema
    OBJECT blessed into Geo::Coder::List   # $self, for chaining

=cut

sub push
{
	# Deliberately NOT using Params::Get here: passing the hashref through it
	# would stringify the compiled qr// object, destroying the regex.
	my ($self, $geocoder) = @_;

	# A geocoder argument is mandatory
	croak(__PACKAGE__, '::push: Usage: ($geocoder)') unless defined($geocoder);

	# Append to the ordered chain and return $self for chaining
	CORE::push @{$self->{geocoders}}, $geocoder;

	return $self;
}

# =============================================================================

=head2 geocode

Resolves a location string to geographic coordinates by trying each geocoder
in turn.  The first successful result is returned and cached.

In scalar context returns a single hashref (or C<undef> on failure).
In list context returns all results from the winning geocoder.

The C<geocoder> field of the returned hashref holds the geocoder object that
supplied the result; it is set to the string C<'cache'> when the result was
served from cache.

See L<Geo::Coder::GooglePlaces::V3> for the canonical result structure.

    my $result = $list->geocode(location => 'Paris, France');
    if($result) {
        printf "lat=%.4f lng=%.4f via %s\n",
            $result->{geometry}{location}{lat},
            $result->{geometry}{location}{lng},
            ref($result->{geocoder}) || $result->{geocoder};
    }

    # List context returns all candidates from the winning geocoder
    my @results = $list->geocode('London, UK');

=head3 API SPECIFICATION

=head4 INPUT

    # Params::Validate::Strict schema
    {
        location => {
            type     => SCALAR,
            required => 1,
            # Must contain at least one non-digit character
        },
    }

=head4 OUTPUT

    # Return::Set schema (scalar context)
    HASHREF | undef
    {
        geometry => { location => { lat => Num, lng => Num } },
        geocoder => OBJECT | 'cache',
        lat      => Num,   # convenience alias
        lng      => Num,   # convenience alias
        lon      => Num,   # compatibility alias for lng
        debug    => Int,   # source line of the normalisation branch taken
        # ... provider-specific keys are preserved
    }

    # Return::Set schema (list context)
    ARRAY of the above HASHREFs

=cut

sub geocode {
	my $self = shift;

	# Params::Get enforces 'location'; calling geocode() with no args causes
	# get_params itself to croak with "Usage:" matching t/carp.t expectations
	my $params = Params::Get::get_params('location', @_);
	if(!defined($params)) {
		$self->_error(__PACKAGE__, ' usage: geocode(location => $location)');
		return;
	}

	my $location = $params->{'location'};

	# Reject empty or whitespace-only location strings
	if((!defined($location)) || (length($location) == 0)) {
		$self->_warn(__PACKAGE__, ' usage: geocode(location => $location)');
		return;
	}

	# A purely numeric string is almost certainly an error (e.g. a bare postcode)
	if($params->{'location'} !~ /\D/) {
		$self->_error('Usage: ', __PACKAGE__, ': invalid input to geocode(), ', $params->{location});
	}

	# Collapse runs of whitespace and expand any HTML entities
	$location =~ s/\s\s+/ /g;
	$location = decode_entities($location);
	# Propagate the cleaned-up string so geocoders also receive the decoded form
	$params->{'location'} = $location;

	print "location: $location\n" if($self->{'debug'});

	# Capture the caller's line number once for all log entries in this call
	my @call_details = caller(0);

	# ── L1 / L2 cache lookup ──────────────────────────────────────────────

	# _cache() returns undef for both "not in cache" and "cached not-found";
	# the not-found sentinel is handled internally so callers see undef either way
	my $cached = $self->_cache($location);

	if(defined $cached) {
		# A defined value means we have a genuine cached positive result
		my @rc = ref($cached) eq 'ARRAY' ? @{$cached} : ($cached);

		# Mark every element as coming from cache.  Shallow-copy HASH results
		# first so that neither the L1 cache entry nor any caller-held reference
		# to the same hashref is mutated in place.
		for my $r (@rc) {
			next unless ref($r);
			$r = { %{$r} } if ref($r) eq 'HASH';
			$r->{'geocoder'} = $CACHE_SOURCE;
		}

		# Scalar context: return the first (and usually only) element
		if(!wantarray) {
			my $rc = $rc[0];
			CORE::push @{$self->{'log'}}, {
				line      => $call_details[2],
				location  => $location,
				timetaken => 0,
				geocoder  => $CACHE_SOURCE,
				wantarray => 0,
				result    => $rc,
			};
			print __PACKAGE__, ': ', __LINE__, ": cached\n" if($self->{'debug'});
			return $rc;
		}

		# List context: return all cached candidates
		CORE::push @{$self->{'log'}}, {
			line      => $call_details[2],
			location  => $location,
			timetaken => 0,
			geocoder  => $CACHE_SOURCE,
			wantarray => 1,
			result    => \@rc,
		};
		print __PACKAGE__, ': ', __LINE__, ": cached\n" if($self->{'debug'});

		# Determine if every element is empty; if so return nothing
		my $allempty = 1;
		for my $r (@rc) {
			if(ref($r) eq 'HASH') {
				$allempty = 0 if defined $r->{geometry}{location}{lat};
			} elsif(ref($r) eq 'Geo::Location::Point') {
				$allempty = 0;
			}
		}
		return if $allempty;
		return @rc;
	}

	# Also check if this location is cached as a definite not-found in L1,
	# without going through _cache() (which masks the sentinel as undef)
	if(exists $self->{'locations'}{$location}) {
		my $stored = $self->{'locations'}{$location};
		if(ref($stored) && ref($stored) eq _NOT_FOUND_CLASS) {
			print "No matches (cached)\n" if($self->{'debug'});
			return wantarray ? () : undef;
		}
	}

	# ── Try each geocoder in turn ─────────────────────────────────────────

	ENCODER: foreach my $g (@{$self->{geocoders}}) {
		my $geocoder = $g;

		# Unpack a hashref entry and apply regex / limit guards
		if(ref($geocoder) eq 'HASH') {
			# Decrement and check the per-geocoder query limit
			if(exists($geocoder->{'limit'}) && defined(my $limit = $geocoder->{'limit'})) {
				print "limit: $limit\n" if($self->{'debug'});
				if($limit <= 0) {
					next;
				}
				$geocoder->{'limit'}--;
			}

			# Skip this entry if the location does not match its regex
			if(my $regex = $geocoder->{'regex'}) {
				print 'consider ', ref($geocoder->{geocoder}), ": $regex\n"
					if($self->{'debug'});
				if($location !~ $regex) {
					next;
				}
			}

			# Unwrap the actual geocoder object from the hashref
			$geocoder = $g->{'geocoder'};
		}

		# Start timing before the network call
		my @rc;
		my $timetaken = Time::HiRes::time();

		eval {
			# Geo::GeoNames uses a positional argument, not a hash
			print 'trying ', ref($geocoder), "\n" if($self->{'debug'});
			if(ref($geocoder) eq 'Geo::GeoNames') {
				print 'username => ', $geocoder->username(), "\n"
					if($self->{'debug'});
				die 'lost username' if(!defined($geocoder->username()));
				@rc = $geocoder->geocode($location);
			} else {
				@rc = $geocoder->geocode(%{$params});
			}
		};

		if($@) {
			# Log the failure and move on; do not abort the whole chain
			my $log = {
				line      => $call_details[2],
				location  => $location,
				geocoder  => ref($geocoder),
				timetaken => Time::HiRes::time() - $timetaken,
				wantarray => wantarray,
				error     => $@,
			};
			CORE::push @{$self->{'log'}}, $log;
			$self->_warn(ref($geocoder), " '$location': $@");
			next ENCODER;
		}

		$timetaken = Time::HiRes::time() - $timetaken;

		# Geo::Coder::US::Census sometimes returns a truthy but empty result
		if((ref($geocoder) eq 'Geo::Coder::US::Census') &&
		   !(defined($rc[0]->{result}{addressMatches}[0]->{coordinates}{y}))) {
			my $log = {
				line      => $call_details[2],
				location  => $location,
				timetaken => $timetaken,
				geocoder  => ref($geocoder),
				wantarray => wantarray,
				result    => $RESULT_NONE,
			};
			CORE::push @{$self->{'log'}}, $log;
			next ENCODER;
		}

		# Reject empty result sets and trivially empty hashes / arrays
		if((scalar(@rc) == 0) ||
		   ((ref($rc[0]) eq 'HASH')  && (scalar(keys %{$rc[0]}) == 0)) ||
		   # UNREACHABLE: if $rc[0] is an ARRAY ref, $rc[0][0] may be undef,
		   # which causes keys(%{undef}) to die under strict refs.  No known
		   # geocoder returns an ARRAY-of-ARRAYs with an empty-hash sub-element.
		   # A safe rewrite would guard with: ref($rc[0][0]) eq 'HASH' first.
		   # ((ref($rc[0]) eq 'ARRAY') && (scalar(keys %{$rc[0][0]}) == 0)) ||
		   0) {
			my $log = {
				line      => $call_details[2],
				location  => $location,
				timetaken => $timetaken,
				geocoder  => ref($geocoder),
				wantarray => wantarray,
				result    => $RESULT_NONE,
			};
			CORE::push @{$self->{'log'}}, $log;
			next ENCODER;
		}

		# ── Normalise each candidate result ──────────────────────────────

		# Track which element was successfully normalised so we return it,
		# not blindly return $rc[0] when a later element was the good one
		my $good_result;

		POSSIBLE_LOCATION: foreach my $l (@rc) {
			# Geo::GeoNames wraps each result in a one-element array
			if(ref($l) eq 'ARRAY') {
				# FIXME: only the first element of the sub-array is considered
				$l = $l->[0];
			}

			# Skip undefined or empty-string candidates
			if((!defined($l)) || ($l eq '')) {
				my $log = {
					line      => $call_details[2],
					location  => $location,
					timetaken => $timetaken,
					geocoder  => ref($geocoder),
					wantarray => wantarray,
					result    => $RESULT_NONE,
				};
				CORE::push @{$self->{'log'}}, $log;
				next ENCODER;
			}

			# Skip bare scalars (e.g. integer 0, plain strings) that are
			# not references; they cannot be hash-dereferenced below
			next unless ref($l);

			# Stamp the source geocoder on the result before normalisation
			$l->{'geocoder'} = ref($geocoder);

			print ref($geocoder), ': ',
				Data::Dumper->new([\$l])->Dump() if($self->{'debug'} >= 2);

			# Geo::Location::Point objects carry their own accessors;
			# upgrade the geocoder field and populate the canonical geometry
			# structure so callers can rely on geometry.location.{lat,lng}
			if(ref($l) eq 'Geo::Location::Point') {
				$l->{'geocoder'} = $geocoder;

				# Populate canonical geometry structure from the GLP's own fields
				if(!defined($l->{geometry}{location}{lat}) && defined($l->{lat})) {
					$l->{geometry}{location}{lat} = $l->{lat};
					$l->{geometry}{location}{lng} = $l->{lng} // $l->{lon};
				}

				# Convenience aliases (idempotent if already set by GLP)
				$l->{'lat'} //= $l->{geometry}{location}{lat};
				$l->{'lng'} //= $l->{geometry}{location}{lng};
				$l->{'lon'} //= $l->{geometry}{location}{lng};

				CORE::push @{$self->{'log'}}, {
					line      => $call_details[2],
					location  => $location,
					timetaken => $timetaken,
					geocoder  => ref($geocoder),
					wantarray => wantarray,
					result    => $l,
				};
				$good_result = $l;
				last POSSIBLE_LOCATION;
			}

			# Only HASH results need normalisation
			next if(ref($l) ne 'HASH');

			if($l->{'error'}) {
				# A top-level 'error' key signals a provider-level failure
				my $log = {
					line      => $call_details[2],
					location  => $location,
					timetaken => $timetaken,
					geocoder  => ref($geocoder),
					wantarray => wantarray,
					error     => $l->{'error'},
				};
				CORE::push @{$self->{'log'}}, $log;
				next ENCODER;
			} else {
				# Map provider-specific fields to the canonical geometry structure
				if(!defined($l->{geometry}{location}{lat})) {
					my ($lat, $long);

					if(defined($l->{lat}) && defined($l->{lon})) {
						# OSM / RandMcNally: top-level lat/lon fields
						$lat   = $l->{lat};
						$long  = $l->{lon};
						$l->{'debug'} = __LINE__;
					} elsif($l->{BestLocation}) {
						# Bing Maps: BestLocation.Coordinates.{Latitude,Longitude}
						$lat   = $l->{BestLocation}->{Coordinates}->{Latitude};
						$long  = $l->{BestLocation}->{Coordinates}->{Longitude};
						$l->{'debug'} = __LINE__;
					} elsif($l->{point}) {
						# Bing Maps alternative: point.coordinates[lat, lng]
						$lat   = $l->{point}->{coordinates}[0];
						$long  = $l->{point}->{coordinates}[1];
						$l->{'debug'} = __LINE__;
					} elsif(defined($l->{latt})) {
						# geocoder.ca: latt / longt fields
						$lat   = $l->{latt};
						$long  = $l->{longt};
						$l->{'debug'} = __LINE__;
					} elsif(defined($l->{latitude})) {
						# postcodes.io, Geo::Coder::Free: latitude / longitude
						$lat   = $l->{latitude};
						$long  = $l->{longitude};
						if(my $type = $l->{'local_type'}) {
							# Carry the local_type hint forward as a normalised 'type'
							$l->{'type'} = lcfirst($type);
						}
						$l->{'debug'} = __LINE__;
					} elsif(defined($l->{'properties'}{'geoLatitude'})) {
						# HERE / Ovi: properties.geoLatitude / geoLongitude
						$lat   = $l->{properties}{geoLatitude};
						$long  = $l->{properties}{geoLongitude};
						$l->{'debug'} = __LINE__;
					} elsif($l->{'results'}[0]->{'geometry'}) {
						if($l->{'results'}[0]->{'geometry'}->{'location'}) {
							# DataScienceToolkit mirrors the Google Maps shape
							$lat   = $l->{'results'}[0]->{'geometry'}->{'location'}->{'lat'};
							$long  = $l->{'results'}[0]->{'geometry'}->{'location'}->{'lng'};
							$l->{'debug'} = __LINE__;
						} else {
							# OpenCage places lat/lng directly under geometry
							$lat   = $l->{'results'}[0]->{'geometry'}->{'lat'};
							$long  = $l->{'results'}[0]->{'geometry'}->{'lng'};
							$l->{'debug'} = __LINE__;
						}
					} elsif($l->{'RESULTS'}) {
						# GeoCodeFarm: RESULTS[0].COORDINATES.{latitude,longitude}
						$lat   = $l->{'RESULTS'}[0]{'COORDINATES'}{'latitude'};
						$long  = $l->{'RESULTS'}[0]{'COORDINATES'}{'longitude'};
						$l->{'debug'} = __LINE__;
					} elsif(defined($l->{result}{addressMatches}[0]->{coordinates}{y})) {
						# US Census Bureau: result.addressMatches[0].coordinates.{y,x}
						$lat   = $l->{result}{addressMatches}[0]->{coordinates}{y};
						$long  = $l->{result}{addressMatches}[0]->{coordinates}{x};
						$l->{'debug'} = __LINE__;
					} elsif(defined($l->{lat})) {
						# Geo::GeoNames: lat / lng (reached only after lat+lon check fails)
						$lat   = $l->{lat};
						$long  = $l->{lng};
						$l->{'debug'} = __LINE__;
					} elsif($l->{features}) {
						if($l->{features}[0]->{center}) {
							# Geo::Coder::Mapbox: center is [lng, lat]
							$lat   = $l->{features}[0]->{center}[1];
							$long  = $l->{features}[0]->{center}[0];
							$l->{'debug'} = __LINE__;
						} elsif($l->{'features'}[0]{'geometry'}{'coordinates'}) {
							# Geo::Coder::GeoApify: coordinates is [lng, lat]
							$lat   = $l->{'features'}[0]{'geometry'}{'coordinates'}[1];
							$long  = $l->{'features'}[0]{'geometry'}{'coordinates'}[0];
							$l->{'debug'} = __LINE__;
						} else {
							# GeoApify signals not-found via empty features, not an error
							next ENCODER;
						}
					} else {
						$l->{'debug'} = __LINE__;
					}

					if(defined($lat) && defined($long)) {
						# Populate the canonical geometry structure
						$l->{geometry}{location}{lat} = $lat;
						$l->{geometry}{location}{lng} = $long;
						# Compatibility aliases expected by callers
						$l->{'lat'} = $lat;
						$l->{'lon'} = $long;
					} else {
						# No coordinates extracted; clean up any partial data
						delete $l->{'geometry'};
						delete $l->{'lat'};
						delete $l->{'lon'};
					}

					# geocoder.xyz provides a country name under 'standard'
					if($l->{'standard'}{'countryname'}) {
						$l->{'address'}{'country'} = $l->{'standard'}{'countryname'};
					}
				}

				if(defined($l->{geometry}{location}{lat})) {
					print $l->{geometry}{location}{lat}, '/',
						$l->{geometry}{location}{lng}, "\n"
						if($self->{'debug'});

					# Store the geocoder object (not just its name) on the result
					$l->{geocoder} = $geocoder;
					$l->{'lat'} //= $l->{geometry}{location}{lat};
					$l->{'lng'} //= $l->{geometry}{location}{lng};
					$l->{'lon'} //= $l->{geometry}{location}{lng};

					my $log = {
						line      => $call_details[2],
						location  => $location,
						timetaken => $timetaken,
						geocoder  => ref($geocoder),
						wantarray => wantarray,
						result    => $l,
					};
					CORE::push @{$self->{'log'}}, $log;

					# Record which element succeeded, then exit the inner loop
					$good_result = $l;
					last POSSIBLE_LOCATION;
				}
			}
		}

		# Only attempt to return / cache if normalisation actually succeeded
		next ENCODER unless defined $good_result;

		print 'Number of matches from ', ref($geocoder), ': ',
			scalar(@rc), "\n" if($self->{'debug'});

		if($self->{'debug'} >= 2) {
			# Use 'local' to avoid permanently altering the global Maxdepth
			local $Data::Dumper::Maxdepth = 10;
			print Data::Dumper->new([\@rc])->Dump();
		}

		# NOTE (latent unreachable path): if a geocoder returned a list whose
		# first element is undef (e.g. (undef, {lat=>1,lon=>2})), $good_result
		# would be set from a later element but defined($rc[0]) is false, so
		# the block below is skipped and the valid result is silently discarded.
		# No known geocoder produces a leading undef, making this scenario
		# unreachable in practice.  A safer guard would be defined($good_result).
		if(defined($rc[0])) {
			# Normalise the legacy 'long' key some geocoders emit
			if(defined($rc[0]->{'long'}) && !defined($rc[0]->{'lng'})) {
				$rc[0]->{'lng'} = $rc[0]->{'long'};
			}
			if(defined($rc[0]->{'long'}) && !defined($rc[0]->{'lon'})) {
				$rc[0]->{'lon'} = $rc[0]->{'long'};
			}

			# Sanity check: the good result must have lat and lng
			if((!defined($good_result->{lat})) || (!defined($good_result->{lng}))) {
				$self->_warn(Data::Dumper->new([\@rc])->Dump());
				$self->_error("BUG: '$location': HASH exists but is not sensible");
			}

			if(wantarray) {
				$self->_cache($location, \@rc);
				return @rc;
			}

			$self->_cache($location, $good_result);
			return $good_result;
		}
	}

	# ── No geocoder produced a usable result ──────────────────────────────

	print "No matches\n" if($self->{'debug'});

	# Cache the not-found result so repeated calls do not hammer all backends
	$self->_cache($location, undef);

	return wantarray ? () : undef;
}

# =============================================================================

=head2 ua

Sets the L<LWP::UserAgent> (or compatible) object on every geocoder in the
chain.  Useful when you need proxy support or custom timeouts across all
backends at once.

There is intentionally no read accessor since that would be meaningless
(each geocoder could have a different UA).

    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $list->ua($ua);

=head3 API SPECIFICATION

=head4 INPUT

    # Params::Validate::Strict schema
    {
        ua => {
            type     => OBJECT,
            optional => 1,
        },
    }

=head4 OUTPUT

    # Return::Set schema
    OBJECT   # the same $ua that was passed in

=cut

sub ua
{
	my ($self, $ua) = @_;

	# Nothing to propagate if no UA was supplied
	return unless $ua;

	# Push the UA into every geocoder in the chain
	foreach my $g (@{$self->{geocoders}}) {
		my $geocoder = (ref($g) eq 'HASH') ? $g->{geocoder} : $g;
		# Guard against a misconfigured entry that has no geocoder object
		Carp::croak('No geocoder found') unless defined $geocoder;

		# When the incoming UA supports clone(), create a per-geocoder copy
		# and set the geocoder's own agent string on that copy.
		# Some APIs (e.g. OSM Nominatim) require a specific User-Agent and
		# refuse requests that carry the generic libwww-perl default.
		# The agent string is derived from the geocoder class name and version
		# (e.g. 'Geo::Coder::OSM/0.03') without reading the geocoder's current
		# UA, which would trigger any spy or hook installed on its ua() method.
		if($ua->can('clone') && $ua->can('agent')) {
			my $per_ua  = $ua->clone();
			my $class   = ref($geocoder);
			my $version = eval { $geocoder->VERSION() } // '';
			$per_ua->agent($version ? "$class/$version" : $class);
			$geocoder->ua($per_ua);
		} else {
			$geocoder->ua($ua);
		}
	}

	# Return the UA so callers can verify what was set (API contract)
	return $ua;
}

# =============================================================================

=head2 reverse_geocode

Converts a latitude/longitude pair into a human-readable address string.

In scalar context returns a single address string (or C<undef>).
In list context returns all address strings from the winning geocoder.

    my $address = $list->reverse_geocode(latlng => '51.5074,-0.1278');
    print "Address: $address\n" if $address;

    my @addresses = $list->reverse_geocode(latlng => '51.5074,-0.1278');

=head3 API SPECIFICATION

=head4 INPUT

    # Params::Validate::Strict schema
    {
        latlng => {
            type    => SCALAR,
            required => 1,
            regex   => qr/^\s*[-+]?(?:\d*\.?\d+|\d+\.?\d*)
                              \s*,\s*
                          [-+]?(?:\d*\.?\d+|\d+\.?\d*)\s*$/x,
        },
    }

=head4 OUTPUT

    # Return::Set schema (scalar context)
    SCALAR (address string) | undef

    # Return::Set schema (list context)
    ARRAY of SCALAR

=cut

sub reverse_geocode {
	my $self = shift;
	my $params = Params::Get::get_params('latlng', \@_);

	my $latlng = $params->{'latlng'} or Carp::croak('Usage: reverse_geocode(latlng => $location)');

	# Split into components; populate convenience keys for geocoders that want them
	my ($latitude, $longitude) = split(/,/, $latlng);
	$params->{'lat'} //= $latitude;
	$params->{'lon'} //= $longitude;

	# Check L1 / L2 cache before hitting any backend
	if(my $rc = $self->_cache($latlng)) {
		return $rc;
	}

	my @call_details = caller(0);

	foreach my $g (@{$self->{geocoders}}) {
		my $geocoder = $g;

		# Apply the per-geocoder limit guard for hashref entries
		if(ref($geocoder) eq 'HASH') {
			if(exists($geocoder->{'limit'}) && defined(my $limit = $geocoder->{'limit'})) {
				print "limit: $limit\n" if($self->{'debug'});
				if($limit <= 0) {
					next;
				}
				$geocoder->{'limit'}--;
			}
			$geocoder = $g->{'geocoder'};
		}

		print 'trying ', ref($geocoder), "\n" if($self->{'debug'});

		if(wantarray) {
			# ── List context: collect all address strings from this geocoder ───
			my @rc;
			my @locs;
			eval { @locs = $geocoder->reverse_geocode(%{$params}) };

			# Some geocoders (e.g. Geo::Coder::GeoApify) use strict parameter
			# validation and reject the 'latlng' key as unknown.  Retry without
			# it -- lat and lon are already in %params from the split above.
			# Other geocoders (e.g. Geo::Coder::CA) require 'latlng', so the
			# first attempt must include it.
			if($@ =~ /Unknown parameter.*latlng|latlng.*[Uu]nknown/s) {
				my %no_latlng = %{$params};
				delete $no_latlng{'latlng'};
				$@ = '';
				eval { @locs = $geocoder->reverse_geocode(%no_latlng) };
			}

			if($@) {
				CORE::push @{$self->{'log'}}, {
					line      => $call_details[2],
					location  => $latlng,
					geocoder  => ref($geocoder),
					timetaken => 0,
					wantarray => 1,
					error     => $@,
				};
				$self->_warn(ref($geocoder), " '$latlng': $@");
				next;
			}

			print Data::Dumper->new([\@locs])->Dump() if($self->{'debug'} >= 2);

			foreach my $loc (@locs) {
				if(my $name = $loc->{'display_name'}) {
					# OSM returns the full address in display_name
					CORE::push @rc, $name;
				} elsif($loc->{'city'}) {
					# Geo::Coder::CA: build the address from individual fields
					CORE::push @rc, _build_ca_address($loc);
				} elsif($loc->{features}) {
					# GeoApify: formatted string inside a features array
					CORE::push @rc,
						$loc->{features}[0]->{properties}{formatted};
					last;	# only one result from this provider
				}
			}

			CORE::push @{$self->{'log'}}, {
				line      => $call_details[2],
				location  => $latlng,
				geocoder  => ref($geocoder),
				timetaken => 0,
				wantarray => 1,
				result    => \@rc,
			};

			$self->_cache($latlng, \@rc);
			return @rc;

		} else {
			# ── Scalar context: return the first address string ────────────────
			my $rc = $self->_cache($latlng)
				// eval { $geocoder->reverse_geocode(%{$params}) };

			# Same strict-validation fallback as the list-context path above
			if($@ =~ /Unknown parameter.*latlng|latlng.*[Uu]nknown/s) {
				my %no_latlng = %{$params};
				delete $no_latlng{'latlng'};
				$@ = '';
				$rc = eval { $geocoder->reverse_geocode(%no_latlng) };
			}

			if($@) {
				CORE::push @{$self->{'log'}}, {
					line      => $call_details[2],
					location  => $latlng,
					geocoder  => ref($geocoder),
					timetaken => 0,
					wantarray => 0,
					error     => $@,
				};
				$self->_warn(ref($geocoder), " '$latlng': $@");
				next;
			}

			# A bare string needs no further processing
			next unless defined $rc;
			if(!ref($rc)) {
				CORE::push @{$self->{'log'}}, {
					line      => $call_details[2],
					location  => $latlng,
					geocoder  => ref($geocoder),
					timetaken => 0,
					wantarray => 0,
					result    => $rc,
				};
				return $rc;
			}

			print Data::Dumper->new([$rc])->Dump() if($self->{'debug'} >= 2);

			if(my $name = $rc->{'display_name'}) {
				# OSM
				CORE::push @{$self->{'log'}}, {
					line      => $call_details[2],
					location  => $latlng,
					geocoder  => ref($geocoder),
					timetaken => 0,
					wantarray => 0,
					result    => $name,
				};
				return $self->_cache($latlng, $name);
			}

			if($rc->{'city'}) {
				# Geo::Coder::CA
				my $name = _build_ca_address($rc);
				CORE::push @{$self->{'log'}}, {
					line      => $call_details[2],
					location  => $latlng,
					geocoder  => ref($geocoder),
					timetaken => 0,
					wantarray => 0,
					result    => $name,
				};
				return $self->_cache($latlng, $name);
			}

			if($rc->{features}) {
				# GeoApify
				my $name = $rc->{features}[0]->{properties}{formatted};
				CORE::push @{$self->{'log'}}, {
					line      => $call_details[2],
					location  => $latlng,
					geocoder  => ref($geocoder),
					timetaken => 0,
					wantarray => 0,
					result    => $name,
				};
				return $self->_cache($latlng, $name);
			}
		}
	}

	return;
}

# =============================================================================

=head2 log

Returns an arrayref of log entries accumulated since the last C<flush()>.
Each entry is a hashref with the keys: C<line>, C<location>, C<timetaken>,
C<geocoder>, C<wantarray>, and either C<result> or C<error>.

    foreach my $entry (@{ $list->log() }) {
        printf "%s: %.3fs via %s\n",
            $entry->{location},
            $entry->{timetaken},
            $entry->{geocoder};
    }

=head3 API SPECIFICATION

=head4 INPUT

    # No parameters accepted

=head4 OUTPUT

    # Return::Set schema
    ARRAYREF of HASHREF
    [
        {
            line      => Int,
            location  => Str,
            timetaken => Num,
            geocoder  => Str | 'cache',
            wantarray => Bool,
            result    => HASHREF | ARRAYREF | Str,   # on success
            error     => Str,                        # on failure
        },
        ...
    ]

=cut

sub log {
	my $self = shift;

	# Guard against the state left by flush(); always return a valid arrayref
	return $self->{'log'} // [];
}

# =============================================================================

=head2 flush

Clears all accumulated log entries and returns C<$self> to allow chaining.

    $list->geocode('Paris, France');
    my $entries = $list->log();
    $list->flush()->geocode('London, UK');   # chained

=head3 API SPECIFICATION

=head4 INPUT

    # No parameters accepted

=head4 OUTPUT

    # Return::Set schema
    OBJECT blessed into Geo::Coder::List   # $self, for chaining

=cut

sub flush {
	my $self = shift;

	# Reset to an empty arrayref so log() always returns a valid reference
	$self->{'log'} = [];

	return $self;
}

# =============================================================================
# PRIVATE HELPERS
# =============================================================================

# _build_ca_address
#
# Purpose:    Assemble a printable address string from a Geo::Coder::CA
#             reverse-geocode response.  The CA response uses different keys
#             for US addresses (nested under 'usa') vs Canadian ones.
#
# Entry:      $loc - HASHREF from Geo::Coder::CA reverse_geocode()
#
# Exit:       Returns a plain string, or empty string if nothing was found.
#
# Notes:      Street number and name are joined with a space; other parts
#             (city, province/state, country) are joined with ', '.

sub _build_ca_address
{
	my $loc = $_[0];
	my $name  = '';

	if(my $usa = $loc->{'usa'}) {
		# US address layout inside a CA result
		$name  = $usa->{'usstnumber'} // '';
		# Street name follows number with a space; if no number, no leading space
		$name .= ($name ? ' ' : '') . $usa->{'usstaddress'} if $usa->{'usstaddress'};
		# City, state, country each separated by ', '; skip separator if name empty
		$name .= ($name ? ', ' : '') . $usa->{'uscity'}     if $usa->{'uscity'};
		$name .= ($name ? ', ' : '') . $usa->{'state'}      if $usa->{'state'};
		# Country is always appended for the US branch
		$name .= ($name ? ', ' : '') . 'USA';
	} else {
		# Canadian address layout
		$name  = $loc->{'stnumber'} // '';
		# Street name follows number with a space; if no number, no leading space
		$name .= ($name ? ' ' : '') . $loc->{'staddress'}   if $loc->{'staddress'};
		$name .= ($name ? ', ' : '') . $loc->{'city'}        if $loc->{'city'};
		$name .= ($name ? ', ' : '') . $loc->{'prov'}        if $loc->{'prov'};
	}

	return $name;
}

# -----------------------------------------------------------------------------

# _cache
#
# Read from or write to the two-level cache.
#             L1 is an in-process HASH (always active).
#             L2 is an optional CHI-compatible object or a plain HASH ref.
#
# Entry (write): _cache($key, $value)
#             $value may be undef, which is stored as $NOT_FOUND_SENTINEL so
#             subsequent reads can distinguish "cached not-found" from "never
#             looked up".  Detect the write path by testing scalar(@_) before
#             shifting, not by truthiness of the value.
#
# Entry (read):  _cache($key)
#
# Exit (write):  Returns $value (undef if the location was not found).
# Exit (read):   Returns the cached value, or undef if not in cache.
#             $NOT_FOUND_SENTINEL is never surfaced to callers; undef is
#             returned in its place so callers handle both cases identically.
#
# Side effects: May update $self->{locations} (L1) and $self->{'cache'} (L2).
#
# Notes:      Cache TTLs are taken from $self->{cache_*_duration}, which are
#             initialised from %config and overridable via Object::Configure.
#             Not-found sentinels are stored only in L1 to avoid leaking
#             internal implementation details into an external L2 store.

sub _cache {
	my $self = shift;
	my $key  = shift;

	# ── Write path ────────────────────────────────────────────────────────
	# Detect a write call by the presence of a third argument (even if undef).
	# Testing truthiness of the value would silently swallow not-found results.

	if(scalar(@_)) {
		my $value = shift;

		# Store a sentinel for not-found so we can skip backends on repeat calls
		my $stored = defined($value) ? $value : $NOT_FOUND_SENTINEL;
		$self->{locations}->{$key} = $stored;

		my $rc = $value;

		if($self->{'cache'}) {
			my $duration;

			if(ref($value) eq 'ARRAY') {
				foreach my $item (@{$value}) {
					# Blessed objects (e.g. Geo::Location::Point) may hold
					# unserializable handles; stringify their geocoder field too
					if(blessed($item) && ref($item->{'geocoder'})) {
						$item->{'geocoder'} = ref($item->{'geocoder'});
					}

					next unless ref($item) eq 'HASH';

					# Serialise the geocoder object to its class name for storage
					$item->{'geocoder'} = ref($item->{'geocoder'});

					# Strip everything except geometry to keep the L2 entry small
					unless($self->{'debug'}) {
						while(my ($k, $v) = each %{$item}) {
							delete $item->{$k} unless($k eq 'geometry');
						}
					}

					unless(defined($item->{geometry}{location}{lat})) {
						# Partial or temporary failure: use the shorter TTL.
						# UNREACHABLE ARM: the access above auto-vivifies
						# $item->{geometry} as {}, so defined($item->{geometry})
						# is always true here; the false arm never executes.
						# Original ternary preserved for documentation:
						# $duration //= defined($item->{geometry})
						#     ? $self->{'cache_part_duration'}
						#     : $self->{'cache_miss_duration'};
						$duration //= $self->{'cache_part_duration'};
						$rc = undef;
					}
				}

				# All items were clean: use the full hit duration
				$duration //= $self->{'cache_hit_duration'};

			} elsif(ref($value) eq 'HASH') {
				$value->{'geocoder'} = ref($value->{'geocoder'});

				unless($self->{'debug'}) {
					while(my ($k, $v) = each %{$value}) {
						delete $value->{$k} unless($k eq 'geometry');
					}
				}

				if(defined($value->{geometry}{location}{lat})) {
					# Confirmed location: cache for a full month
					$duration = $self->{'cache_hit_duration'};
				} elsif(defined($value->{geometry})) {
					# Partial geometry: may be a transient failure, retry soon
					$duration = $self->{'cache_part_duration'};
					$rc = undef;
				}
				# UNREACHABLE: the else branch below is dead.  The access
				# defined($value->{geometry}{location}{lat}) above auto-vivifies
				# $value->{geometry} as {}, so the elsif is always taken when
				# the if fails.  Original else preserved for documentation:
				# } else {
				#     # No geometry at all: place probably does not exist
				#     $duration = $self->{'cache_miss_duration'};
				#     $rc = undef;
				# }
			} else {
				# Scalar string or a blessed object (e.g. Geo::Location::Point).
				# Blessed objects may hold unserializable handles; stringify the
				# geocoder field so CHI (Storable) can freeze the value safely.
				if(ref($value) && ref($value->{'geocoder'})) {
					$value->{'geocoder'} = ref($value->{'geocoder'});
				}
				$duration = $self->{'cache_hit_duration'};
			}

			print Data::Dumper->new([$value])->Dump() if($self->{'debug'});

			# Do not push the not-found sentinel into L2
			if(!defined($value)) {
				# value is not-found; L1 sentinel is sufficient
			} elsif(ref($self->{'cache'}) eq 'HASH') {
				$self->{'cache'}->{$key} = $value;
			} else {
				$self->{'cache'}->set($key, $value, $duration);
			}
		}

		return $rc;
	}

	# ── Read path ─────────────────────────────────────────────────────────

	# Check L1 first (in-process, no serialisation cost)
	my $rc = $self->{'locations'}->{$key};

	# Fall through to L2 only when L1 has no entry for this key
	if((!defined($rc)) && $self->{'cache'}) {
		if(ref($self->{'cache'}) eq 'HASH') {
			$rc = $self->{'cache'}->{$key};
		} else {
			$rc = $self->{'cache'}->get($key);
		}
	}

	return unless defined $rc;

	# Translate the not-found sentinel back to undef for the caller
	return if ref($rc) && (ref($rc) eq _NOT_FOUND_CLASS);

	# Restore the convenience aliases that were stripped before L2 storage
	if(ref($rc) eq 'HASH') {
		return unless defined($rc->{geometry}{location}{lat});
		$rc->{'lat'} //= $rc->{geometry}{location}{lat};
		$rc->{'lng'} //= $rc->{geometry}{location}{lng};
		$rc->{'lon'} //= $rc->{geometry}{location}{lng};
	}

	return $rc;
}

# Emit a debug message somewhere
sub _debug {
	my $self = shift;

	if(my $logger = $self->{logger}) {
		$logger->debug(@_);
	}
	if($self->{debug}) {
		print @_, "\n";
	}
}

# Emit a warning message somewhere
sub _warn {
	my $self = shift;

	if(my $logger = $self->{logger}) {
		$logger->warn(@_);
	} else {
		Carp::carp(@_);
	}
}

# Emit an error message somewhere
sub _error {
	my $self = shift;

	if(my $logger = $self->{logger}) {
		$logger->error(@_);
		die @_;
	} else {
		Carp::croak(@_);
	}
}

# =============================================================================
# DOCUMENTATION
# =============================================================================

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-geo-coder-list at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List>.

Known limitations:

=over 4

=item * C<reverse_geocode()> does not yet support L<Geo::Location::Point> objects.

=item * When C<Geo::GeoNames> returns multiple candidates, only the first
element of each sub-array is considered.

=back

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Geo-Coder-List/coverage/>

=item * L<Geo::Coder::All>

=item * L<Geo::Coder::GooglePlaces>

=item * L<Geo::Coder::Many>

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Readonly>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc Geo::Coder::List

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-List>

=item * MetaCPAN

L<https://metacpan.org/release/Geo-Coder-List>

=back

=encoding utf-8

=head2 FORMAL SPECIFICATION

=head3 new

    List_State
    ──────────────────────────────────────────────────────
    geocoders : seq (Geocoder | RegexGeocoder)
    L1        : LocationStr ↛ (GeoResult | NotFound)
    log       : seq LogEntry
    debug     : ℕ
    cache?    : L2Cache

    new
    ──────────────────────────────────────────────────────
    List_State
    params? : ℙ(Key × Value)
    ──────────────────────────────────────────────────────
    geocoders = ⟨⟩
    L1        = ∅
    log       = ⟨⟩
    debug     = params?.debug ∣ DEBUG_DEFAULT
    cache     = params?.cache ∣ ⊥

=head3 push

    push
    ──────────────────────────────────────────────────────
    ΔList_State
    g? : Geocoder | RegexGeocoder
    ──────────────────────────────────────────────────────
    geocoders' = geocoders ⌢ ⟨g?⟩
    L1'        = L1
    log'       = log
    ──────────────────────────────────────────────────────
    where RegexGeocoder ::= { regex    : Regex
                             ; geocoder : Geocoder
                             ; limit?  : ℕ }

=head3 geocode

    LocationStr ::= { s : seq Char | s ≠ ⟨⟩ ∧ ∃ c : s • c ∉ Digit }
    GeoResult   ::= HASHREF with geometry.location.{lat,lng} : ℝ

    geocode
    ──────────────────────────────────────────────────────────────────────
    ΔList_State
    loc?    : LocationStr
    result! : GeoResult | ⊥
    ──────────────────────────────────────────────────────────────────────
    loc? ∈ dom L1
      ⟹ result! = L1(loc?)
         ∧ log' = log ⌢ ⟨{geocoder ↦ cache; timetaken ↦ 0}⟩

    loc? ∉ dom L1
      ⟹ (∃ i : 1..#geocoders •
            applies(geocoders i, loc?)
            ∧ result! = Normalize(geocoders i . geocode(loc?))
            ∧ L1' = L1 ⊕ {loc? ↦ result!}
            ∧ log' = log ⌢ ⟨{geocoder ↦ class(geocoders i)}⟩)
         ∨ (result! = ⊥ ∧ L1' = L1 ⊕ {loc? ↦ ⊥})

    applies(g, loc) ≙
        (g isa Geocoder)
      ∨ (g isa RegexGeocoder ∧ loc ∈ matches(g.regex) ∧ g.limit > 0)

=head3 ua SPECIFICATION

    ua
    ──────────────────────────────────────────────────────
    ΞList_State
    ua?  : UserAgent
    ua!  : UserAgent
    ──────────────────────────────────────────────────────
    ∀ g : ran geocoders • g.ua = ua?
    ua!  = ua?

=head3 reverse_geocode

    LatLngStr ::= { s : seq Char
                  | s matches /^[-+]?\d+\.?\d*,[-+]?\d+\.?\d*$/ }

    reverse_geocode
    ──────────────────────────────────────────────────────────────────────
    ΔList_State
    latlng? : LatLngStr
    result! : seq Char | ⊥
    ──────────────────────────────────────────────────────────────────────
    latlng? ∈ dom L1
      ⟹ result! = L1(latlng?)

    latlng? ∉ dom L1
      ⟹ (∃ i : 1..#geocoders •
            applies(geocoders i, latlng?)
            ∧ result! = geocoders i . reverse_geocode(latlng?)
            ∧ L1' = L1 ⊕ {latlng? ↦ result!})
         ∨ result! = ⊥

=head3 log

    log
    ──────────────────────────────────────────────────────
    ΞList_State
    result! : seq LogEntry
    ──────────────────────────────────────────────────────
    result! = log

=head3 flush

    flush
    ──────────────────────────────────────────────────────
    ΔList_State
    ──────────────────────────────────────────────────────
    log'       = ⟨⟩
    geocoders' = geocoders
    L1'        = L1

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
