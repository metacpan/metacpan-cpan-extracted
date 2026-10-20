package Geo::Coder::Free;

use strict;
use warnings;
use autodie qw(:all);

use Carp;
use Config::Auto;
use Geo::Coder::Free::Local;
use Geo::Coder::Free::MissCache;
use Geo::Coder::Free::MaxMind;
use Geo::Coder::Free::OpenAddresses;
use Geo::Coder::Free::Utils qw(_abbreviate _normalize);
use Geo::Location::Predicate qw(_valid_location);
use Object::Configure;
use Params::Get;
use Readonly;
use Scalar::Util;

=head1 NAME

Geo::Coder::Free - Geocoding using free, locally-hosted databases

=head1 VERSION

Version 0.48

=cut

our $VERSION = '0.48';

=encoding utf-8

=head1 SYNOPSIS

    use Geo::Coder::Free;

    my $geo = Geo::Coder::Free->new();
    my $pt  = $geo->geocode(location => 'Ramsgate, Kent, UK');
    printf "%.6f, %.6f\n", $pt->lat(), $pt->long();

    # With OpenAddresses/WhoOnFirst data:
    my $geo2 = Geo::Coder::Free->new(openaddr => $ENV{OPENADDR_HOME});
    my $pt2  = $geo2->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');

    # Free-text scanning:
    my @hits = $geo2->geocode(scantext => 'She grew up in Ramsgate, Kent.',
                              region   => 'GB');

=head1 DESCRIPTION

C<Geo::Coder::Free> translates addresses into latitude/longitude coordinates
using local SQLite databases built from free data sources - MaxMind/GeoNames,
OpenAddresses, Who's On First, OpenStreetMap, and dr5hn's countries/states/cities
database.  It deliberately avoids paid or rate-limited online geocoding services.
The module is designed to be flexible, supporting both command-line and programmatic usage.
It also includes a sample CGI script for a web-based geocoding service.

Geocoding dispatch order depends on whether C<OPENADDR_HOME> (or C<openaddr>) is set:

B<With OpenAddresses data:>

=over 4

=item 1. C<Geo::Coder::Free::OpenAddresses> - requires C<OPENADDR_HOME>

=item 2. C<Geo::Coder::Free::Local> - user-curated CSV entries (tried as fallback)

=item 3. C<Geo::Coder::Free::MaxMind> - bundled, always available

=back

B<Without OpenAddresses data:>

=over 4

=item 1. C<Geo::Coder::Free::MaxMind> only - Local is not consulted.

=back

The C<cgi-bin> directory contains a simple DIY geo-coding website:

    cgi-bin/page.fcgi page=query q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA

The sample website is currently down while a new host is sought.
When it returns, you will be able to test it with:

    curl 'https://geocode.nigelhorne.com/cgi-bin/page.fcgi?page=query&q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA'

=head1 LIMITATIONS

=over 4

=item * C<scantext> mode only finds locations in OpenAddresses; it falls back
silently when C<OPENADDR_HOME> is not set (B<FIXME>: should warn).

=item * The C<__DATA__> alternatives table is hard-coded; it should live in a
user-editable config file.

=item * The address-regex scantext path misses birth-year sentences such as
C<"She was born May 21, 1937 in Noblesville, IN."> because the regex requires
a preceding capital-letter word directly before the city.

=item * C<reverse_geocode> is only partially implemented; the MaxMind path does
not return meaningful results.

=item * The C<alternatives> map loop uses C<each %{$alt}>, which retains its
iterator position across calls.  After a successful match and early C<return>,
the next C<geocode()> call on the same input starts iterating from the key
B<after> the matched one, potentially missing the match entirely until C<each>
wraps around.  Workaround: call C<keys %{$alt}> once to reset the iterator
before iterating.

=back

=cut

# -----------------------------------------------------------------------
# Module-level singletons — initialised once, shared across all instances.
# Using 'our' so that test code can reset them between test runs if needed.
# -----------------------------------------------------------------------
our $alternatives;

# -----------------------------------------------------------------------
# Error-message table.  All user-facing strings live here so that a future
# i18n layer only needs to swap this hash, not touch every call site.
# -----------------------------------------------------------------------
my %_MESSAGES = (
	usage_geocode       => 'Usage: %s::geocode(location => $location|scantext => $text)',
	usage_geocode_many  => 'Usage: %s::geocode_many(\@values, region => $region, on_error => "croak"|"undef")',
	usage_reverse       => 'Usage: %s::reverse_geocode(latlng => "$lat,$long")',
	invalid_location    => '%s: invalid location to geocode(), %s',
	invalid_scantext    => '%s: invalid scantext to geocode(), %s',
	invalid_on_error    => '%s: on_error must be "croak" or "undef", not %s',
	reserved_location   => '%s: "%s" is one of the keys geocode_many() answers with, so it cannot be one of the values it looks up',
	geocoding_failed    => '%s: geocoding failed',
	reverse_unsupported => 'Reverse lookup is not yet supported',
	use_arrow_new       => '%s: use ->new() not ::new() to instantiate',
	bad_ref_arg         => 'Usage: %s — do not pass a non-hash reference',
);

# Confidence thresholds for scantext results, expressed as named constants
# rather than magic numbers so call sites document intent.
Readonly::Scalar my $CONF_TRIPLET => 0.8;
Readonly::Scalar my $CONF_DUPLET  => 0.7;
Readonly::Scalar my $CONF_REGEX   => 0.7;

# The keys geocode_many() answers with besides the values themselves.  The map
# and the counts share one hashref, so a value spelled like one of these would
# overwrite what the name stands for, and it is refused by name instead
Readonly::Array my @RESULT_KEYS => qw(lookups reads resolved unresolved unresolved_values);

# The backends geocode_many() reports its reads for: the slots of the facade
# that hold them, and the name each is reported under.  The names are the short
# vocabulary provenance() reports a result's backend in, so that the backend
# that read a value and the backend a result came from are spelled the same way
# and a caller can read the two together.
Readonly::Hash my %_BACKEND_NAMES => (
	maxmind  => 'MaxMind',
	local    => 'Local',
	openaddr => 'OpenAddresses',
);

# Stopwords excluded from word-window scantext searches.
my %_COMMON_WORDS = map { $_ => 1 } qw(
	a age an and at be by cross for how i in is more of on or over pm
	road she side some the to was with
);

=head1 METHODS

=head2 new

=head3 SYNOPSIS

    my $geo = Geo::Coder::Free->new();
    my $geo = Geo::Coder::Free->new(openaddr => '/data/openaddr');
    my $geo = Geo::Coder::Free->new(directory => '/data/maxmind');

=head3 DESCRIPTION

Constructor.  Accepts a hash or hashref of options.  If called without
C<openaddr>, the module checks C<$ENV{OPENADDR_HOME}> before giving up.

If called on an existing object instance (C<< $clone = $geo->new() >>), returns
a B<shallow clone>.  All scalar fields are copied by value, but reference-type
fields (C<alternatives>, C<scantext_misses>, C<maxmind>, C<openaddr>) share the
same underlying object or hashref between the original and the clone.  Mutations
to those shared references are immediately visible in both objects.

=head3 API SPECIFICATION

=head4 input

    # Input schema (Params::Validate::Strict)
    openaddr  => { type => 'scalar', optional => 1 }                          # path to OpenAddresses/WOF data dir
    directory => { type => 'scalar', optional => 1 }                          # path to MaxMind/GeoNames files
    cache     => { type => 'object', optional => 1, can => ['get', 'set'] }   # CHI-compatible cache object

=head4 output

    # Output schema (Return::Set)
    { type => 'object', isa => 'Geo::Coder::Free' }

=head3 EXAMPLE

    use Geo::Coder::Free;

    # Minimal - uses only the bundled MaxMind data:
    my $geo = Geo::Coder::Free->new();

    # Full - also searches OpenAddresses/WOF:
    my $geo = Geo::Coder::Free->new(openaddr => $ENV{OPENADDR_HOME});

=head3 MESSAGES

    use ->new() not ::new()   Called as a function; use arrow syntax.

=cut

sub new {
	my $class = shift;

	my $params = Params::Get::get_params(undef, @_) // {};

	# Called as a function (Geo::Coder::Free::new) rather than a method
	if (!defined($class)) {
		if (keys %{$params}) {
			Carp::carp(_i18n('use_arrow_new', __PACKAGE__));
			return;
		}
		$class = __PACKAGE__;	# FIXME: only works with no arguments
	} elsif (Scalar::Util::blessed($class)) {
		return bless { %{$class}, %{$params} }, ref($class);
	}

	# Populate the alternatives map once from __DATA__ and cache it
	# across all instances.  Config::Auto parses the INI-like DATA block.
	if (!$alternatives) {
		my $keep = $/;
		local $/ = undef;
		my $data = <DATA>;
		$/ = $keep;

		$alternatives = Config::Auto->new(source => $data)->parse();
		# Config::Auto turns multi-value keys into arrayrefs; flatten them.
		while (my ($key, $value) = each %{$alternatives}) {
			$alternatives->{$key} = join(', ', @{$value});
		}
	}

	# Resolve OPENADDR_HOME before Object::Configure so plug-ins can see it
	if (!defined($params->{'openaddr'}) && $ENV{'OPENADDR_HOME'}) {
		$params->{'openaddr'} = $ENV{'OPENADDR_HOME'};
	}

	$params = Object::Configure::configure($class, $params);

	my $rc = {
		%{$params},
		maxmind      => Geo::Coder::Free::MaxMind->new($params),
		alternatives => $alternatives,
	};

	if ($params->{'openaddr'}) {
		$rc->{'openaddr'} = Geo::Coder::Free::OpenAddresses->new(id => 'md5', %{$params});
	}
	if (my $cache = $params->{'cache'}) {
		$rc->{'cache'} = $cache;
	}

	return bless $rc, $class;
}

=head2 valid_location

=head3 SYNOPSIS

    if ($geo->valid_location($row->{'place'})) {
        push @found, $geo->geocode(location => $row->{'place'});
    }

=head3 DESCRIPTION

Answers whether a string is something this module will even try to look up.
It is the public form of the rule C<geocode()> applies before it touches a
backend, so a caller working down a spreadsheet column can skip a row whose
value is a bare number - or is empty - instead of catching the croak that
would otherwise kill the whole run.  That rule is defined once, in
L<Geo::Location::Predicate>, and the backends apply it too: what
C<valid_location()> refuses is refused wherever it is looked up.

Only that cheap syntactic test is answered.  A true result means the string is
not disqualified, B<not> that a backend knows it: C<'Ramsgate, Kent'> is valid
and may still find nothing, while C<'0044'> is invalid and is never looked up.
The rule rejects a string of digits only, which is what a numeric column holds
when the wrong column has been read, so anything with a non-digit in it counts
as valid - C<'3.14'> and C<'-'> included.  C<undef>, C<''> and a reference are
not valid.

=head3 API SPECIFICATION

=head4 input

    location => { type => 'scalar', optional => 1 }  # the string to test

=head4 output

    { type => 'boolean' }  # false for undef, '' and a digit-only string

=head3 EXAMPLE

    my $geo = Geo::Coder::Free->new();

    $geo->valid_location('Ramsgate, Kent');   # true
    $geo->valid_location('0044');             # false - never a location
    $geo->valid_location('');                 # false
    $geo->valid_location(undef);              # false

Accepts the three calling conventions the rest of this module does:

    $geo->valid_location('0044');
    Geo::Coder::Free->valid_location('0044');
    Geo::Coder::Free::valid_location('0044');

=cut

sub valid_location {
	my $self = shift;

	# The location is whichever argument is not the invocant, so that the
	# predicate reads the same whether it is called on an instance, on the
	# class or as a plain function.
	my $location;
	if (ref($self)) {
		$location = shift;
	} elsif (@_) {
		$location = shift;
	} elsif (defined($self) && $self ne __PACKAGE__) {
		$location = $self;
	}

	return _valid_location($location) ? 1 : 0;
}

=head2 geocode

=head3 SYNOPSIS

    # Standard lookup (returns a Geo::Location::Point or undef)
    my $pt = $geo->geocode(location => 'Ramsgate, Kent, UK');
    printf "lat=%.6f lon=%.6f\n", $pt->lat(), $pt->long();

    # Scantext - returns a list of Geo::Location::Point objects
    my @hits = $geo->geocode(
        scantext     => 'She lived in Ramsgate, Kent.',
        region       => 'GB',
        ignore_words => [qw(lived)],
    );

    # Invocation flexibility (all equivalent)
    $geo->geocode('Ramsgate, Kent, UK');
    $geo->geocode({ location => 'Ramsgate, Kent, UK' });
    $geo->geocode(location => 'Ramsgate, Kent, UK');

    # A batch caller with a dirty column: skip the row, do not kill the run
    for my $place (@column) {
        my $pt = $geo->geocode(location => $place, on_error => 'undef');
        next unless defined $pt;
        push @found, $pt;
    }

=head3 DESCRIPTION

A location or a scantext that is not a location at all - a bare number, such as
the C<0044> a numeric column holds - is refused before any backend is
touched.  C<valid_location()> answers the same question, so a caller can filter
first; C<on_error> chooses what happens when one gets through anyway:

=over 4

=item * C<'croak'> (the default) - C<Carp::croak>, the behaviour every existing
caller already has.

=item * C<'undef'> - return C<undef>, so one bad row in a spreadsheet column is
skipped rather than ending the run.  It changes the answer for B<only> the two
documented input errors below; an exception from a backend is still an
exception, and a malformed argument list still croaks.

=back

The option is deliberately narrow, so a batch caller wants C<valid_location()>
with it: that predicate answers false for C<undef> and C<''> as well, which are
the other two things an empty cell holds.  A call with neither a location nor a
scantext is a usage error rather than an input error - the same croak as calling
C<geocode()> with no arguments - and stays a croak on either setting.

=head3 API SPECIFICATION

=head4 input

    # Input schema (Params::Validate::Strict) - exactly one of location or scantext is required
    location     => { type => 'scalar',   optional => 1 }  # address string (exclusive with scantext)
    scantext     => { type => 'scalar',   optional => 1 }  # free text to scan for place names
    region       => { type => 'scalar',   optional => 1 }  # ISO 3166-1 alpha-2 country code hint
    ignore_words => { type => 'arrayref', optional => 1 }  # words to suppress during scantext scan
    on_error     => { type => 'scalar',   optional => 1 }  # 'croak' (default) or 'undef'

=head4 output

    # Output schema (Return::Set)
    # scalar context: { type => 'object',   isa => 'Geo::Location::Point', optional => 1 }
    # list context:   { type => 'arrayref', of  => { isa => 'Geo::Location::Point' } }

=head4 provenance

Every result carries C<geocoder>, C<database>, C<confidence> and C<accuracy>
which distribution produced
it, which backend answered, how good the match was, and how precise the
coordinate is.  C<provenance()> reads the four back.  C<location> is set by every
path but the MaxMind cities one, and C<text> only by a scantext lookup; C<lat>,
C<long> and C<lng> come from the value object itself.

=head3 MESSAGES

    Usage: ...::geocode(...)        No location or scantext argument given.
    invalid location to geocode()   location is purely numeric.
    invalid scantext to geocode()   scantext is purely numeric.
    on_error must be ...            on_error is neither 'croak' nor 'undef'.

=head3 PSEUDOCODE

    if self is not a blessed object → delegate to new()->geocode(@args)
    normalise @_ into %params
    validate: on_error is 'croak' or 'undef' (croak if not)
    validate: location is not purely numeric; scantext is not purely numeric
              (undef instead of croaking when on_error is 'undef')
    if openaddr backend is available:
        if scantext:
            try the raw scantext string as a direct location
            build stopword set from %_COMMON_WORDS + ignore_words param
            try 3-word windows (triplets) at confidence 0.8
            try 2-word windows (duplets) at confidence 0.7
            try the address-pattern regex at confidence 0.7
            try region-specific address finders (GB / US / CA)
            mark scantext as a miss; return undef
        else:
            try openaddr backend
            try local backend
            try __DATA__ alternatives map
    try maxmind backend for location lookups
    croak if no scantext and no location

=cut

sub geocode {
	my $self = shift;

	# Handle being called as a function rather than a method
	if (!ref($self)) {
		if (scalar @_) {
			return __PACKAGE__->new()->geocode(@_);
		} elsif (!defined($self)) {
			Carp::croak(_i18n('usage_geocode', __PACKAGE__));
		} elsif ($self eq __PACKAGE__) {
			Carp::croak(_i18n('usage_geocode', $self));
		}
		return __PACKAGE__->new()->geocode($self);
	} elsif (ref($self) eq 'HASH') {
		return __PACKAGE__->new()->geocode($self);
	}

	my %params = _normalize_args(_i18n('usage_geocode', __PACKAGE__), 'location', @_);

	# What to do with an input this module rejects before it touches a backend.
	# 'croak' is the historical behaviour and stays the default, so no existing
	# caller changes; 'undef' is for a batch caller working down a dirty column,
	# which wants the row skipped rather than the whole run killed.  Only the two
	# input errors below consult it: a backend that throws still throws, because
	# nothing here is wrapped in an eval
	my $on_error = $params{'on_error'} // 'croak';
	Carp::croak(_i18n('invalid_on_error', __PACKAGE__, $on_error))
		unless $on_error eq 'croak' || $on_error eq 'undef';

	# Reject pure-numeric inputs early — they are never valid addresses.
	# The rule is Geo::Location::Predicate's, the same one the backends
	# apply, and valid_location() answers it in public, so a caller can
	# pre-filter with it and never reach this croak at all.
	if (defined($params{'location'}) && !_valid_location($params{'location'})) {
		return if !length($params{'location'}) || ($on_error eq 'undef');
		Carp::croak(_i18n('invalid_location', __PACKAGE__, $params{'location'}));
	}
	if (defined($params{'scantext'}) && !_valid_location($params{'scantext'})) {
		return if !length($params{'scantext'}) || ($on_error eq 'undef');
		Carp::croak(_i18n('invalid_scantext', __PACKAGE__, $params{'scantext'}));
	}

	if ($self->{'openaddr'}) {
		if (my $scantext = $params{'scantext'}) {
			return if $self->{'scantext_misses'}{$scantext};

			# First try the whole scantext as a direct location lookup —
			# saves work when the text happens to be a valid address string.
			$self->{'local'} ||= Geo::Coder::Free::Local->new();
			my @direct = grep { defined }
				$self->{'local'}->geocode($scantext),
				$self->{'openaddr'}->geocode($scantext),
				$self->{'maxmind'}->geocode($scantext);
			return @direct if @direct;

			my $region = $params{'region'};

			# Build the effective stopword set.  When the caller supplies no
			# ignore_words we avoid copying %_COMMON_WORDS (which is immutable
			# at runtime) by using a reference to it directly.  Only when extra
			# words are needed do we allocate and populate a merged hash.
			my $ignore_words;
			if (my $iw = $params{'ignore_words'}) {
				my %merged = %_COMMON_WORDS;
				$merged{lc $_} = 1 for @{$iw};
				$ignore_words = \%merged;
			} else {
				$ignore_words = \%_COMMON_WORDS;
			}

			my @rc;

			# 3-word window search
			my @triplets = _find_word_ngrams($scantext, 3, $ignore_words);
			my $res = $self->_resolve_scan_candidates(\@triplets, $region, $CONF_TRIPLET, $scantext);
			if (@{$res}) {
				return wantarray ? @{$res} : $res->[0];
			}

			# 2-word window search
			my @duplets = _find_word_ngrams($scantext, 2, $ignore_words);
			$res = $self->_resolve_scan_candidates(\@duplets, $region, $CONF_DUPLET, $scantext);
			if (@{$res}) {
				return wantarray ? @{$res} : $res->[0];
			}

			# Regex-based address pattern — catches "City, ST"-style fragments.
			# Note: misses sentences like "born May 21, 1937 in Noblesville, IN"
			# because the pattern requires a capitalised word before the city.
			my @regex_matches = $scantext =~
				/\b(?:\d+\s+)?(?:[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\.?),\s*
				 (?:[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*(?:,\s*[A-Z]{2,})*)\b/gx;
			my @places = grep { defined && $_ ne '' } @regex_matches;
			$res = $self->_resolve_scan_candidates(\@places, $region, $CONF_REGEX, $scantext);
			if (@{$res}) {
				return wantarray ? @{$res} : $res->[0];
			}

			# Region-specific structured address patterns
			if ($region) {
				my @candidates;
				if    ($region eq 'GB') { @candidates = _find_gb_addresses($scantext) }
				elsif ($region eq 'US') { @candidates = _find_us_addresses($scantext) }
				elsif ($region eq 'Canada') { @candidates = _find_ca_addresses($scantext) }

				if (@candidates) {
					my @regional;
					for my $candidate (@candidates) {
						next if $ignore_words->{lc $candidate};
						my @hits = grep { defined }
							$self->{'openaddr'}->geocode("$candidate, $region");
						push @regional, @hits if @hits;
					}
					return @regional if @regional;
				}
			}

			$self->{'scantext_misses'}{$scantext} = 1;
			return;
		}

		# Standard (non-scantext) lookup path
		if (wantarray) {
			my @rc = $self->{'openaddr'}->geocode(\%params);
			return @rc if @rc && $rc[0];
			$self->{'local'} ||= Geo::Coder::Free::Local->new();
			@rc = $self->{'local'}->geocode(\%params);
			return @rc if @rc && $rc[0];
		} else {
			if (my $rc = $self->{'openaddr'}->geocode(\%params)) {
				return $rc;
			}
			$self->{'local'} ||= Geo::Coder::Free::Local->new();
			if (my $rc = $self->{'local'}->geocode(\%params)) {
				return $rc;
			}
		}

		# Try the alternatives table — hand-curated mappings for locations that
		# the databases have under slightly different names.
		# M3 (transitive reduction): every scantext path inside this block returned
		# early above; at this point $params{'scantext'} is provably falsy, so the
		# former `if (!$params{'scantext'})` guard was a tautology — removed.
		if (my $alt = $self->{'alternatives'}) {
			my $location = $params{'location'};
			while (my ($key, $value) = each %{$alt}) {
				next unless $location =~ $key;
				(my $new_loc = $location) =~ s/$key/$value/;
				$params{'location'} = $new_loc;
				if (my $rc = $self->geocode(\%params)) {
					return $rc;
				}
				# Also try the comma-free variant ("Tyne and Wear" etc.)
				if ($value =~ /, /) {
					(my $flat = $value) =~ s/,//g;
					($new_loc = $location) =~ s/$key/$flat/;
					$params{'location'} = $new_loc;
					if (my $rc = $self->geocode(\%params)) {
						return $rc;
					}
				}
				# Restore for the next iteration
				$params{'location'} = $location;
			}
		}
	}

	# Final fallback: MaxMind for location lookups.
	# Scantext without OPENADDR_HOME will silently reach here and return undef;
	# a proper fix would warn here (see LIMITATIONS).
	# M8 (tautology elimination): both arms of the former wantarray ternary were
	# identical — collapsed to a single call; context propagates implicitly.
	if ($params{'location'}) {
		return $self->{'maxmind'}->geocode(\%params);
	}

	Carp::croak(_i18n('usage_geocode', __PACKAGE__)) unless $params{'scantext'};
	return;
}

=head2 geocode_many

=head3 SYNOPSIS

    my $batch = $geo->geocode_many(\@places, region => 'GB', on_error => 'undef');

    for my $place (@places) {
        my $pt = $batch->{$place};              # a Geo::Location::Point, or undef
        next unless defined $pt;
        printf "%s is at %.4f, %.4f\n", $place, $pt->lat(), $pt->long();
    }

    printf "geocoded %d of %d places in %d lookups\n",
        $batch->{'resolved'},
        $batch->{'resolved'} + $batch->{'unresolved'},
        $batch->{'lookups'};

=head3 DESCRIPTION

The loop a batch caller writes around C<geocode()>, run for it: one lookup per
B<distinct> value, with the same options and the same results, plus the counts
that caller would otherwise keep itself - how many values made a backend read,
how many resolved, how many did not, which ones, and which backend read for them

The hashref returned holds one entry per distinct value given, keyed by the
value, plus five keys of its own:

=over 4

=item * C<< $batch->{$value} >> - the C<Geo::Location::Point> the value resolved
to, or C<undef> if nothing did.  Every distinct value in the input is keyed, so
a caller walking a column can look each row up without first asking whether the
batch covered it.  An C<undef> in the input has no key of its own and shares the
entry of the empty string, which is not a location either.

=item * C<lookups> - how many distinct values made a backend read to answer
them: one per value, however many backends looked at it.  A value the module
refuses before any backend is touched - a bare number, C<''>, C<undef>, a
reference - is not counted, and neither is a value a backend answered from a
cache or from a hand-curated entry, because nothing was read for it.  This is
what makes the count the work a caller is capping rather than the work it asked
for.  A value repeated in the batch is one lookup.  Every backend reports its
reads through C<reads()>, and a value every backend has already missed is
remembered in L<Geo::Coder::Free::MissCache>, one process-level cache that all
backends and instances share, whose entries expire after an hour and can be
emptied early with L</clear_miss_cache>.  A later batch in the same process is
answered from those caches and so reports the reads it needed, often none, in
place of the ones the first batch made.

=item * C<reads> - how many reads each backend made for the batch, keyed by the
name C<provenance()> reports that backend under: C<MaxMind>, C<Local> or
C<OpenAddresses>.  Every backend the object holds is named, at zero for one that
read nothing, so a batch answered from a cache names its backends at zero rather
than naming none.  C<lookups> counts values and this counts reads - a value that
made two backends read is one lookup and a read for each of them, so these
numbers can add up to more than C<lookups> - and the two vocabularies are the
same, so a caller can put the backend that read a value beside the backend a
result came from.

=item * C<resolved> - how many distinct values produced a point.

=item * C<unresolved> - how many produced nothing, the refused values included.

=item * C<unresolved_values> - those values, in the order they were first seen,
so that a caller can record them as tried-and-failed rather than retrying them
on every request.  Section 2.5 sketches this list under the name C<unresolved>;
here C<unresolved> is the count a "geocoded N of M" message needs and the values
themselves are C<unresolved_values>.

=back

C<resolved> and C<unresolved> always add up to the number of distinct values
given, and the five keys above are reserved: a value equal to one of them is
refused by name, before anything is looked up, rather than allowed to overwrite
a count.

C<region> and C<on_error> are handed to every lookup and mean there what they
mean in C<geocode()>, including the rule that a backend exception is still an
exception - nothing here is wrapped in an C<eval>.  C<on_error> defaults to
C<'croak'> for the same reason it does there: a batch should not quietly plot
fewer points than its column holds unless the caller asked it to, and a caller
working down a dirty column asks for C<'undef'>.  The two settings do not differ
in which values are looked up, only in what happens to a value the module
refuses: C<'croak'> dies on it with the message C<geocode()> gives for it,
C<'undef'> counts it unresolved and carries on.

A batch of no values is not an error: the counts come back zero.

The values are treated as a set.  Repeating a value in the input looks it up
once and every row is keyed to the same point object, so a column that repeats
the same handful of places thousands of times costs the handful of lookups.

=head3 API SPECIFICATION

=head4 input

    # Input schema (Params::Validate::Strict) — values required, options optional
    values   => { type => 'arrayref' }                  # location strings, one per row
    region   => { type => 'scalar', optional => 1 }     # ISO 3166-1 alpha-2 country code hint
    on_error => { type => 'scalar', optional => 1 }     # 'croak' (the default) or 'undef'

=head4 output

    # Output schema (Return::Set)
    { type => 'hashref' }
    #   $result->{$value}            => { isa => 'Geo::Location::Point', optional => 1 }
    #   $result->{lookups}           => { type => 'integer' }
    #   $result->{reads}             => { type => 'hashref' }
    #   $result->{resolved}          => { type => 'integer' }
    #   $result->{unresolved}        => { type => 'integer' }
    #   $result->{unresolved_values} => { type => 'arrayref' }

=head3 MESSAGES

    Usage: ...::geocode_many(...)   No values argument, one that is not an arrayref,
                                    or options that are neither a list nor a hashref.
    invalid location to geocode()   A value refused under on_error => 'croak', with the
                                    message geocode() gives for that value.
    on_error must be ...            on_error is neither 'croak' nor 'undef'.
    <value> is one of the keys ...  A value spelled like one of the five returned keys.

=head3 EXAMPLE

    my $geo = Geo::Coder::Free->new(openaddr => $ENV{OPENADDR_HOME});

    # A log file's place column: repeats, a few unreadable values, one empty cell.
    my @places = ('Ramsgate, Kent', '0044', 'Nowhere, Imaginary, ZZ',
                  'Ramsgate, Kent', undef);

    my $batch = $geo->geocode_many(\@places, region => 'GB', on_error => 'undef');

    printf "geocoded %d of %d distinct places in %d lookups\n",
        $batch->{'resolved'},
        $batch->{'resolved'} + $batch->{'unresolved'},
        $batch->{'lookups'};        # 4 distinct places, 2 of them looked up

    # Which backend did the reading, and which answered from a cache: a backend
    # at zero answered nothing by reading.
    while (my ($backend, $reads) = each %{$batch->{'reads'}}) {
        print "$backend read $reads times\n";
    }

    for my $place ($batch->{'unresolved_values'}) {
        warn "no coordinates for '" . (defined($place) ? $place : '') . "'\n";
    }

=cut

sub geocode_many {
	my $self = shift;

	# The same calling conventions as the rest of the module, with the batch's
	# own spelling for the plain-function form: the values are always an
	# arrayref, so that is what a function call arrives holding.
	if (!Scalar::Util::blessed($self)) {
		return __PACKAGE__->new()->geocode_many($self, @_)
			if ref($self) eq 'ARRAY';
		Carp::croak(_i18n('usage_geocode_many', __PACKAGE__)) unless @_;
		return __PACKAGE__->new()->geocode_many(@_);
	}

	my $values = shift;
	Carp::croak(_i18n('usage_geocode_many', __PACKAGE__)) unless ref($values) eq 'ARRAY';

	# Options are a hashref or an even list.  A lone scalar is neither: there is
	# no bare-string form of a batch, so it is refused rather than guessed at.
	my $opts;
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		$opts = { %{$_[0]} };
	} elsif ((scalar @_) % 2 == 0 && !grep { ref } @_) {
		$opts = { @_ };
	} else {
		Carp::croak(_i18n('usage_geocode_many', __PACKAGE__));
	}

	my $on_error = $opts->{'on_error'} // 'croak';
	Carp::croak(_i18n('invalid_on_error', __PACKAGE__, $on_error))
		unless $on_error eq 'croak' || $on_error eq 'undef';

	my $region = $opts->{'region'};

	# A value spelled like one of the keys this method answers with would
	# overwrite it, so it is refused by name - before anything is looked up,
	# rather than after a count has been lost.
	my %reserved = map { $_ => 1 } @RESULT_KEYS;
	for my $value (@{$values}) {
		my $key = defined($value) ? $value : '';
		Carp::croak(_i18n('reserved_location', __PACKAGE__, $key)) if $reserved{$key};
	}

	my %results = map { $_ => 0 } @RESULT_KEYS;
	$results{'unresolved_values'} = [];
	$results{'reads'} = {};

	# A batch is a set: a value repeated in the input is looked up once, and
	# every row holding it is keyed to the same object.
	my %seen;
	for my $value (@{$values}) {
		# undef has no key of its own, and the empty string it shares is not a
		# location either, so it is unresolved without reaching a backend.
		my $key = defined($value) ? $value : '';
		next if $seen{$key}++;

		# What geocode() makes of this value on this setting is asked of
		# geocode() rather than written out again here: the guard, its message and
		# the choice of backend are all its own.  The backends' read counters are
		# taken around the call, so the value is counted as a lookup only if one of
		# them actually read: a value answered from a cache, or from a hand-curated
		# entry, is not counted as work the batch did not do.  Taking them per
		# backend rather than in total says which backend read, and which answered
		# from somewhere else: a read is added to the name of the backend that made
		# it, so a value two backends read through is one lookup and a read each.
		my $reads_before = $self->_backend_reads();
		my $point = $self->geocode(
			location => $key,
			defined($region) ? (region => $region) : (),
			on_error => $on_error,
		);
		my $reads_after = $self->_backend_reads();

		my $read = 0;
		foreach my $backend (keys %{$reads_after}) {
			my $reads = $reads_after->{$backend} - ($reads_before->{$backend} // 0);
			next unless $reads > 0;
			$results{'reads'}{$backend} += $reads;
			$read += $reads;
		}

		# A value the module refuses is not a lookup: it never reached a backend,
		# so it does not count against the work a caller is capping.
		$results{'lookups'}++ if _valid_location($key) && $read;
		$results{$key} = $point;

		if (defined($point)) {
			$results{'resolved'}++;
		} else {
			$results{'unresolved'}++;
			push @{$results{'unresolved_values'}}, $value;
		}
	}

	# A backend that read nothing is reported as well, at zero: what a caller is
	# asking is which backend read and which answered from a cache, and a backend
	# left out of the answer cannot be told from one that answered from one.
	# Local is built the first time a lookup falls through to it, so it appears
	# once it has been consulted, whether or not it found anything.
	foreach my $backend (keys %{$self->_backend_reads()}) {
		$results{'reads'}{$backend} //= 0;
	}

	return \%results;
}

# How much reading each backend has done so far, by the name it is reported
# under.  Counters rather than flags: the change across a call says which
# backend read for that value, and a backend that was never called cannot leave
# a stale flag behind.  A backend object may not exist yet - Local is built on
# first use - and a test may hand the facade a stand-in, so each slot is asked
# only if it holds something that can answer.
sub _backend_reads {
	my $self = shift;

	my %reads;
	foreach my $slot (sort keys %_BACKEND_NAMES) {
		my $backend = $self->{$slot} or next;
		next unless Scalar::Util::blessed($backend) && $backend->can('reads');
		$reads{$_BACKEND_NAMES{$slot}} = $backend->reads() // 0;
	}

	return \%reads;
}

=head2 clear_miss_cache

    Geo::Coder::Free->clear_miss_cache();
    $geo->clear_miss_cache();
    Geo::Coder::Free->clear_miss_cache('OpenAddresses');

Forgets the lookups that found nothing.  Each backend remembers a miss in
L<Geo::Coder::Free::MissCache>, one process-level cache that every backend and
every instance shares, so an address that is not in the data is searched for
once per process rather than once per call.  Entries expire after an hour; this
method empties them now, for a caller that has rebuilt a database or downloaded
a data set while the process is running.

With a scope - C<OpenAddresses>, C<Local> or C<MaxMind> - only that backend's
entries go; C<OpenAddresses> covers every OpenAddresses directory this process
has opened.  Returns true.

=cut

sub clear_miss_cache {
	# The invocant is $_[0] and is not needed; anything after it is the scope.
	Geo::Coder::Free::MissCache->clear(@_ > 1 ? $_[1] : undef);

	return 1;
}

=head2 provenance

    my ($dist, $backend, $confidence, $accuracy) = $geocoder->provenance($point);

or, in scalar context, the same four as a hashref:

    my $provenance = $geocoder->provenance($point);
    print $provenance->{'backend'};

Where a result came from and how good it is, so that a caller does not have to
reach for the hash keys itself:

=over 4

=item * C<$dist> - the distribution that produced the result: the C<geocoder>
key, C<Geo::Coder::Free> for a result from this distribution, or the wrapper
that passed it on, such as C<Geo::Coder::List>.

=item * C<$backend> - which backend answered, in a short vocabulary: C<Local>,
C<MaxMind>, C<OpenAddresses> or C<GeoNames>.  This is the C<database> key with
the distribution's prefix removed, so that the two spellings the backends use -
C<Geo::Coder::Free::Local> from C<Local>, and C<MaxMind> from C<MaxMind> - speak
the same vocabulary here.  B<The C<database> key itself is unchanged>, for the
consumers that already match on it.

=item * C<$confidence> - how good the match was, 0.0 to 1.0, where 1.0 is exact.

=item * C<$accuracy> - how precise the coordinate is: C<address>, C<street>,
C<postcode>, C<locality>, C<city>, C<region> or C<country>.

=back

Returns an empty list - and an empty hashref in scalar context - when handed
something that is not a result.  A key a result does not carry comes back
C<undef> rather than being guessed at, because a plain hash from another
geocoder has no provenance to report.

=cut

sub provenance {
	my ($self, $point) = @_;

	return wantarray ? () : {} unless defined($point) && ref($point)
		&& ((Scalar::Util::reftype($point) || '') eq 'HASH');

	my $dist    = $point->{'geocoder'};
	my $backend = $point->{'database'};
	$backend =~ s/^Geo::Coder::Free::// if defined($backend);

	my %provenance = (
		dist       => $dist,
		backend    => $backend,
		confidence => $point->{'confidence'},
		accuracy   => $point->{'accuracy'},
	);

	return wantarray ? @provenance{qw(dist backend confidence accuracy)} : \%provenance;
}

=head2 reverse_geocode

=head3 SYNOPSIS

    my $loc = $geo->reverse_geocode(latlng => '51.3341,-1.4159');

=head3 DESCRIPTION

Translates a latitude/longitude pair back to a place name.
B<Partially implemented>: the MaxMind backend does not return meaningful results.
OpenAddresses is attempted first when available.

=head3 API SPECIFICATION

=head4 input

    # Input schema (Params::Validate::Strict) — latlng required
    latlng => { type => 'scalar' }  # "$lat,$long" comma-separated decimal degrees
    # NOTE: separate lat/lon/long keys are NOT supported at the Geo::Coder::Free
    # (facade) level.  When no OpenAddresses backend is configured, passing
    # lat/lon/long instead of latlng will croak "not yet supported".
    # To use separate coordinates call Geo::Coder::Free::Local::reverse_geocode.

=head4 output

    # Output schema (Return::Set)
    { type => 'object', isa => 'Geo::Location::Point', optional => 1 }

=cut

sub reverse_geocode {
	my $self = shift;

	if (!ref($self)) {
		if (scalar @_) {
			return __PACKAGE__->new()->reverse_geocode(@_);
		} elsif (!defined($self)) {
			Carp::croak(_i18n('usage_reverse', __PACKAGE__));
		} elsif ($self eq __PACKAGE__) {
			Carp::croak(_i18n('usage_reverse', $self));
		}
		return __PACKAGE__->new()->reverse_geocode($self);
	} elsif (ref($self) eq 'HASH') {
		return __PACKAGE__->new()->reverse_geocode($self);
	}

	my %params = _normalize_args(_i18n('usage_reverse', __PACKAGE__), 'latlng', @_);

	# M8 (tautology — same pattern fixed in geocode): both arms are identical;
	# context propagates implicitly through return.
	if ($self->{'openaddr'}) {
		return $self->{'openaddr'}->reverse_geocode(\%params);
	}
	if ($params{'latlng'}) {
		return $self->{'maxmind'}->reverse_geocode(\%params);
	}

	Carp::croak(_i18n('reverse_unsupported'));
}

=head2 ua

Does nothing.  Present for drop-in compatibility with other Geo::Coder::* modules.

=cut

sub ua { }

=head2 run

Command-line entry point.  Use as:

    perl lib/Geo/Coder/Free.pm 1600 Pennsylvania Avenue NW, Washington DC

=cut

__PACKAGE__->run(@ARGV) unless caller();

sub run {
	require Data::Dumper;

	my $class    = shift;
	my $location = join ' ', @_;

	my @rc = $ENV{'OPENADDR_HOME'}
		? $class->new(openaddr => $ENV{'OPENADDR_HOME'})->geocode($location)
		: $class->new()->geocode($location);

	Carp::croak(_i18n('geocoding_failed', $0)) unless @rc;

	print Data::Dumper->new([\@rc])->Dump();
}

# -----------------------------------------------------------------------
# Private helpers
# -----------------------------------------------------------------------

# The rule geocode() rejects on - whether a string could be a location at all -
# is defined in Geo::Location::Predicate, and imported above.  It is not
# written out here as well: the backends ask the same question of what a caller
# hands them, so one definition is what keeps valid_location(), the guard that
# croaks and the backends from disagreeing about it.

# Purpose:  Return a formatted message string from the message table.
#           Falls back to the raw key so call sites never die on a missing key.
# Entry:    $key — message key; @args — sprintf format arguments.
# Exit:     Formatted string.
sub _i18n {
	my ($key, @args) = @_;
	my $fmt = $_MESSAGES{$key} // $key;
	return @args ? sprintf($fmt, @args) : $fmt;
}

# Purpose:  Normalise the four calling conventions accepted by geocode/reverse_geocode:
#             hashref, even-length key-val list, odd-length list, single bare string.
# Entry:    $error_msg — message to croak if a non-hash reference is passed.
#           $bare_key  — hash key to assign to a single bare string argument
#                        ('location' for geocode, 'latlng' for reverse_geocode).
#           @args — raw @_ after $self has been shifted.
# Exit:     Flat key-value %params hash.
# Side Effects: None; croaks on unsupported reference argument.
sub _normalize_args {
	my ($error_msg, $bare_key, @args) = @_;
	return %{$args[0]}              if ref($args[0]) eq 'HASH';
	Carp::croak($error_msg)         if ref($args[0]);
	return @args                    if @args && @args % 2 == 0;
	return ($bare_key => $args[0])  if @args == 1;
	# M7 (logic-gap closure): odd-count > 1 is not a valid calling convention.
	# The former code silently returned () here, discarding the trailing elements.
	# Fail fast instead of propagating a malformed argument list downstream.
	Carp::croak($error_msg)         if @args;
	return ();
}

# Purpose:  Try to geocode each candidate place string via the openaddr backend,
#           annotating every hit with location/text/confidence metadata and
#           memoising misses to avoid re-querying the same failing string.
# Entry:    $self       — geocoder instance with {openaddr} and {scantext_misses}.
#           $candidates — arrayref of place-name strings to probe.
#           $region     — optional ISO country code appended to each candidate.
#           $confidence — numeric confidence score assigned to all hits.
#           $scantext   — original free text (stored inside each result object).
# Exit:     Arrayref of Geo::Location::Point objects; empty arrayref on no hits.
# Side Effects: Populates $self->{scantext_misses} for every non-matching place.
sub _resolve_scan_candidates {
	my ($self, $candidates, $region, $confidence, $scantext) = @_;
	my @results;
	for my $place (@{$candidates}) {
		my $location = $region ? "$place, $region" : $place;
		next if $self->{'scantext_misses'}{$location};
		my @res = grep { defined } $self->{'openaddr'}->geocode($location);
		if (@res) {
			for my $entry (@res) {
				$entry->{'location'}   = $location;
				$entry->{'text'}       = $scantext;
				$entry->{'confidence'} = $confidence;
			}
			push @results, @res;
		} else {
			$self->{'scantext_misses'}{$location} = 1;
		}
	}
	return \@results;
}

# Purpose:  Slide a window of $n words across $text and return all comma-joined
#           n-grams, excluding pure-numeric tokens and stopwords.  A token of
#           digits only is not a word of a place name, which is the question
#           Geo::Location::Predicate::_valid_location() answers, so it is asked
#           there rather than spelled out here (t/location-rule.t fails if the
#           rule is written out again).
#           Replaces the former _find_word_triplets ($n=3) and
#           _find_word_duplets ($n=2) which were identical except for window size
#           and the duplets version was missing the lc() normalisation on stopwords.
# Entry:    $text — raw string; $n — window size; $stop — stopword hashref.
# Exit:     Flat list of n-gram strings.
sub _find_word_ngrams {
	my ($text, $n, $stop) = @_;
	$text =~ s/,+/ /g;
	$text =~ s/\s+/ /g;
	$text =~ s/^\s+|\s+$//g;
	my @words = grep { !$stop->{lc $_} && _valid_location($_) } split /\s+/, $text;
	my @ngrams;
	for my $i (0 .. $#words - ($n - 1)) {
		push @ngrams, join ', ', @words[$i .. $i + $n - 1];
	}
	return @ngrams;
}

# Purpose:  Extract structured US street addresses from free text.
# Entry:    $text — arbitrary string.
# Exit:     List of full address strings matching the US pattern.
sub _find_us_addresses {
	my $text = shift;
	my @addresses;
	my $re = qr/
		\b \d{1,5} \s+                                      # house number
		(?:[A-Za-z0-9]+(?:\s+[A-Za-z0-9]+){0,6}) \s+       # street name: 1–7 words (bounded)
		(?:Avenue|Ave\.?|Boulevard|Blvd\.?|Road|Rd\.?|Lane|Ln\.?|Drive|Dr\.?|Street|St\.?)
		(?:\s+[A-Za-z]{2})? ,\s*
		(?:[A-Za-z]+(?:\s+[A-Za-z]+){0,3}) ,\s*            # city: 1–4 words
		[A-Z]{2} \s* (?:\d{5}(?:-\d{4})?)? \b              # state + optional zip
	/x;
	while ($text =~ /$re/g) {
		push @addresses, $&;
	}
	return @addresses;
}

# Purpose:  Extract British-style addresses from free text.
# Entry:    $text — arbitrary string.
# Exit:     List of trimmed address strings.
sub _find_gb_addresses {
	my $text = shift;
	my @addresses;
	# ReDoS fix: the former pattern used \s*,?\s* between all parts and
	# [A-Za-z\s'-]+ groups — with commas optional, the engine must try all
	# possible splits of a long string among 5 overlapping space-containing
	# groups, causing exponential backtracking.  Making commas mandatory
	# eliminates the ambiguity entirely: UK postal addresses always have commas.
	# All groups are non-capturing (only $& is used).
	my $re = qr/
		\b
		(?:\d{1,5} | [\w'-]+)                   # house number or single-word name
		\s+
		(?:[\w'-]+(?:\s+[\w'-]+){0,5})           # street name (up to 6 words)
		\s*,\s*                                   # COMMA REQUIRED — kills the ambiguity
		(?:[\w'-]+(?:\s+[\w'-]+){0,3})           # town (up to 4 words)
		\s*,\s*                                   # COMMA REQUIRED
		(?:[\w'-]+(?:\s+[\w'-]+){0,3})           # county (up to 4 words)
		\s*,\s*                                   # COMMA REQUIRED
		(?:[\w'-]+(?:\s+[\w'-]+){0,2})           # country (up to 3 words)
		\b
	/x;
	while ($text =~ /$re/g) {
		(my $addr = $&) =~ s/[,\s]+$//;
		push @addresses, $addr;
	}
	return @addresses;
}

# Purpose:  Extract Canadian street addresses from free text.
# Entry:    $text — arbitrary string.
# Exit:     List of full address strings matching the Canadian pattern.
sub _find_ca_addresses {
	my $text = shift;
	my @addresses;
	my $re = qr/
		\b \d{1,5} \s+                                         # house number
		(?:[A-Za-z0-9]+(?:\s+[A-Za-z0-9]+){0,6}) \s+          # street name: 1–7 words (bounded)
		(?:Avenue|Ave\.?|Boulevard|Blvd\.?|Road|Rd\.?|Lane|Ln\.?|Drive|Dr\.?|Street|St\.?|Circle|Crescent|Cres\.?)
		\s*,\s*
		(?:[A-Za-z]+(?:\s+[A-Za-z]+){0,3}) \s*,\s*            # city: 1–4 words
		[A-Z]{2} \s*,?\s*
		(?:[A-Z]\d[A-Z]\s?\d[A-Z]\d)? \b                      # optional postal code
	/x;
	while ($text =~ /$re/g) {
		push @addresses, $&;
	}
	return @addresses;
}

# _normalize and _abbreviate are imported from Geo::Coder::Free::Utils.

=head1 GETTING STARTED

To download, import and set up the local database:
before running C<make>, but after running C<perl Makefile.PL>, follow these instructions.

Optionally set C<OPENADDR_HOME> to point to an empty directory and download the data from
L<http://results.openaddresses.io> into that directory; and
optionally set C<WHOSONFIRST_HOME> to point to an empty directory and download the data using
L<https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-clone>.
The script C<bin/download_databases> (see below) will do those for you.
You do not need to download the MaxMind data — that is downloaded automatically.

You will need to create the database used by C<Geo::Coder::Free>.

Install L<App::csv2sqlite> and L<https://github.com/nigelhorne/NJH-Snippets>.
Run C<bin/create_sqlite> — this converts the MaxMind "cities" database from CSV to SQLite.

To use with MariaDB, set C<MARIADB_SERVER="$hostname;$port"> and
C<MARIADB_USER="$user;$password"> (TODO: username/password should be asked for interactively).
The code will use a database called C<geo_code_free>, which will be dropped and recreated if it exists.
C<$user> needs only DROP, CREATE, SELECT, INSERT, and INDEX privileges on that database.

The following optional steps download and install large databases.
This will take a long time and use a lot of disc space.

=over 4

=item 1

C<mkdir $WHOSONFIRST_HOME; cd $WHOSONFIRST_HOME> then run C<wof-clone> from NJH-Snippets.

This can take a long time because it contains many nested directories, which filesystem drivers
can be slow to navigate (particularly on EXT4 and ZFS).

=item 2

Install L<https://github.com/dr5hn/countries-states-cities-database.git> into C<$DR5HN_HOME>.
This data covers cities only, so it is not used when C<OSM_HOME> is set (OSM is far more
comprehensive).  Only Australia, Canada, and the US are imported, as the UK data is difficult
to parse.

=item 3

Run C<bin/download_databases> — this downloads the Who's On First, OpenAddr, OpenStreetMap,
and dr5hn databases.
OpenStreetMap now uses PBF files, so you will need C<apt install osmium-tool> first.
Check the values of C<OSM_HOME>, C<OPENADDR_HOME>, C<DR5HN_HOME> and C<WHOSONFIRST_HOME>
within that script and adjust them for your setup.
The C<Makefile.PL> file downloads the MaxMind database automatically, as it is not optional.

=item 4

Run C<bin/create_db> — this creates the database used by C<Geo::Coder::Free> from the data you
have just downloaded.
The database is called C<openaddr.sql> for historical reasons (before Who's On First was added);
it actually contains data from all sources above.

=back

Now you are ready to run C<make>.
See the comment at the start of C<createdatabase.PL> for further details.

=head1 MORE INFORMATION

I have written several Perl genealogy programs including
L<gedcom|https://github.com/nigelhorne/gedcom> and
L<ged2site|https://github.com/nigelhorne/ged2site>.
One of the things these do is check the validity of a family tree, including verifying place-names.
Of course places do change names and spelling becomes more consistent over the years, but the vast
majority remain the same — enough to make computerised verification worthwhile.

=head1 BUGS

Some lookups fail.  Please file a bug report at
L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Free>.

The MaxMind data contains cities only.
The OpenAddresses data does not cover the whole globe.
C<London, England> cannot be parsed yet.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Geo-Coder-Free/coverage/>

=back

L<Geo::Coder::Free::Local>, L<Geo::Coder::Free::MaxMind>,
L<Geo::Coder::Free::OpenAddresses>,
L<https://openaddresses.io/>, L<https://www.maxmind.com/>,
L<https://www.geonames.org/>, L<https://www.whosonfirst.org/>.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 FORMAL SPECIFICATION

=head2 new

    GeoCoderFreeState ::= ⟨⟨ maxmind     : MaxMind_Geocoder;
                              openaddr    : OpenAddr_Geocoder | undef;
                              alternatives: Map[STRING → STRING];
                              cache       : Cache | undef ⟩⟩

    Init : Params → GeoCoderFreeState
    ∀ p : Params •
      let oa_path == p.openaddr ∨ env.OPENADDR_HOME •
      GeoCoderFreeState.openaddr = if oa_path ≠ ∅ then OpenAddresses(oa_path) else undef fi

=head2 valid_location

    ValidLocation : Any → BOOLEAN
    ∀ x : Any •
      ValidLocation(x) = (x ≠ ∅ ∧ ¬ ref(x) ∧ x ≠ "" ∧ x ∋ non-digit)

=head2 geocode

    ErrorMode ::= "croak" | "undef"

    Geocode : Address × Region? × ErrorMode? → Point?
    ∀ addr : Address; r : Region?; e : ErrorMode? •
      let mode == e ∨ "croak" •
      let backends == (openaddr ≠ undef ⟹ [OpenAddresses, Local, MaxMind])
                    ∧ (openaddr = undef ⟹ [MaxMind]) •
      ¬ ValidLocation(addr) ⟹ (mode = "undef" ⟹ result = ∅ | mode = "croak" ⟹ ⊥)
      ∧ ValidLocation(addr) ⟹
      result = first { defined } map { b.geocode(addr, r) } backends

=head2 provenance

    Provenance : Point? → (DISTRIBUTION?, BACKEND?, CONFIDENCE?, ACCURACY?)
    ∀ p : Point? •
      Provenance(p) = if p ≠ ∅ ∧ is_a_result(p)
                      then ⟨⟨ p.geocoder,
                              strip("Geo::Coder::Free::", p.database),
                              p.confidence,
                              p.accuracy ⟩⟩
                      else ∅ fi

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.  Licensed under GPL2 for personal use.

This product uses GeoLite2 data created by MaxMind,
available from L<https://www.maxmind.com/>.

=cut

1;

# Common mappings for looser lookups.  A future version should load these from
# an external, user-editable config file.  See also Local.pm's %alternatives.
__DATA__
St Lawrence, Thanet, Kent = Ramsgate, Kent
St Peters, Thanet, Kent = Broadstairs, Kent
Minster, Thanet, Kent = Ramsgate, Kent
Tyne and Wear = Borough of North Tyneside
