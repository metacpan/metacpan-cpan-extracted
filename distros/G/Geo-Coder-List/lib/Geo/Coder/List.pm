package Geo::Coder::List;

# Geo::Coder::List - Aggregate and chain multiple geocoding backends

use 5.10.1;

use strict;
use warnings;

use Carp;
use Data::Dumper;
# One definition of what counts as a location: Geo::Location::Predicate holds
# the rule the facade and its backends apply, so what is refused here is refused
# there for the same reason.  It is called by name rather than imported - an
# import copies the code reference into this package, and then a test could not
# swap the rule for a spy to prove that it is the rule being consulted.
#
# The rule is an optional dependency, not a prerequisite: it is a distribution of
# its own (Geo-Location-Predicate), declared in Makefile.PL under META_MERGE's
# recommends, so an installer fetches it by default and a standalone install that
# leaves it out still gets the one answer this module can give alone - a
# reference is refused.  It is looked for when it is first needed rather than
# when this module is loaded, so importing this module reads no file it may not
# need, and a rule installed after this module is loaded is still found.
my $HAVE_RULE;	# undef until the rule is first looked for
use HTML::Entities;
use Object::Configure 0.13;
use Params::Get 0.04;
use Readonly;
use Scalar::Util qw(blessed reftype);
use Time::HiRes;

=head1 NAME

Geo::Coder::List - Call many Geo-Coders

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

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

# A latlng argument to reverse_geocode(): two decimal numbers and a comma.
# The classes are spelt out rather than written \d and \s: those match
# Arabic-Indic and other Unicode digits, which no backend reads as numbers,
# and the /a flag that would restrict them needs Perl 5.14.
Readonly::Scalar my $LATLNG_RE => qr/^[ \t]*[-+]?(?:[0-9]*\.?[0-9]+|[0-9]+\.?[0-9]*)[ \t]*,[ \t]*[-+]?(?:[0-9]*\.?[0-9]+|[0-9]+\.?[0-9]*)[ \t]*$/;

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

    use Geo::Coder::List;
    use Geo::Coder::OSM;

    # 1. The simplest use: one list, one geocoder
    my $list = Geo::Coder::List->new()->push(Geo::Coder::OSM->new());

    my $place = $list->geocode('10 Downing St, London, UK');
    if($place) {
        print "Latitude:  $place->{geometry}{location}{lat}\n";
        print "Longitude: $place->{geometry}{location}{lng}\n";
    } else {
        print "Not found\n";
    }

    # 2. Several geocoders, tried in order.  Geo::Coder::CA is asked only
    #    about places in Canada or the USA, and at most 1000 times.
    use Geo::Coder::CA;

    my $chain = Geo::Coder::List->new()
        ->push({ regex => qr/(Canada|USA)$/, geocoder => Geo::Coder::CA->new(), limit => 1000 })
        ->push(Geo::Coder::OSM->new());

    my $ottawa = $chain->geocode('Ottawa, ON, Canada');    # asks CA first
    my $paris  = $chain->geocode('Paris, France');         # CA is skipped

    # 3. A cache that lives longer than the object (any CHI driver works)
    use CHI;

    my $cached = Geo::Coder::List->new(
        cache => CHI->new(driver => 'File', root_dir => '/var/cache/geocode'),
    )->push(Geo::Coder::OSM->new());

    # 4. Every candidate, not only the best one: call geocode() in list context
    my @candidates = $list->geocode('Springfield, USA');
    print scalar(@candidates), " places are called Springfield\n";

    # 5. From a position to an address
    my $address = $list->reverse_geocode(latlng => '51.5034,-0.1276');
    print "$address\n" if defined($address);

    # 6. Bad input is fatal, so check it when the text comes from a user
    my $text_from_a_form = $ARGV[0];
    my $result = eval { $list->geocode($text_from_a_form) };
    warn "Not a place: $@" if $@;

    # 7. See what happened, then clear the record
    $list->geocode('Rome, Italy');
    for my $entry (@{ $list->log() }) {
        printf "%s: %s in %.3fs\n", $entry->{location}, $entry->{geocoder}, $entry->{timetaken};
    }
    $list->flush();

=head1 DESCRIPTION

L<Geo::Coder::All> and L<Geo::Coder::Many> are great modules but neither
quite does what I want.

A I<geocoder> turns the name of a place, such as C<'Paris, France'>, into
a position on the Earth (a latitude and a longitude).  There are many
geocoding services.  Each one knows some places better than others, each
one has its own limits, and each one returns its answer in its own format.

C<Geo::Coder::List> lets you use many geocoders as if they were one:

=over 4

=item * B<A chain.>
You add geocoders with C<push()>.  When you ask for a place, the geocoders
are asked one at a time, in the order you added them.  The first one that
gives a usable answer wins, and the others are not asked.

=item * B<Routing.>
A geocoder can be given a regular expression.  It is then asked only
about places whose names match it.

=item * B<Limits.>
A geocoder can be given a limit: the number of questions it may answer.
When the limit is used up, the geocoder is skipped.

=item * B<One answer format.>
Every answer is changed into the same structure, whichever service gave
it.  The structure is the one used by L<HTML::GoogleMaps::V3> and
L<HTML::OSM>:

    $result->{geometry}{location}{lat}   # latitude
    $result->{geometry}{location}{lng}   # longitude
    $result->{lat}                       # the same latitude, for convenience
    $result->{lng}                       # the same longitude, for convenience
    $result->{lon}                       # the same longitude, another common name
    $result->{geocoder}                  # the geocoder object that answered,
                                         # or the string 'cache'

=item * B<A cache in two levels.>
Level 1 (L1) is a hash inside the object.  It is always used, and it lasts
as long as the object.  Level 2 (L2) is optional.  It can be a plain hash
or any object with C<get()> and C<set()> methods, such as a L<CHI> cache.
L2 can last longer than the object and can be shared between programs.
How long L2 keeps an answer depends on the answer:

    found                      1 month   (cache_hit_duration)
    found, but no latitude     1 day     (cache_part_duration)
    not found                  1 week    (cache_miss_duration)

A place that was not found is remembered in L1 only, never in L2.

=back

=head1 SUPPORTED ANSWER FORMATS

Each geocoding service answers in its own format.  C<geocode()> finds the
latitude and longitude in each of the formats below and copies them into
the common structure.  Any geocoder whose answers use one of these formats
works without extra code.  The provider's own fields are kept as well.

    Service (module)                Where the position is found
    ------------------------------  -----------------------------------------
    OpenStreetMap, RandMcNally      lat, lon
    Bing Maps                       BestLocation.Coordinates.Latitude/Longitude
    Bing Maps (other form)          point.coordinates [lat, lng]
    geocoder.ca (Geo::Coder::CA)    latt, longt
    postcodes.io, Geo::Coder::Free  latitude, longitude
    HERE / Ovi                      properties.geoLatitude/geoLongitude
    DataScienceToolkit              results[0].geometry.location.lat/lng
    OpenCage                        results[0].geometry.lat/lng
    GeocodeFarm                     RESULTS[0].COORDINATES.latitude/longitude
    US Census Bureau                result.addressMatches[0].coordinates.y/x
    GeoNames                        lat, lng
    Mapbox                          features[0].center [lng, lat]
    GeoApify                        features[0].geometry.coordinates [lng, lat]
    Google, and anything already    geometry.location.lat/lng
    in the common structure

Notice that Mapbox and GeoApify give the longitude B<first>.

Some services need special handling, which is done for you:

=over 4

=item * B<Geo::Location::Point.>
A geocoder may answer with a L<Geo::Location::Point> object.  Its
C<geometry> is filled in from its own C<lat> and C<lng> (or C<lon>).

=item * B<postcodes.io.>
Its C<local_type> field is copied to C<type>, with the first letter made
lower case.

=item * B<geocoder.xyz.>
Its C<standard.countryname> field is copied to C<address.country>.

=item * B<GeoNames.>
L<Geo::GeoNames> is called with the place name alone, not with
C<location =E<gt> ...>.  If it has no C<username>, it fails with
C<lost username>, which is logged, and the next geocoder is asked.
GeoNames puts its answers in arrays; every answer in them is considered.

=item * B<US Census Bureau.>
An answer with no C<addressMatches> means "not found", and the next
geocoder is asked.

=item * B<GeoApify.>
An answer with an empty C<features> list means "not found", and the next
geocoder is asked.

=item * B<Errors.>
An answer with a top-level C<error> key is treated as a refusal, not as a
place.  The error is logged, and the next geocoder is asked.

=back

Every answer that went through this process also has a C<debug> key.  It
holds the line number, in this module, of the code that read the answer.
It is there to help when a new format is not read correctly.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new C<Geo::Coder::List> object with no geocoders in it.

Settings can also come from the environment, through
L<Object::Configure>.  The variable name is C<GEO__CODER__LIST__> followed
by the setting name.  For example, C<GEO__CODER__LIST__carp_on_warn=1>
makes warnings go through L<Carp>, and
C<GEO__CODER__LIST__cache_hit_duration='7 days'> changes how long a found
place stays in L2.

When you call C<new()> on an object that already exists, you get a
I<clone>: a new object with the same settings and the same geocoders,
merged with any arguments you give.  The clone has its own list of
geocoders and its own limits, and it starts with an empty log.  The clone
B<shares> the L1 and L2 caches with the original.

    use Geo::Coder::List;
    use CHI;

    # With an L2 cache
    my $geocoder = Geo::Coder::List->new(
        cache => CHI->new(driver => 'Memory', global => 1),
    );

    # A clone of it that prints what it is doing
    my $verbose = $geocoder->new(debug => 1);

Arguments can be given as a list of pairs or as one hash reference.

=over 4

=item * C<cache> - Optional.  The L2 cache: a hash reference, or an object
with C<get($key)> and C<set($key, $value, $ttl)> methods.

=item * C<debug> - Optional.  C<0> (the default) prints nothing, C<1>
prints what is tried, C<2> also prints every answer in full.

=item * C<cache_hit_duration>, C<cache_part_duration>,
C<cache_miss_duration> - Optional.  How long L2 keeps each kind of
answer, in any form your L2 cache understands, such as C<'1 week'>.

=item * C<geocoders> - Optional.  An array reference of geocoders, as if
each had been given to C<push()>.

=item * C<logger> - Optional.  Where warnings and errors go.  See
L<Object::Configure>.

=item * C<carp_on_warn> - Optional.  When true, warnings go through
L<Carp>.

=back

If C<new> is called as a function, C<Geo::Coder::List::new()>, with no
arguments, it still returns an object.  Called as a function with
arguments, it warns and returns C<undef>.

=head3 API SPECIFICATION

=head4 INPUT

    {
        cache               => { type => 'hashref|object', optional => 1 },
        debug               => { type => 'integer', optional => 1, min => 0, max => 2 },
        cache_hit_duration  => { type => 'string', optional => 1 },
        cache_part_duration => { type => 'string', optional => 1 },
        cache_miss_duration => { type => 'string', optional => 1 },
        geocoders           => { type => 'arrayref', optional => 1 },
        logger              => { type => 'object|coderef|arrayref|string', optional => 1 },
        carp_on_warn        => { type => 'boolean', optional => 1 },
    }

=head4 OUTPUT

    {
        type => 'object',
        isa  => 'Geo::Coder::List',
    }

    # undef only when called as Geo::Coder::List::new() with arguments

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
		# With no arguments there is nothing to lose, so build a default
		# object; with arguments the caller has mistaken the calling form and
		# is told so above, rather than having the arguments silently ignored
		$class = __PACKAGE__;
	} elsif(blessed($class)) {
		# Shallow clone merged with new params; log is always fresh so the
		# clone starts with an empty event history independent of the original
		# The chain is copied, hashref entries included, so pushing onto the
		# clone or spending one of its limits leaves the original's alone
		my $clone = bless { %{$class}, %{$params}, log => [] }, ref($class);
		$clone->{'geocoders'} = [
			map { ref($_) eq 'HASH' ? { %{$_} } : $_ } @{$clone->{'geocoders'} // []}
		];
		return $clone;
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

Adds one geocoder to the end of the chain.  Geocoders are asked in the
order in which they were added.

C<push> returns the object itself, so you can add several geocoders in
one statement.

There are two ways to add a geocoder:

=over 4

=item * B<A geocoder object.>
It is asked about every place.

=item * B<A hash reference>, with these keys:

=over 4

=item * C<geocoder> - Required.  The geocoder object.

=item * C<regex> - Optional.  A regular expression, made with C<qr//>.
The geocoder is asked only about places whose names match it.

=item * C<limit> - Optional.  A whole number.  The geocoder answers at
most this many questions.  Each question it is asked makes the number one
smaller.  When the number reaches C<0>, the geocoder is skipped.  A place
that does not match C<regex> does not use up the limit.

=back

=back

    my $list = Geo::Coder::List->new()
        ->push({ regex => qr/USA$/, geocoder => Geo::Coder::US::Census->new(), limit => 100 })
        ->push(Geo::Coder::OSM->new());

C<push> croaks if C<$geocoder> is missing or C<undef>.

=head3 API SPECIFICATION

=head4 INPUT

    {
        geocoder => { type => 'object|hashref', optional => 0 },
    }

    # A hashref geocoder holds the keys geocoder (an object, required),
    # regex (a Regexp, optional) and limit (an integer, optional)

=head4 OUTPUT

    {
        type => 'object',
        isa  => 'Geo::Coder::List',
    }

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

# The rule when it is installed, and the one thing that can be said without it.
# A reference is not a location however it would print: when the rule is there it
# says so, and when it is not this refuses it - the hole this module used to have
# was testing the string a reference turns into.  Whether a string of digits is a
# place is the rule's question, so without the rule it is not asked: the string
# is looked up, as it was before the rule existed.
sub _could_be_a_location {
	my $location = shift;

	if(!defined($HAVE_RULE)) {
		$HAVE_RULE = eval {
			require Geo::Location::Predicate;
			Geo::Location::Predicate->can('_valid_location') ? 1 : 0;
		} ? 1 : 0;
	}

	# When the rule is installed it decides everything, references included, so
	# that this module cannot be stricter or looser than the facade.  Without it
	# there are two answers this module can give on its own.
	return Geo::Location::Predicate::_valid_location($location) ? 1 : 0 if $HAVE_RULE;

	return 0 if ref($location);
	return 0 unless defined($location) && length($location);
	return 1;
}

# =============================================================================

=head2 geocode

Finds the position of a place from its name.

    my $result = $list->geocode(location => 'Paris, France');
    my $result = $list->geocode('Paris, France');            # the same
    my $result = $list->geocode({ location => 'Paris, France' });  # the same

    if($result) {
        printf "lat=%.4f lng=%.4f from %s\n",
            $result->{geometry}{location}{lat},
            $result->{geometry}{location}{lng},
            ref($result->{geocoder}) || $result->{geocoder};
    }

These are the steps, in order:

=over 4

=item 1. If C<location> is missing, C<geocode> croaks.  If it is
C<undef> or an empty string, C<geocode> warns and returns nothing.

=item 2. Runs of white space are made into one space, and HTML entities
are decoded: C<'Caf&eacute;'> becomes C<'Caf'> followed by the single
character e-acute.  A reference to a string is treated as the string.

=item 3. The text is checked.  A reference is never a place.  When
L<Geo::Location::Predicate> is installed, it decides what else is not a
place; for example, a string of only digits is not.  If the text is not a
place, C<geocode> croaks.  The check is done after step 2, so
C<'&#49;&#50;'> is refused as the digits C<'12'>.

=item 4. The cache is checked: first L1, then L2.  If the place is there,
the cached answer is returned, with C<geocoder> set to C<'cache'>.  If L1
remembers that the place was not found, nothing is returned and no
geocoder is asked.

=item 5. Each geocoder in the chain is asked in turn.  A geocoder is
skipped if the place does not match its C<regex>, or if its C<limit> is
used up.  If a geocoder dies, the error is logged, a warning is given, and
the next geocoder is asked.

=item 6. The first answer that has both a latitude and a longitude wins.
It is changed into the common structure (see L</DESCRIPTION>), stored in
the cache, and returned.

=item 7. If no geocoder gives a usable answer, the place is remembered as
"not found" in L1, and nothing is returned.

=back

B<Scalar context> returns one hash reference, or C<undef>.

B<List context> returns every answer from the geocoder that won, or an
empty list.  This is useful when a name, such as C<'Springfield'>, belongs
to many places.  Answers that the geocoder returned inside an array are
taken out of it, so the list never contains array references.  Answers
without a position may be in the list too; check C<geometry> before you
use each one.

    my @all = $list->geocode('Springfield, USA');

The C<geocoder> key of an answer holds the geocoder object that gave it.
When the answer came from the cache, it holds the string C<'cache'>.

=head3 API SPECIFICATION

=head4 INPUT

    {
        location => { type => 'string', optional => 0, min => 1 },
    }

=head4 OUTPUT

    {
        type => 'hashref',
        optional => 1,
    }

    # Return::Set schema, scalar context: a hashref, or undef when not found
    #   {
    #       geometry => { location => { lat => Num, lng => Num } },
    #       lat      => Num,
    #       lng      => Num,
    #       lon      => Num,                   # the same as lng
    #       geocoder => OBJECT | 'cache',
    #       debug    => Int,                   # line that read the answer
    #       ...                                # fields from the provider
    #   }
    #
    # List context: a list of hashrefs as above, or an empty list

=cut

sub geocode {
	my $self = shift;

	# The geocoders are called inside eval; the caller's $@ is not ours to change
	local $@;

	# Params::Get enforces 'location'; calling geocode() with no args causes
	# get_params itself to croak with "Usage:" matching t/carp.t expectations
	my $params = Params::Get::get_params('location', @_);
	if(!defined($params)) {
		$self->_error(__PACKAGE__, ' usage: geocode(location => $location)');
		return;
	}

	my $location = $params->{'location'};

	# A scalar reference is one way of passing the string it points at, and
	# Params::Get dereferences it when it is the only argument.  Do it here as
	# well, in every calling form, so that it means the string however the
	# method is called.
	$location = ${$location} if ref($location) eq 'SCALAR';

	# Reject empty or whitespace-only location strings
	if((!defined($location)) || (length($location) == 0)) {
		$self->_warn(__PACKAGE__, ' usage: geocode(location => $location)');
		return;
	}

	# Collapse runs of whitespace and expand any HTML entities before the rule
	# is asked: '&#49;&#50;' is the string of digits '12' once decoded, and it
	# is the decoded string that is looked up.  A reference is left as it is
	# for the rule to refuse.
	if(!ref($location)) {
		$location =~ s/\s\s+/ /g;
		$location = decode_entities($location);
	}

	# What counts as a location is Geo::Location::Predicate's answer, not a
	# second copy of it here: a reference is not a location however it would print,
	# and a string of digits is what a numeric column holds when the wrong one has
	# been read.
	if(!_could_be_a_location($location)) {
		$self->_error('Usage: ', __PACKAGE__, ': invalid input to geocode(), ',
			ref($location) ? 'a reference is not a location' : $location);
		return;
	}

	# Propagate the cleaned-up string so geocoders also receive the decoded form
	$params->{'location'} = $location;

	$self->_debug("location: $location\n");

	# Capture the caller's line number once for all log entries in this call
	my @call_details = caller(0);

	# ── L1 / L2 cache lookup ──────────────────────────────────────────────

	# _cache() returns undef for both "not in cache" and "cached not-found";
	# the not-found sentinel is handled internally so callers see undef either way
	my $cached = $self->_cache($location);

	# Only a reference is a geocode result.  A plain string in the cache under
	# this key - a reverse_geocode() address, or a corrupted store - is not,
	# and is looked up again rather than returned as if it were one.
	if(defined($cached) && !ref($cached)) {
		undef $cached;
	}

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
			$self->_debug(__PACKAGE__, ': ', __LINE__, ": cached\n");
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
		$self->_debug(__PACKAGE__, ': ', __LINE__, ": cached\n");

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
			$self->_debug("No matches (cached)\n");
			return wantarray ? () : undef;
		}
	}

	# ── Try each geocoder in turn ─────────────────────────────────────────

	ENCODER: foreach my $g (@{$self->{geocoders}}) {
		my $geocoder = $g;

		# Unpack a hashref entry and apply regex / limit guards
		if(ref($geocoder) eq 'HASH') {
			# Skip this entry if the location does not match its regex.  This
			# comes before the limit so that a location the geocoder is never
			# asked about does not spend one of its queries.
			if(my $regex = $geocoder->{'regex'}) {
				$self->_debug('consider ', ref($geocoder->{geocoder}), ": $regex\n");
				if($location !~ $regex) {
					next;
				}
			}

			# Decrement and check the per-geocoder query limit
			if(exists($geocoder->{'limit'}) && defined(my $limit = $geocoder->{'limit'})) {
				$self->_debug("limit: $limit\n");
				if($limit <= 0) {
					next;
				}
				$geocoder->{'limit'}--;
			}

			# Unwrap the actual geocoder object from the hashref
			$geocoder = $g->{'geocoder'};
		}

		# Start timing before the network call
		my @rc;
		my $timetaken = Time::HiRes::time();

		eval {
			# Geo::GeoNames uses a positional argument, not a hash
			$self->_debug('trying ', ref($geocoder), "\n");
			if(ref($geocoder) eq 'Geo::GeoNames') {
				$self->_debug('username => ', $geocoder->username(), "\n");
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

		# Geo::GeoNames wraps its results in arrays.  Every element of such an
		# array is a candidate, so they are unwrapped into one list here, and a
		# wrapped empty hash is then caught by the check below like any other
		@rc = map { ref($_) eq 'ARRAY' ? @{$_} : $_ } @rc;

		# Reject empty result sets and trivially empty hashes
		if((scalar(@rc) == 0) ||
		   ((ref($rc[0]) eq 'HASH') && (scalar(keys %{$rc[0]}) == 0))) {
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

			$self->_debug(ref($geocoder), ': ',
				Data::Dumper->new([\$l])->Dump()) if($self->{'debug'} >= 2);

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

				# A result whose geometry has lat but no lng may still carry the
				# longitude at the top level, some geocoders using the legacy
				# 'long' key for it
				if(defined($l->{geometry}{location}{lat})) {
					$l->{geometry}{location}{lng} //= $l->{'lng'} // $l->{'lon'} // $l->{'long'};
				}

				# Only a result with both coordinates is usable; anything less is
				# passed over so that a later element, or the next geocoder, can
				# answer instead
				if(defined($l->{geometry}{location}{lat}) && defined($l->{geometry}{location}{lng})) {
					$self->_debug($l->{geometry}{location}{lat}, '/',
						$l->{geometry}{location}{lng}, "\n");

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

		$self->_debug('Number of matches from ', ref($geocoder), ': ',
			scalar(@rc), "\n");

		if($self->{'debug'} >= 2) {
			# Use 'local' to avoid permanently altering the global Maxdepth
			local $Data::Dumper::Maxdepth = 10;
			$self->_debug(Data::Dumper->new([\@rc])->Dump());
		}

		# Only a result with both coordinates is accepted above, so this can
		# fail only if the normalisation itself is wrong
		if((!defined($good_result->{lat})) || (!defined($good_result->{lng}))) {
			$self->_warn(Data::Dumper->new([\@rc])->Dump());
			$self->_error("BUG: '$location': HASH exists but is not sensible");
		}

		if(wantarray) {
			# A bare scalar the loop passed over is not a result
			@rc = grep { ref } @rc;
			$self->_cache($location, \@rc);
			return @rc;
		}

		$self->_cache($location, $good_result);
		return $good_result;
	}

	# ── No geocoder produced a usable result ──────────────────────────────

	$self->_debug("No matches\n");

	# Cache the not-found result so repeated calls do not hammer all backends
	$self->_cache($location, undef);

	return wantarray ? () : undef;
}

# =============================================================================

=head2 ua

Gives a user agent (the object that makes the web requests) to every
geocoder in the chain.  Use it to set a proxy or a time-out for all of
them at once.

    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new(timeout => 10);
    $ua->env_proxy(1);
    $list->ua($ua);

If C<$ua> has both C<clone()> and C<agent()> methods, as
L<LWP::UserAgent> does, each geocoder is given its own copy.  The
C<agent> string of each copy is set to the geocoder's class name and
version, such as C<'Geo::Coder::OSM/0.03'>, so each service can see which
module is calling it.  Otherwise every geocoder is given C<$ua> itself.

Add the geocoders before you call C<ua>: geocoders added later do not get
the user agent.

There is no way to read the user agent back, because each geocoder may
have a different one.

If C<$ua> is missing or false, nothing changes and nothing is returned.
C<ua> croaks with C<No geocoder found> if an entry in the chain has no
geocoder.

=head3 API SPECIFICATION

=head4 INPUT

    {
        ua => { type => 'object', optional => 1 },
    }

=head4 OUTPUT

    {
        type => 'object',
        optional => 1,
    }

    # The same $ua that was passed in, or nothing when $ua is false

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

Finds the address of a position: the opposite of C<geocode>.

    my $address = $list->reverse_geocode(latlng => '51.5034,-0.1276');
    my $address = $list->reverse_geocode('51.5034,-0.1276');    # the same
    print "Address: $address\n" if defined($address);

    my @addresses = $list->reverse_geocode(latlng => '51.5034,-0.1276');

C<latlng> is the latitude, a comma, and the longitude, in that order.  It
must be two plain decimal numbers written with the digits C<0> to C<9>.
Spaces, tabs and a C<+> or C<-> sign are allowed.  Anything else, such as
C<'51.5;-0.1'>, C<'1e5,2'> or C<'51.5'>, makes C<reverse_geocode> croak
before any geocoder is asked.

The geocoders are asked in turn, as for C<geocode>.  C<limit> is honoured;
C<regex> is not.  If a geocoder complains that it does not know the
C<latlng> parameter, it is asked again with only C<lat> and C<lon>.  If a
geocoder dies for any other reason, a warning is given and the next
geocoder is asked.

B<Scalar context> returns one address string, or C<undef>.

B<List context> returns every address from the first geocoder that has
any, or an empty list.

An address is taken from the first of these that the answer has:

=over 4

=item * C<display_name> (OpenStreetMap, and others that copy it)

=item * the fields of geocoder.ca: C<stnumber>, C<staddress>, C<city> and
C<prov> for Canada, giving for example
C<'1 Sussex Dr, Ottawa, ON'>; or the C<usa> fields for the United States,
giving for example C<'1600 Pennsylvania Ave, Washington, DC, USA'>

=item * C<features[0].properties.formatted> (GeoApify); only the first
feature is used

=back

If a geocoder returns a plain string, the string is the address.

Addresses are cached under the C<latlng> string, so asking again for the
same position does not ask any geocoder.

=head3 API SPECIFICATION

=head4 INPUT

    {
        latlng => { type => 'string', optional => 0, matches => qr/^[ \t]*[-+]?(?:[0-9]*\.?[0-9]+|[0-9]+\.?[0-9]*)[ \t]*,[ \t]*[-+]?(?:[0-9]*\.?[0-9]+|[0-9]+\.?[0-9]*)[ \t]*$/ },
    }

=head4 OUTPUT

    {
        type => 'string',
        optional => 1,
    }

    # Scalar context: an address string, or undef when not found
    # List context: a list of address strings, or an empty list

=cut

sub reverse_geocode {
	my $self = shift;

	# The geocoders are called inside eval; the caller's $@ is not ours to change
	local $@;

	my $params = Params::Get::get_params('latlng', \@_);

	my $latlng = $params->{'latlng'} or Carp::croak('Usage: reverse_geocode(latlng => $location)');

	# Only a numeric pair is a position; anything else would be split into
	# nonsense coordinates and sent to every backend
	Carp::croak('Usage: reverse_geocode(latlng => $location)')
		if(ref($latlng) || ($latlng !~ $LATLNG_RE));

	# Split into components; populate convenience keys for geocoders that want them
	my ($latitude, $longitude) = split(/,/, $latlng);
	$params->{'lat'} //= $latitude;
	$params->{'lon'} //= $longitude;

	# Check L1 / L2 cache before hitting any backend.  A list-context call
	# caches every address as an arrayref and a scalar-context call caches
	# one string, so the entry is unpacked for the context asking for it.
	if(defined(my $rc = $self->_cache($latlng))) {
		if(ref($rc) eq 'ARRAY') {
			return wantarray ? @{$rc} : $rc->[0];
		}
		return $rc;
	}

	my @call_details = caller(0);

	foreach my $g (@{$self->{geocoders}}) {
		my $geocoder = $g;

		# Apply the per-geocoder limit guard for hashref entries
		if(ref($geocoder) eq 'HASH') {
			if(exists($geocoder->{'limit'}) && defined(my $limit = $geocoder->{'limit'})) {
				$self->_debug("limit: $limit\n");
				if($limit <= 0) {
					next;
				}
				$geocoder->{'limit'}--;
			}
			$geocoder = $g->{'geocoder'};
		}

		$self->_debug('trying ', ref($geocoder), "\n");

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

			$self->_debug(Data::Dumper->new([\@locs])->Dump()) if($self->{'debug'} >= 2);

			foreach my $loc (@locs) {
				next unless(defined($loc));

				# A plain string is the address itself, as it is in scalar
				# context; anything else that is not a HASH has none to give
				if(!ref($loc)) {
					CORE::push @rc, $loc if(length($loc));
					next;
				}
				next unless(reftype($loc) eq 'HASH');

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

			# A geocoder with no address for the position has not answered;
			# the next one may
			next unless(scalar(@rc));

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

			$self->_debug(Data::Dumper->new([$rc])->Dump()) if($self->{'debug'} >= 2);

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

Returns the record of what has happened since the object was made, or
since the last C<flush()>.  There is one entry for each question asked of
a geocoder, and one for each answer that C<geocode()> serves from the
cache.  C<reverse_geocode()> adds no entry when it answers from the
cache.

    for my $entry (@{ $list->log() }) {
        printf "%s: %.3fs via %s\n",
            $entry->{location},
            $entry->{timetaken},
            $entry->{geocoder};
    }

Each entry is a hash reference with these keys:

=over 4

=item * C<location> - the place name or C<latlng> that was asked about

=item * C<geocoder> - the class name of the geocoder, or C<'cache'>

=item * C<timetaken> - how long the geocoder took, in seconds

=item * C<line> - the line of your program that made the call

=item * C<wantarray> - true if the call was made in list context

=item * C<result> - the answer, when there was one; the string
C<'not found'> when the geocoder had none

=item * C<error> - the error, when the geocoder died or returned an
error; this can be an exception object, not only a string

=back

The returned array reference is the object's own record, not a copy.

=head3 API SPECIFICATION

=head4 INPUT

    []

=head4 OUTPUT

    {
        type => 'arrayref',
    }

    # Each element:
    #   {
    #       line      => Int,
    #       location  => Str,
    #       timetaken => Num,
    #       geocoder  => Str,                     # class name, or 'cache'
    #       wantarray => Bool,
    #       result    => HASHREF | ARRAYREF | Str,  # on success
    #       error     => Str | OBJECT | HASHREF,    # on failure
    #   }

=cut

sub log {
	my $self = shift;

	# Guard against the state left by flush(); always return a valid arrayref
	return $self->{'log'} // [];
}

# =============================================================================

=head2 flush

Empties the log and returns the object itself, so that it can be chained.

    $list->geocode('Paris, France');
    my $entries = $list->log();
    $list->flush()->geocode('London, UK');

C<flush> does B<not> empty the cache.

=head3 API SPECIFICATION

=head4 INPUT

    []

=head4 OUTPUT

    {
        type => 'object',
        isa  => 'Geo::Coder::List',
    }

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
			# L2 is written from copies: the caller is returned $value and L1
			# holds it, so what is stripped for storage must not be stripped
			# from what they see
			my $l2value = $value;
			my $duration;

			if(ref($value) eq 'ARRAY') {
				$l2value = [ map { _l2_copy($_, $self->{'debug'}) } @{$value} ];

				foreach my $item (@{$l2value}) {
					next unless ref($item) eq 'HASH';

					unless(_has_lat($item)) {
						# Geometry without a lat may be a transient failure, so
						# retry soon; no geometry at all is a miss
						$duration //= defined($item->{geometry})
							? $self->{'cache_part_duration'}
							: $self->{'cache_miss_duration'};
						$rc = undef;
					}
				}

				# All items were clean: use the full hit duration
				$duration //= $self->{'cache_hit_duration'};

			} elsif(ref($value) eq 'HASH') {
				$l2value = _l2_copy($value, $self->{'debug'});

				if(_has_lat($l2value)) {
					# Confirmed location: cache for a full month
					$duration = $self->{'cache_hit_duration'};
				} elsif(defined($l2value->{geometry})) {
					# Partial geometry: may be a transient failure, retry soon
					$duration = $self->{'cache_part_duration'};
					$rc = undef;
				} else {
					# No geometry at all: place probably does not exist
					$duration = $self->{'cache_miss_duration'};
					$rc = undef;
				}
			} else {
				# Scalar string or a blessed object (e.g. Geo::Location::Point)
				$l2value = _l2_copy($value, 1);
				$duration = $self->{'cache_hit_duration'};
			}

			$self->_debug(Data::Dumper->new([$l2value])->Dump()) if($self->{'debug'});

			# Do not push the not-found sentinel into L2
			if(!defined($value)) {
				# value is not-found; L1 sentinel is sufficient
			} elsif(ref($self->{'cache'}) eq 'HASH') {
				$self->{'cache'}->{$key} = $l2value;
			} else {
				# L2 is only an optimisation: a store that is down must not
				# lose the caller the result that has already been found
				local $@;
				eval { $self->{'cache'}->set($key, $l2value, $duration); 1 }
					or $self->_warn(__PACKAGE__, ": cache set failed for '$key': $@");
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
			# A store that cannot be read is treated as a miss, so the lookup
			# goes to the geocoders rather than failing
			local $@;
			$rc = eval { $self->{'cache'}->get($key) };
			$self->_warn(__PACKAGE__, ": cache get failed for '$key': $@") if($@);
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

# A copy of one result fit for L2.  The geocoder object becomes its class name,
# since a handle it holds may not serialise, and unless $keep_all only geometry
# is kept, to keep the entry small.  Anything that is not a HASH-based
# reference is returned as it is.
sub _l2_copy {
	my ($item, $keep_all) = @_;

	return $item unless ref($item) && (reftype($item) eq 'HASH');

	my $copy = { %{$item} };
	$copy = bless $copy, ref($item) if blessed($item);

	$copy->{'geocoder'} = ref($copy->{'geocoder'}) if ref($copy->{'geocoder'});

	# A blessed object keeps its fields: its accessors may rely on them
	unless($keep_all || blessed($item)) {
		delete @{$copy}{grep { $_ ne 'geometry' } keys %{$copy}};
	}

	return $copy;
}

# Whether a result carries a latitude, looked for without auto-vivifying the
# path to it in a structure that may be shared with the caller
sub _has_lat {
	my $item = shift;

	return 0 unless ref($item->{geometry}) eq 'HASH';
	return 0 unless ref($item->{geometry}{location}) eq 'HASH';
	return defined($item->{geometry}{location}{lat}) ? 1 : 0;
}

# Emit a debug message somewhere
sub _debug {
	my $self = shift;

	# Callers may end the message with a newline or not; it is printed with
	# exactly one, and given to the logger with none
	my $message = join('', map { $_ // '' } @_);
	$message .= "\n" unless($message =~ /\n\z/);

	if(my $logger = $self->{logger}) {
		(my $line = $message) =~ s/\n\z//;
		$logger->debug($line);
	}
	if($self->{debug}) {
		print $message;
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

=head1 COMMON PITFALLS

=over 4

=item * B<Scalar context and list context give different answers.>

C<geocode()> and C<reverse_geocode()> return one answer in scalar
context and all answers in list context.  Perl decides the context from
the code around the call, and some places give list context when you may
not expect it:

    my %row = (name => $name, place => $list->geocode($name));  # list context!
    print 'Found: ', $list->geocode($name);                     # list context!
    return $list->geocode($name);                               # your caller decides

When nothing is found, list context returns an I<empty list>, so in the
first example the keys and values of C<%row> move out of step.  Use
C<scalar()> to be sure:

    my %row = (name => $name, place => scalar($list->geocode($name)));

=item * B<C<undef> means "not found" and also "bad empty input".>

C<geocode()> returns C<undef> both when no geocoder knows the place and
when C<location> is C<undef> or empty (it also warns in that case).  Other
bad input, such as a reference or a string of digits, does not return
C<undef>: it croaks.  Wrap the call in C<eval> when the text comes from
outside your program.

=item * B<"Not found" is remembered for the life of the object.>

When no geocoder finds a place, L1 remembers that, and later calls for
the same place return C<undef> at once without asking any geocoder, even
if a geocoder was only down for a moment.  C<flush()> does not forget it,
and nor does a clone, which shares L1.  Make a new object with
C<Geo::Coder::List-E<gt>new()> to ask again.  L2 never stores "not
found".

=item * B<An answer from L2 has only its position.>

To keep L2 small, only C<geometry> is stored there (unless C<debug> is
set).  An answer that comes from L2, for example in a new run of your
program, has C<geometry>, C<lat>, C<lng>, C<lon> and C<geocoder> (set to
C<'cache'>), but none of the provider's other fields, such as an address
or a place type.  Answers from L1 keep every field.

=item * B<The C<geocoder> key is not always an object.>

It is the geocoder object when a geocoder answered, and the string
C<'cache'> when the cache answered.  Do not call methods on it without
checking.  To get a printable name in both cases:

    my $source = ref($result->{geocoder}) || $result->{geocoder};

=item * B<Changing an answer changes the cache.>

The first answer for a place is the same hash that L1 stores.  If you
change it, later answers for that place, which are copies of the L1 entry,
include your change.  Copy the answer before you change it.

=item * B<The hash you give to C<push()> is changed.>

C<limit> counts down inside the hash reference that you pushed.  If you
push the same hash reference into two lists, they share one limit.  A
clone made with C<< $list->new() >> has its own copy.

=item * B<The cache key is the exact text.>

C<'Paris, France'>, C<'paris, france'> and C<'Paris,France'> are three
different keys, and each one asks the geocoders again.  Only runs of
white space are made into one space before the text is used as a key.

=item * B<HTML entities are always decoded.>

C<'AT&amp;T Park'> is looked up as C<'AT&T Park'>.  There is no way to
look up text that really contains C<&amp;>.

=item * B<Strings of digits depend on an optional module.>

When L<Geo::Location::Predicate> is installed, C<geocode('12345')> croaks.
When it is not installed, C<'12345'> is sent to the geocoders.  If you
handle postcodes or ZIP codes, add the country, such as
C<'12345, USA'>.

=item * B<C<reverse_geocode()> ignores C<regex>.>

A geocoder added with C<regex> is still asked to reverse geocode every
position.  Only C<limit> is honoured.

=item * B<The log grows until you empty it.>

Every call adds to the log.  In a long-running program, such as a web
server, call C<flush()> from time to time.

=item * B<Debug output goes to standard output.>

With C<debug> set, messages are printed to C<STDOUT>, not C<STDERR>, so
they mix with your program's own output.  The same messages are always
given to the configured C<logger> at debug level, whether C<debug> is set
or not, so a logger is the way to collect them somewhere else.

=back

=head1 ENCODING

=over 4

=item * B<Place names> (C<location> in C<geocode()>) may contain any
Unicode text, including accented letters, other alphabets and emoji.
Give them to C<geocode()> as Perl I<character> strings: if your text is
UTF-8 bytes from a file or a web form, decode it first, for example with
C<Encode::decode('UTF-8', $bytes)>.  HTML entities in the text are decoded
into characters, so text that mixes UTF-8 bytes that are not yet decoded
with entities becomes garbled.  The text is passed to each geocoder unchanged apart from
that; whether a geocoder understands emoji is up to the geocoder.

=item * B<White space.>  Runs of ASCII spaces, tabs and new lines are
always made into one space.  Unicode spaces, such as the no-break space,
may or may not be, depending on how Perl stores the string; do not rely on
it.

=item * B<Positions> (C<latlng> in C<reverse_geocode()>) must be ASCII.
Only the digits C<0> to C<9> are accepted.  Other Unicode digits, such as
Eastern Arabic or full-width digits, are refused.

=item * B<Cache keys> are the cleaned text, so they can contain any
character.  L1 and a plain-hash L2 accept them all.  An L2 object must
accept character-string keys; L<CHI> does.

=item * B<Answers> are returned as the geocoder gave them.  Most
geocoders return character strings.

=item * B<Debug output> prints place names to C<STDOUT>.  If they contain
characters above 255, Perl warns C<Wide character in print> unless
C<STDOUT> has an encoding layer, such as
C<binmode(STDOUT, ':encoding(UTF-8)')>.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-geo-coder-list at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List>.

Known limitations:

=over 4

=item * C<reverse_geocode()> does not yet support L<Geo::Location::Point> objects.

=item * C<reverse_geocode()> does not honour C<regex>.

=back

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Geo-Coder-List/coverage/>

=item * L<CHI>

=item * L<Geo::Coder::All>

=item * L<Geo::Coder::GooglePlaces>

=item * L<Geo::Coder::Many>

=item * L<Geo::Location::Predicate>

=item * L<HTML::GoogleMaps::V3>

=item * L<HTML::OSM>

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

=head1 FORMAL SPECIFICATION

The specifications below use the Z notation.  They describe what each
method does to the state of the object; they do not describe how.

=head2 State

    [Geocoder, Regex, Text, Result, LogEntry, Duration]

    Key         == Text
    NotFound    ::= notFound
    Entry       ::= plain⟨⟨Geocoder⟩⟩
                  | routed⟨⟨Geocoder × ℙ Text × (ℤ ∪ {∞})⟩⟩
                    -- the geocoder, the texts its regex matches, its limit

    ┌─ GeoCoderList ─────────────────────────────────────────────────
    │ geocoders : seq Entry
    │ L1        : Key ⇸ (Result ∪ NotFound)
    │ L2        : Key ⇸ Result
    │ log       : seq LogEntry
    │ debug     : 0 ‥ 2
    │ hit, part, miss : Duration
    ├────────────────────────────────────────────────────────────────
    │ notFound ∉ ran L2
    │ ∀ r : ran L2 • dom r ⊆ {geometry, geocoder}  ∨  debug > 0
    └────────────────────────────────────────────────────────────────

    usable : ℙ Result
    usable = { r : Result | r.geometry.location.lat ≠ ⊥
                          ∧ r.geometry.location.lng ≠ ⊥ }

    clean : Text → Text
    -- runs of white space become one space; HTML entities are decoded

    isPlace : (Text ∪ Reference) → 𝔹
    -- Geo::Location::Predicate::_valid_location when installed;
    -- otherwise true for every non-empty Text and false for a Reference

=head2 new

    ┌─ New ──────────────────────────────────────────────────────────
    │ GeoCoderList′
    │ args? : Key ⇸ Value
    ├────────────────────────────────────────────────────────────────
    │ geocoders′ = args?(geocoders) if geocoders ∈ dom args?, else ⟨⟩
    │ L1′  = ∅
    │ log′ = ⟨⟩
    │ L2′  = args?(cache) if cache ∈ dom args?, else ∅
    │ hit′ = 1 month ∧ part′ = 1 day ∧ miss′ = 1 week   -- unless given
    └────────────────────────────────────────────────────────────────

    ┌─ Clone ────────────────────────────────────────────────────────
    │ GeoCoderList ; GeoCoderList′
    │ args? : Key ⇸ Value
    ├────────────────────────────────────────────────────────────────
    │ geocoders′ = geocoders            -- equal values, distinct copies
    │ L1′ = L1 ∧ L2′ = L2               -- the same stores, shared
    │ log′ = ⟨⟩
    └────────────────────────────────────────────────────────────────

=head2 push

    ┌─ Push ─────────────────────────────────────────────────────────
    │ ΔGeoCoderList
    │ g? : Entry
    ├────────────────────────────────────────────────────────────────
    │ g? ≠ ⊥
    │ geocoders′ = geocoders ⁀ ⟨g?⟩
    │ L1′ = L1 ∧ L2′ = L2 ∧ log′ = log
    └────────────────────────────────────────────────────────────────

    PushUndef ≙ [ ΞGeoCoderList ; g? : Entry | g? = ⊥ ] ⇒ croak

=head2 geocode

    asks : Entry × Text ⇸ 𝔹
    asks(plain g, t)          = true
    asks(routed(g, M, n), t)  = t ∈ M ∧ n > 0

    spend : Entry × Text → Entry
    spend(routed(g, M, n), t) = routed(g, M, n − 1)   if t ∈ M ∧ n > 0
    spend(e, t)               = e                      otherwise

    ┌─ Geocode ──────────────────────────────────────────────────────
    │ ΔGeoCoderList
    │ loc?    : Text ∪ Reference
    │ result! : Result ∪ {⊥}
    ├────────────────────────────────────────────────────────────────
    │ let t == clean(loc?) •
    │   ¬ isPlace(t) ⇒ croak
    │
    │   t ∈ dom L1 ∧ L1(t) ∈ Result
    │     ⇒ result! = L1(t) ⊕ {geocoder ↦ cache}
    │        ∧ geocoders′ = geocoders ∧ L1′ = L1
    │
    │   t ∈ dom L1 ∧ L1(t) = notFound
    │     ⇒ result! = ⊥ ∧ geocoders′ = geocoders ∧ L1′ = L1
    │
    │   t ∉ dom L1
    │     ⇒ (∃ i : dom geocoders •
    │            asks(geocoders i, t)
    │          ∧ (∀ j : 1 ‥ i − 1 • ¬ asks(geocoders j, t)
    │                              ∨ answer(geocoders j, t) ∉ usable)
    │          ∧ answer(geocoders i, t) ∈ usable
    │          ∧ result! = answer(geocoders i, t)
    │          ∧ L1′ = L1 ⊕ {t ↦ result!}
    │          ∧ L2′ = L2 ⊕ {t ↦ result! ↾ {geometry, geocoder}})
    │      ∨ (result! = ⊥ ∧ L1′ = L1 ⊕ {t ↦ notFound} ∧ L2′ = L2)
    │
    │   geocoders′ = ⟨ e : geocoders • spend(e, t) ⟩   -- for those asked
    │   log′ = log ⁀ ⟨ one entry per geocoder asked, or one for the cache ⟩
    └────────────────────────────────────────────────────────────────

=head2 ua

    ┌─ UA ───────────────────────────────────────────────────────────
    │ ΞGeoCoderList
    │ ua? : UserAgent ∪ {⊥}
    │ ua! : UserAgent ∪ {⊥}
    ├────────────────────────────────────────────────────────────────
    │ ua? = ⊥ ⇒ ua! = ⊥
    │ ua? ≠ ⊥ ⇒ ua! = ua?
    │         ∧ (∀ e : ran geocoders • geocoderOf(e) ≠ ⊥ ∨ croak)
    │         ∧ (∀ e : ran geocoders •
    │              geocoderOf(e).ua′ = clone(ua?)   if ua? can clone and agent
    │              geocoderOf(e).ua′ = ua?          otherwise)
    └────────────────────────────────────────────────────────────────

=head2 reverse_geocode

    LatLng == { s : Text | s ∈ ⟦ ^W*[-+]?D W*,W*[-+]?D W*$ ⟧ }
    -- D is a decimal number written in the ASCII digits 0-9;
    -- W is a space or a tab

    ┌─ ReverseGeocode ───────────────────────────────────────────────
    │ ΔGeoCoderList
    │ latlng?  : Text
    │ address! : Text ∪ {⊥}
    ├────────────────────────────────────────────────────────────────
    │ latlng? ∉ LatLng ⇒ croak
    │
    │ latlng? ∈ dom L1 ⇒ address! = first(L1(latlng?)) ∧ L1′ = L1
    │
    │ latlng? ∉ dom L1
    │   ⇒ (∃ i : dom geocoders •
    │          limitOf(geocoders i) > 0
    │        ∧ addresses(geocoders i, latlng?) ≠ ⟨⟩
    │        ∧ address! = head addresses(geocoders i, latlng?)
    │        ∧ L1′ = L1 ⊕ {latlng? ↦ address!})
    │    ∨ (address! = ⊥ ∧ L1′ = L1)
    └────────────────────────────────────────────────────────────────

=head2 log

    ┌─ Log ──────────────────────────────────────────────────────────
    │ ΞGeoCoderList
    │ entries! : seq LogEntry
    ├────────────────────────────────────────────────────────────────
    │ entries! = log
    └────────────────────────────────────────────────────────────────

=head2 flush

    ┌─ Flush ────────────────────────────────────────────────────────
    │ ΔGeoCoderList
    │ self! : GeoCoderList
    ├────────────────────────────────────────────────────────────────
    │ log′ = ⟨⟩
    │ geocoders′ = geocoders ∧ L1′ = L1 ∧ L2′ = L2
    │ self! = θGeoCoderList′
    └────────────────────────────────────────────────────────────────

=head1 STATE DIAGRAM

An object has three parts that change over time: its chain of geocoders,
its cache (one state for each place name), and its log.  Each part is
shown on its own below.

=head2 The object and its chain

    +-------------+  push($g)        +--------------+  push($g)
    |   EMPTY     |----------------->|    READY     |<-----------+
    | no geocoder |  adds $g to the  | 1+ geocoders |------------+
    +-------------+  end of chain    +--------------+  adds $g to the end
          |                                 |
          | geocode($t)                     | new() on the object
          | reverse_geocode($p)             | clone: copies the chain and
          v                                 | limits, shares L1 and L2,
    returns undef / ()                      | empties the log
    nothing is asked, but a                 v
    geocode() miss is still          +--------------+
    remembered in L1                 | READY (clone)|
                                     +--------------+

=head2 The cache, for one place name $t

    +-----------+ geocode($t): a geocoder gives a usable answer
    |           |----------------------------------------------+
    |  UNKNOWN  |  - answer stored in L1                       |
    | not in L1 |  - copy with only geometry stored in L2,     |
    |           |    kept for cache_hit_duration (1 month)     |
    +-----------+  - log gets one entry per geocoder asked     |
       |  ^                                                    v
       |  |                                             +-----------+
       |  | L2 entry expires, and a new object          |  FOUND    |<--+
       |  | is used (L1 dies with its object)           |  L1 holds |   | geocode($t):
       |  +---------------------------------------------| an answer |---+ no geocoder
       |                                                +-----------+   asked; a copy
       | geocode($t): no geocoder gives a usable answer                 returned with
       |  - L1 stores "not found"; L2 is not written                    geocoder='cache';
       |  - log gets one entry per geocoder asked                       log gets one
       v                                                                cache entry
    +-----------+
    | NOT FOUND |<--+ geocode($t): nothing asked, undef / () returned,
    | in L1     |---+ nothing logged
    +-----------+
          |
          +-- leaves this state only when the object is destroyed;
              flush() and clones do not leave it

    Any state: geocode($t) with a reference, digits (when
    Geo::Location::Predicate is installed) or entity-encoded digits
    --> croaks; the state does not change.

=head2 The limit of one geocoder pushed with limit => N

    +--------------+ geocode($t), $t matches regex   +--------------+
    |  ACTIVE      |-------------------------------->|  ACTIVE      |
    |  limit = n   |  geocoder asked; limit = n - 1  |  limit = n-1 |
    +--------------+                                 +--------------+
       |      ^                                             |
       |      | geocode($t), $t does not match regex:       | ... when the
       |      | geocoder not asked, limit unchanged         | limit reaches 0
       +------+                                             v
                                                     +--------------+
                                                     |  EXHAUSTED   |<--+
                                                     |  limit <= 0  |---+
                                                     +--------------+ geocode() and
                                                                      reverse_geocode():
                                                                      skipped, never asked

=head2 The log

    +-----------+  geocode() or reverse_geocode()   +-------------+
    |  EMPTY    |---------------------------------->|  HAS        |<--+
    |  log = [] |  appends one entry per geocoder   |  ENTRIES    |---+ geocode() /
    +-----------+  asked, or one for a cache hit    +-------------+   reverse_geocode():
         ^                                                 |          appends entries
         |               flush(): log = [], returns $self  |
         +-------------------------------------------------+
         ^
         | new() and clone: start EMPTY

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
