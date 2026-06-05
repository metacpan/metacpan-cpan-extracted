[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-List.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-List)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/naayd09612e10llw/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-list/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/Geo-Coder-List/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Geo-Coder-List?branch=master)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-List.svg)](https://metacpan.org/release/Geo-Coder-List)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/nigelhorne/geo-coder-list/test.yml?branch=master)
![Perl Version](https://img.shields.io/badge/perl-5.10.1+-blue)

# NAME

Geo::Coder::List - Call many Geo-Coders

# VERSION

Version 0.37

# SYNOPSIS

[Geo::Coder::All](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AAll) and [Geo::Coder::Many](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AMany) are great modules but neither
quite does what I want.

`Geo::Coder::List` aggregates multiple geocoding services into a single,
unified interface.  It chains and prioritizes backends based on regex routing
and per-geocoder query limits, caches results at two levels (L1 in-memory
always; optional L2 via CHI or a plain HASH), and normalizes every provider's
idiosyncratic response into the common structure expected by
[HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3) and [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM):

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

# SUBROUTINES/METHODS

## new

Creates a new `Geo::Coder::List` object.  When called on an existing object
it returns a clone of that object merged with the supplied arguments.

The constructor reads configuration from environment variables via
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure); for example, setting
`GEO__CODER__LIST__carp_on_warn=1` causes warnings to use [Carp](https://metacpan.org/pod/Carp).

    use Geo::Coder::List;
    use CHI;

    # With an optional L2 cache (any CHI driver works)
    my $geocoder = Geo::Coder::List->new(
        cache => CHI->new(driver => 'Memory', global => 1),
        debug => 0,
    );

    # Clone an existing object with a higher debug level
    my $verbose = $geocoder->new(debug => 2);

### API SPECIFICATION

#### INPUT

    # Params::Validate::Strict schema
    {
        cache => {
            type     => [ 'hashref', 'object' ],        # OBJECT must implement get($key) and set($key, $value, $ttl)
            optional => 1,
        },
        debug => {
            type     => 'boolean',
            optional => 1,
            default  => 0,
        },
        # Any additional key is forwarded to Object::Configure
    }

#### OUTPUT

    # Return::Set schema
    OBJECT blessed into Geo::Coder::List

## push

Appends a geocoder to the chain.  Geocoders are tried in the order they
were pushed.  Returns `$self` so calls can be chained.

A plain geocoder object is tried for every location.  A hashref with
`regex`, `geocoder`, and optional `limit` keys restricts the geocoder to
locations matching the regex and caps total queries at `limit`.

    my $list = Geo::Coder::List->new()
        ->push({ regex => qr/USA$/, geocoder => Geo::Coder::CA->new(), limit => 100 })
        ->push(Geo::Coder::OSM->new());

### API SPECIFICATION

#### INPUT

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

#### OUTPUT

    # Return::Set schema
    OBJECT blessed into Geo::Coder::List   # $self, for chaining

## geocode

Resolves a location string to geographic coordinates by trying each geocoder
in turn.  The first successful result is returned and cached.

In scalar context returns a single hashref (or `undef` on failure).
In list context returns all results from the winning geocoder.

The `geocoder` field of the returned hashref holds the geocoder object that
supplied the result; it is set to the string `'cache'` when the result was
served from cache.

See [Geo::Coder::GooglePlaces::V3](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces%3A%3AV3) for the canonical result structure.

    my $result = $list->geocode(location => 'Paris, France');
    if($result) {
        printf "lat=%.4f lng=%.4f via %s\n",
            $result->{geometry}{location}{lat},
            $result->{geometry}{location}{lng},
            ref($result->{geocoder}) || $result->{geocoder};
    }

    # List context returns all candidates from the winning geocoder
    my @results = $list->geocode('London, UK');

### API SPECIFICATION

#### INPUT

    # Params::Validate::Strict schema
    {
        location => {
            type     => SCALAR,
            required => 1,
            # Must contain at least one non-digit character
        },
    }

#### OUTPUT

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

## ua

Sets the [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) (or compatible) object on every geocoder in the
chain.  Useful when you need proxy support or custom timeouts across all
backends at once.

There is intentionally no read accessor since that would be meaningless
(each geocoder could have a different UA).

    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $list->ua($ua);

### API SPECIFICATION

#### INPUT

    # Params::Validate::Strict schema
    {
        ua => {
            type     => OBJECT,
            optional => 1,
        },
    }

#### OUTPUT

    # Return::Set schema
    OBJECT   # the same $ua that was passed in

## reverse\_geocode

Converts a latitude/longitude pair into a human-readable address string.

In scalar context returns a single address string (or `undef`).
In list context returns all address strings from the winning geocoder.

    my $address = $list->reverse_geocode(latlng => '51.5074,-0.1278');
    print "Address: $address\n" if $address;

    my @addresses = $list->reverse_geocode(latlng => '51.5074,-0.1278');

### API SPECIFICATION

#### INPUT

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

#### OUTPUT

    # Return::Set schema (scalar context)
    SCALAR (address string) | undef

    # Return::Set schema (list context)
    ARRAY of SCALAR

## log

Returns an arrayref of log entries accumulated since the last `flush()`.
Each entry is a hashref with the keys: `line`, `location`, `timetaken`,
`geocoder`, `wantarray`, and either `result` or `error`.

    foreach my $entry (@{ $list->log() }) {
        printf "%s: %.3fs via %s\n",
            $entry->{location},
            $entry->{timetaken},
            $entry->{geocoder};
    }

### API SPECIFICATION

#### INPUT

    # No parameters accepted

#### OUTPUT

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

## flush

Clears all accumulated log entries and returns `$self` to allow chaining.

    $list->geocode('Paris, France');
    my $entries = $list->log();
    $list->flush()->geocode('London, UK');   # chained

### API SPECIFICATION

#### INPUT

    # No parameters accepted

#### OUTPUT

    # Return::Set schema
    OBJECT blessed into Geo::Coder::List   # $self, for chaining

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report any bugs or feature requests to
`bug-geo-coder-list at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List).

Known limitations:

- `reverse_geocode()` does not yet support [Geo::Location::Point](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APoint) objects.
- When `Geo::GeoNames` returns multiple candidates, only the first
element of each sub-array is considered.

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Geo-Coder-List/coverage/)
- [Geo::Coder::All](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AAll)
- [Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces)
- [Geo::Coder::Many](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AMany)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Readonly](https://metacpan.org/pod/Readonly)

# SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc Geo::Coder::List

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-List](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-List)

- MetaCPAN

    [https://metacpan.org/release/Geo-Coder-List](https://metacpan.org/release/Geo-Coder-List)

## FORMAL SPECIFICATION

### new

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

### push

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

### geocode

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

### ua SPECIFICATION

    ua
    ──────────────────────────────────────────────────────
    ΞList_State
    ua?  : UserAgent
    ua!  : UserAgent
    ──────────────────────────────────────────────────────
    ∀ g : ran geocoders • g.ua = ua?
    ua!  = ua?

### reverse\_geocode

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

### log

    log
    ──────────────────────────────────────────────────────
    ΞList_State
    result! : seq LogEntry
    ──────────────────────────────────────────────────────
    result! = log

### flush

    flush
    ──────────────────────────────────────────────────────
    ΔList_State
    ──────────────────────────────────────────────────────
    log'       = ⟨⟩
    geocoders' = geocoders
    L1'        = L1

# LICENSE AND COPYRIGHT

Copyright 2016-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
