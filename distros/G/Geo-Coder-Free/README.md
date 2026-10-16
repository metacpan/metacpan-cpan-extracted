# NAME

Geo::Coder::Free - Geocoding using free, locally-hosted databases

# VERSION

Version 0.46

# SYNOPSIS

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

# DESCRIPTION

`Geo::Coder::Free` translates addresses into latitude/longitude coordinates
using local SQLite databases built from free data sources - MaxMind/GeoNames,
OpenAddresses, Who's On First, OpenStreetMap, and dr5hn's countries/states/cities
database.  It deliberately avoids paid or rate-limited online geocoding services.
The module is designed to be flexible, supporting both command-line and programmatic usage.
It also includes a sample CGI script for a web-based geocoding service.

Geocoding dispatch order depends on whether `OPENADDR_HOME` (or `openaddr`) is set:

**With OpenAddresses data:**

- 1. `Geo::Coder::Free::OpenAddresses` - requires `OPENADDR_HOME`
- 2. `Geo::Coder::Free::Local` - user-curated CSV entries (tried as fallback)
- 3. `Geo::Coder::Free::MaxMind` - bundled, always available

**Without OpenAddresses data:**

- 1. `Geo::Coder::Free::MaxMind` only - Local is not consulted.

The `cgi-bin` directory contains a simple DIY geo-coding website:

    cgi-bin/page.fcgi page=query q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA

The sample website is currently down while a new host is sought.
When it returns, you will be able to test it with:

    curl 'https://geocode.nigelhorne.com/cgi-bin/page.fcgi?page=query&q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA'

# LIMITATIONS

- `scantext` mode only finds locations in OpenAddresses; it falls back
silently when `OPENADDR_HOME` is not set (**FIXME**: should warn).
- The `__DATA__` alternatives table is hard-coded; it should live in a
user-editable config file.
- The address-regex scantext path misses birth-year sentences such as
`"She was born May 21, 1937 in Noblesville, IN."` because the regex requires
a preceding capital-letter word directly before the city.
- `reverse_geocode` is only partially implemented; the MaxMind path does
not return meaningful results.
- The `alternatives` map loop uses `each %{$alt}`, which retains its
iterator position across calls.  After a successful match and early `return`,
the next `geocode()` call on the same input starts iterating from the key
**after** the matched one, potentially missing the match entirely until `each`
wraps around.  Workaround: call `keys %{$alt}` once to reset the iterator
before iterating.

# METHODS

## new

### SYNOPSIS

    my $geo = Geo::Coder::Free->new();
    my $geo = Geo::Coder::Free->new(openaddr => '/data/openaddr');
    my $geo = Geo::Coder::Free->new(directory => '/data/maxmind');

### DESCRIPTION

Constructor.  Accepts a hash or hashref of options.  If called without
`openaddr`, the module checks `$ENV{OPENADDR_HOME}` before giving up.

If called on an existing object instance (`$clone = $geo->new()`), returns
a **shallow clone**.  All scalar fields are copied by value, but reference-type
fields (`alternatives`, `scantext_misses`, `maxmind`, `openaddr`) share the
same underlying object or hashref between the original and the clone.  Mutations
to those shared references are immediately visible in both objects.

### API SPECIFICATION

#### input

    # Input schema (Params::Validate::Strict)
    openaddr  => { type => 'scalar', optional => 1 }                          # path to OpenAddresses/WOF data dir
    directory => { type => 'scalar', optional => 1 }                          # path to MaxMind/GeoNames files
    cache     => { type => 'object', optional => 1, can => ['get', 'set'] }   # CHI-compatible cache object

#### output

    # Output schema (Return::Set)
    { type => 'object', isa => 'Geo::Coder::Free' }

### EXAMPLE

    use Geo::Coder::Free;

    # Minimal - uses only the bundled MaxMind data:
    my $geo = Geo::Coder::Free->new();

    # Full - also searches OpenAddresses/WOF:
    my $geo = Geo::Coder::Free->new(openaddr => $ENV{OPENADDR_HOME});

### MESSAGES

    use ->new() not ::new()   Called as a function; use arrow syntax.

## valid\_location

### SYNOPSIS

    if ($geo->valid_location($row->{'place'})) {
        push @found, $geo->geocode(location => $row->{'place'});
    }

### DESCRIPTION

Answers whether a string is something this module will even try to look up.
It is the public form of the rule `geocode()` applies before it touches a
backend, so a caller working down a spreadsheet column can skip a row whose
value is a bare number - or is empty - instead of catching the croak that
would otherwise kill the whole run.  That rule is defined once, in
[Geo::Coder::Free::Validate](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AValidate), and the backends apply it too: what
`valid_location()` refuses is refused wherever it is looked up.

Only that cheap syntactic test is answered.  A true result means the string is
not disqualified, **not** that a backend knows it: `'Ramsgate, Kent'` is valid
and may still find nothing, while `'0044'` is invalid and is never looked up.
The rule rejects a string of digits only, which is what a numeric column holds
when the wrong column has been read, so anything with a non-digit in it counts
as valid - `'3.14'` and `'-'` included.  `undef`, `''` and a reference are
not valid.

### API SPECIFICATION

#### input

    location => { type => 'scalar', optional => 1 }  # the string to test

#### output

    { type => 'boolean' }  # false for undef, '' and a digit-only string

### EXAMPLE

    my $geo = Geo::Coder::Free->new();

    $geo->valid_location('Ramsgate, Kent');   # true
    $geo->valid_location('0044');             # false - never a location
    $geo->valid_location('');                 # false
    $geo->valid_location(undef);              # false

Accepts the three calling conventions the rest of this module does:

    $geo->valid_location('0044');
    Geo::Coder::Free->valid_location('0044');
    Geo::Coder::Free::valid_location('0044');

## geocode

### SYNOPSIS

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

### DESCRIPTION

A location or a scantext that is not a location at all - a bare number, such as
the `0044` a numeric column holds - is refused before any backend is
touched.  `valid_location()` answers the same question, so a caller can filter
first; `on_error` chooses what happens when one gets through anyway:

- `'croak'` (the default) - `Carp::croak`, the behaviour every existing
caller already has.
- `'undef'` - return `undef`, so one bad row in a spreadsheet column is
skipped rather than ending the run.  It changes the answer for **only** the two
documented input errors below; an exception from a backend is still an
exception, and a malformed argument list still croaks.

The option is deliberately narrow, so a batch caller wants `valid_location()`
with it: that predicate answers false for `undef` and `''` as well, which are
the other two things an empty cell holds.  A call with neither a location nor a
scantext is a usage error rather than an input error - the same croak as calling
`geocode()` with no arguments - and stays a croak on either setting.

### API SPECIFICATION

#### input

    # Input schema (Params::Validate::Strict) - exactly one of location or scantext is required
    location     => { type => 'scalar',   optional => 1 }  # address string (exclusive with scantext)
    scantext     => { type => 'scalar',   optional => 1 }  # free text to scan for place names
    region       => { type => 'scalar',   optional => 1 }  # ISO 3166-1 alpha-2 country code hint
    ignore_words => { type => 'arrayref', optional => 1 }  # words to suppress during scantext scan
    on_error     => { type => 'scalar',   optional => 1 }  # 'croak' (default) or 'undef'

#### output

    # Output schema (Return::Set)
    # scalar context: { type => 'object',   isa => 'Geo::Location::Point', optional => 1 }
    # list context:   { type => 'arrayref', of  => { isa => 'Geo::Location::Point' } }

#### provenance

Every result carries `geocoder`, `database`, `confidence` and `accuracy`
(section 2.1 of `BI-Phase6-Dependency-Specs.md`): which distribution produced
it, which backend answered, how good the match was, and how precise the
coordinate is.  `provenance()` reads the four back.  `location` is set by every
path but the MaxMind cities one, and `text` only by a scantext lookup; `lat`,
`long` and `lng` come from the value object itself.

### MESSAGES

    Usage: ...::geocode(...)        No location or scantext argument given.
    invalid location to geocode()   location is purely numeric.
    invalid scantext to geocode()   scantext is purely numeric.
    on_error must be ...            on_error is neither 'croak' nor 'undef'.

### PSEUDOCODE

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

## provenance

    my ($dist, $backend, $confidence, $accuracy) = $geocoder->provenance($point);

or, in scalar context, the same four as a hashref:

    my $provenance = $geocoder->provenance($point);
    print $provenance->{'backend'};

Where a result came from and how good it is, so that a caller does not have to
reach for the hash keys itself (section 2.1 of `BI-Phase6-Dependency-Specs.md`):

- `$dist` - the distribution that produced the result: the `geocoder`
key, `Geo::Coder::Free` for a result from this distribution, or the wrapper
that passed it on, such as `Geo::Coder::List`.
- `$backend` - which backend answered, in a short vocabulary: `Local`,
`MaxMind`, `OpenAddresses` or `GeoNames`.  This is the `database` key with
the distribution's prefix removed, so that the two spellings the backends use -
`Geo::Coder::Free::Local` from `Local`, and `MaxMind` from `MaxMind` - speak
the same vocabulary here.  **The `database` key itself is unchanged**, for the
consumers that already match on it.
- `$confidence` - how good the match was, 0.0 to 1.0, where 1.0 is exact.
- `$accuracy` - how precise the coordinate is: `address`, `street`,
`postcode`, `locality`, `city`, `region` or `country`.

Returns an empty list - and an empty hashref in scalar context - when handed
something that is not a result.  A key a result does not carry comes back
`undef` rather than being guessed at, because a plain hash from another
geocoder has no provenance to report.

## reverse\_geocode

### SYNOPSIS

    my $loc = $geo->reverse_geocode(latlng => '51.3341,-1.4159');

### DESCRIPTION

Translates a latitude/longitude pair back to a place name.
**Partially implemented**: the MaxMind backend does not return meaningful results.
OpenAddresses is attempted first when available.

### API SPECIFICATION

#### input

    # Input schema (Params::Validate::Strict) — latlng required
    latlng => { type => 'scalar' }  # "$lat,$long" comma-separated decimal degrees
    # NOTE: separate lat/lon/long keys are NOT supported at the Geo::Coder::Free
    # (facade) level.  When no OpenAddresses backend is configured, passing
    # lat/lon/long instead of latlng will croak "not yet supported".
    # To use separate coordinates call Geo::Coder::Free::Local::reverse_geocode.

#### output

    # Output schema (Return::Set)
    { type => 'object', isa => 'Geo::Location::Point', optional => 1 }

## ua

Does nothing.  Present for drop-in compatibility with other Geo::Coder::\* modules.

## run

Command-line entry point.  Use as:

    perl lib/Geo/Coder/Free.pm 1600 Pennsylvania Avenue NW, Washington DC

# GETTING STARTED

To download, import and set up the local database:
before running `make`, but after running `perl Makefile.PL`, follow these instructions.

Optionally set `OPENADDR_HOME` to point to an empty directory and download the data from
[http://results.openaddresses.io](http://results.openaddresses.io) into that directory; and
optionally set `WHOSONFIRST_HOME` to point to an empty directory and download the data using
[https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-clone](https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-clone).
The script `bin/download_databases` (see below) will do those for you.
You do not need to download the MaxMind data — that is downloaded automatically.

You will need to create the database used by `Geo::Coder::Free`.

Install [App::csv2sqlite](https://metacpan.org/pod/App%3A%3Acsv2sqlite) and [https://github.com/nigelhorne/NJH-Snippets](https://github.com/nigelhorne/NJH-Snippets).
Run `bin/create_sqlite` — this converts the MaxMind "cities" database from CSV to SQLite.

To use with MariaDB, set `MARIADB_SERVER="$hostname;$port"` and
`MARIADB_USER="$user;$password"` (TODO: username/password should be asked for interactively).
The code will use a database called `geo_code_free`, which will be dropped and recreated if it exists.
`$user` needs only DROP, CREATE, SELECT, INSERT, and INDEX privileges on that database.

The following optional steps download and install large databases.
This will take a long time and use a lot of disc space.

1. `mkdir $WHOSONFIRST_HOME; cd $WHOSONFIRST_HOME` then run `wof-clone` from NJH-Snippets.

    This can take a long time because it contains many nested directories, which filesystem drivers
    can be slow to navigate (particularly on EXT4 and ZFS).

2. Install [https://github.com/dr5hn/countries-states-cities-database.git](https://github.com/dr5hn/countries-states-cities-database.git) into `$DR5HN_HOME`.
This data covers cities only, so it is not used when `OSM_HOME` is set (OSM is far more
comprehensive).  Only Australia, Canada, and the US are imported, as the UK data is difficult
to parse.
3. Run `bin/download_databases` — this downloads the Who's On First, OpenAddr, OpenStreetMap,
and dr5hn databases.
OpenStreetMap now uses PBF files, so you will need `apt install osmium-tool` first.
Check the values of `OSM_HOME`, `OPENADDR_HOME`, `DR5HN_HOME` and `WHOSONFIRST_HOME`
within that script and adjust them for your setup.
The `Makefile.PL` file downloads the MaxMind database automatically, as it is not optional.
4. Run `bin/create_db` — this creates the database used by `Geo::Coder::Free` from the data you
have just downloaded.
The database is called `openaddr.sql` for historical reasons (before Who's On First was added);
it actually contains data from all sources above.

Now you are ready to run `make`.
See the comment at the start of `createdatabase.PL` for further details.

# MORE INFORMATION

I have written several Perl genealogy programs including
[gedcom](https://github.com/nigelhorne/gedcom) and
[ged2site](https://github.com/nigelhorne/ged2site).
One of the things these do is check the validity of a family tree, including verifying place-names.
Of course places do change names and spelling becomes more consistent over the years, but the vast
majority remain the same — enough to make computerised verification worthwhile.

# BUGS

Some lookups fail.  Please file a bug report at
[https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Free](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Free).

The MaxMind data contains cities only.
The OpenAddresses data does not cover the whole globe.
`London, England` cannot be parsed yet.

# SEE ALSO

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Geo-Coder-Free/coverage/)

[Geo::Coder::Free::Local](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3ALocal), [Geo::Coder::Free::MaxMind](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AMaxMind),
[Geo::Coder::Free::OpenAddresses](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AOpenAddresses),
[https://openaddresses.io/](https://openaddresses.io/), [https://www.maxmind.com/](https://www.maxmind.com/),
[https://www.geonames.org/](https://www.geonames.org/), [https://www.whosonfirst.org/](https://www.whosonfirst.org/).

# AUTHOR

Nigel Horne `<njh@nigelhorne.com>`

# FORMAL SPECIFICATION

## new

    GeoCoderFreeState ::= ⟨⟨ maxmind     : MaxMind_Geocoder;
                              openaddr    : OpenAddr_Geocoder | undef;
                              alternatives: Map[STRING → STRING];
                              cache       : Cache | undef ⟩⟩

    Init : Params → GeoCoderFreeState
    ∀ p : Params •
      let oa_path == p.openaddr ∨ env.OPENADDR_HOME •
      GeoCoderFreeState.openaddr = if oa_path ≠ ∅ then OpenAddresses(oa_path) else undef fi

## valid\_location

    ValidLocation : Any → BOOLEAN
    ∀ x : Any •
      ValidLocation(x) = (x ≠ ∅ ∧ ¬ ref(x) ∧ x ≠ "" ∧ x ∋ non-digit)

## geocode

    ErrorMode ::= "croak" | "undef"

    Geocode : Address × Region? × ErrorMode? → Point?
    ∀ addr : Address; r : Region?; e : ErrorMode? •
      let mode == e ∨ "croak" •
      let backends == (openaddr ≠ undef ⟹ [OpenAddresses, Local, MaxMind])
                    ∧ (openaddr = undef ⟹ [MaxMind]) •
      ¬ ValidLocation(addr) ⟹ (mode = "undef" ⟹ result = ∅ | mode = "croak" ⟹ ⊥)
      ∧ ValidLocation(addr) ⟹
      result = first { defined } map { b.geocode(addr, r) } backends

## provenance

    Provenance : Point? → (DISTRIBUTION?, BACKEND?, CONFIDENCE?, ACCURACY?)
    ∀ p : Point? •
      Provenance(p) = if p ≠ ∅ ∧ is_a_result(p)
                      then ⟨⟨ p.geocoder,
                              strip("Geo::Coder::Free::", p.database),
                              p.confidence,
                              p.accuracy ⟩⟩
                      else ∅ fi

# LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.  Licensed under GPL2 for personal use.

This product uses GeoLite2 data created by MaxMind,
available from [https://www.maxmind.com/](https://www.maxmind.com/).
