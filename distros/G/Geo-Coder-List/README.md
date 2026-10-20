## Name

Geo::Coder::List - Call many Geo-Coders

## Version

Version 0.39

## Synopsis

```perl
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
```

## Description

[Geo::Coder::All](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AAll) and [Geo::Coder::Many](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AMany) are great modules but neither
quite does what I want.

A _geocoder_ turns the name of a place, such as `'Paris, France'`, into
a position on the Earth (a latitude and a longitude).  There are many
geocoding services.  Each one knows some places better than others, each
one has its own limits, and each one returns its answer in its own format.

`Geo::Coder::List` lets you use many geocoders as if they were one:

- **A chain.**
You add geocoders with `push()`.  When you ask for a place, the geocoders
are asked one at a time, in the order you added them.  The first one that
gives a usable answer wins, and the others are not asked.
- **Routing.**
A geocoder can be given a regular expression.  It is then asked only
about places whose names match it.
- **Limits.**
A geocoder can be given a limit: the number of questions it may answer.
When the limit is used up, the geocoder is skipped.
- **One answer format.**
Every answer is changed into the same structure, whichever service gave
it.  The structure is the one used by [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3) and
[HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM):

    ```
    $result->{geometry}{location}{lat}   # latitude
    $result->{geometry}{location}{lng}   # longitude
    $result->{lat}                       # the same latitude, for convenience
    $result->{lng}                       # the same longitude, for convenience
    $result->{lon}                       # the same longitude, another common name
    $result->{geocoder}                  # the geocoder object that answered,
                                         # or the string 'cache'
    ```

- **A cache in two levels.**
Level 1 (L1) is a hash inside the object.  It is always used, and it lasts
as long as the object.  Level 2 (L2) is optional.  It can be a plain hash
or any object with `get()` and `set()` methods, such as a [CHI](https://metacpan.org/pod/CHI) cache.
L2 can last longer than the object and can be shared between programs.
How long L2 keeps an answer depends on the answer:

    ```
    found                      1 month   (cache_hit_duration)
    found, but no latitude     1 day     (cache_part_duration)
    not found                  1 week    (cache_miss_duration)
    ```

    A place that was not found is remembered in L1 only, never in L2.

## Supported Answer Formats

Each geocoding service answers in its own format.  `geocode()` finds the
latitude and longitude in each of the formats below and copies them into
the common structure.  Any geocoder whose answers use one of these formats
works without extra code.  The provider's own fields are kept as well.

```
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
```

Notice that Mapbox and GeoApify give the longitude **first**.

Some services need special handling, which is done for you:

- **Geo::Location::Point.**
A geocoder may answer with a [Geo::Location::Point](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APoint) object.  Its
`geometry` is filled in from its own `lat` and `lng` (or `lon`).
- **postcodes.io.**
Its `local_type` field is copied to `type`, with the first letter made
lower case.
- **geocoder.xyz.**
Its `standard.countryname` field is copied to `address.country`.
- **GeoNames.**
[Geo::GeoNames](https://metacpan.org/pod/Geo%3A%3AGeoNames) is called with the place name alone, not with
`location => ...`.  If it has no `username`, it fails with
`lost username`, which is logged, and the next geocoder is asked.
GeoNames puts its answers in arrays; every answer in them is considered.
- **US Census Bureau.**
An answer with no `addressMatches` means "not found", and the next
geocoder is asked.
- **GeoApify.**
An answer with an empty `features` list means "not found", and the next
geocoder is asked.
- **Errors.**
An answer with a top-level `error` key is treated as a refusal, not as a
place.  The error is logged, and the next geocoder is asked.

Every answer that went through this process also has a `debug` key.  It
holds the line number, in this module, of the code that read the answer.
It is there to help when a new format is not read correctly.

## Subroutines/Methods

### New

Creates a new `Geo::Coder::List` object with no geocoders in it.

Settings can also come from the environment, through
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).  The variable name is `GEO__CODER__LIST__` followed
by the setting name.  For example, `GEO__CODER__LIST__carp_on_warn=1`
makes warnings go through [Carp](https://metacpan.org/pod/Carp), and
`GEO__CODER__LIST__cache_hit_duration='7 days'` changes how long a found
place stays in L2.

When you call `new()` on an object that already exists, you get a
_clone_: a new object with the same settings and the same geocoders,
merged with any arguments you give.  The clone has its own list of
geocoders and its own limits, and it starts with an empty log.  The clone
**shares** the L1 and L2 caches with the original.

```perl
use Geo::Coder::List;
use CHI;

# With an L2 cache
my $geocoder = Geo::Coder::List->new(
    cache => CHI->new(driver => 'Memory', global => 1),
);

# A clone of it that prints what it is doing
my $verbose = $geocoder->new(debug => 1);
```

Arguments can be given as a list of pairs or as one hash reference.

- `cache` - Optional.  The L2 cache: a hash reference, or an object
with `get($key)` and `set($key, $value, $ttl)` methods.
- `debug` - Optional.  `0` (the default) prints nothing, `1`
prints what is tried, `2` also prints every answer in full.
- `cache_hit_duration`, `cache_part_duration`,
`cache_miss_duration` - Optional.  How long L2 keeps each kind of
answer, in any form your L2 cache understands, such as `'1 week'`.
- `geocoders` - Optional.  An array reference of geocoders, as if
each had been given to `push()`.
- `logger` - Optional.  Where warnings and errors go.  See
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).
- `carp_on_warn` - Optional.  When true, warnings go through
[Carp](https://metacpan.org/pod/Carp).

If `new` is called as a function, `Geo::Coder::List::new()`, with no
arguments, it still returns an object.  Called as a function with
arguments, it warns and returns `undef`.

#### Api Specification

##### Input

```perl
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
```

##### Output

```perl
{
    type => 'object',
    isa  => 'Geo::Coder::List',
}

# undef only when called as Geo::Coder::List::new() with arguments
```

### Push

Adds one geocoder to the end of the chain.  Geocoders are asked in the
order in which they were added.

`push` returns the object itself, so you can add several geocoders in
one statement.

There are two ways to add a geocoder:

- **A geocoder object.**
It is asked about every place.
- **A hash reference**, with these keys:
    - `geocoder` - Required.  The geocoder object.
    - `regex` - Optional.  A regular expression, made with `qr//`.
    The geocoder is asked only about places whose names match it.
    - `limit` - Optional.  A whole number.  The geocoder answers at
    most this many questions.  Each question it is asked makes the number one
    smaller.  When the number reaches `0`, the geocoder is skipped.  A place
    that does not match `regex` does not use up the limit.

```perl
my $list = Geo::Coder::List->new()
    ->push({ regex => qr/USA$/, geocoder => Geo::Coder::US::Census->new(), limit => 100 })
    ->push(Geo::Coder::OSM->new());
```

`push` croaks if `$geocoder` is missing or `undef`.

#### Api Specification

##### Input

```perl
{
    geocoder => { type => 'object|hashref', optional => 0 },
}

# A hashref geocoder holds the keys geocoder (an object, required),
# regex (a Regexp, optional) and limit (an integer, optional)
```

##### Output

```perl
{
    type => 'object',
    isa  => 'Geo::Coder::List',
}
```

### Geocode

Finds the position of a place from its name.

```perl
my $result = $list->geocode(location => 'Paris, France');
my $result = $list->geocode('Paris, France');            # the same
my $result = $list->geocode({ location => 'Paris, France' });  # the same

if($result) {
    printf "lat=%.4f lng=%.4f from %s\n",
        $result->{geometry}{location}{lat},
        $result->{geometry}{location}{lng},
        ref($result->{geocoder}) || $result->{geocoder};
}
```

These are the steps, in order:

- 1. If `location` is missing, `geocode` croaks.  If it is
`undef` or an empty string, `geocode` warns and returns nothing.
- 2. Runs of white space are made into one space, and HTML entities
are decoded: `'Caf&eacute;'` becomes `'Caf'` followed by the single
character e-acute.  A reference to a string is treated as the string.
- 3. The text is checked.  A reference is never a place.  When
[Geo::Location::Predicate](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APredicate) is installed, it decides what else is not a
place; for example, a string of only digits is not.  If the text is not a
place, `geocode` croaks.  The check is done after step 2, so
`'&#49;&#50;'` is refused as the digits `'12'`.
- 4. The cache is checked: first L1, then L2.  If the place is there,
the cached answer is returned, with `geocoder` set to `'cache'`.  If L1
remembers that the place was not found, nothing is returned and no
geocoder is asked.
- 5. Each geocoder in the chain is asked in turn.  A geocoder is
skipped if the place does not match its `regex`, or if its `limit` is
used up.  If a geocoder dies, the error is logged, a warning is given, and
the next geocoder is asked.
- 6. The first answer that has both a latitude and a longitude wins.
It is changed into the common structure (see ["DESCRIPTION"](#description)), stored in
the cache, and returned.
- 7. If no geocoder gives a usable answer, the place is remembered as
"not found" in L1, and nothing is returned.

**Scalar context** returns one hash reference, or `undef`.

**List context** returns every answer from the geocoder that won, or an
empty list.  This is useful when a name, such as `'Springfield'`, belongs
to many places.  Answers that the geocoder returned inside an array are
taken out of it, so the list never contains array references.  Answers
without a position may be in the list too; check `geometry` before you
use each one.

```perl
my @all = $list->geocode('Springfield, USA');
```

The `geocoder` key of an answer holds the geocoder object that gave it.
When the answer came from the cache, it holds the string `'cache'`.

#### Api Specification

##### Input

```perl
{
    location => { type => 'string', optional => 0, min => 1 },
}
```

##### Output

```perl
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
```

### Ua

Gives a user agent (the object that makes the web requests) to every
geocoder in the chain.  Use it to set a proxy or a time-out for all of
them at once.

```perl
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(timeout => 10);
$ua->env_proxy(1);
$list->ua($ua);
```

If `$ua` has both `clone()` and `agent()` methods, as
[LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) does, each geocoder is given its own copy.  The
`agent` string of each copy is set to the geocoder's class name and
version, such as `'Geo::Coder::OSM/0.03'`, so each service can see which
module is calling it.  Otherwise every geocoder is given `$ua` itself.

Add the geocoders before you call `ua`: geocoders added later do not get
the user agent.

There is no way to read the user agent back, because each geocoder may
have a different one.

If `$ua` is missing or false, nothing changes and nothing is returned.
`ua` croaks with `No geocoder found` if an entry in the chain has no
geocoder.

#### Api Specification

##### Input

```perl
{
    ua => { type => 'object', optional => 1 },
}
```

##### Output

```perl
{
    type => 'object',
    optional => 1,
}

# The same $ua that was passed in, or nothing when $ua is false
```

### Reverse\_Geocode

Finds the address of a position: the opposite of `geocode`.

```perl
my $address = $list->reverse_geocode(latlng => '51.5034,-0.1276');
my $address = $list->reverse_geocode('51.5034,-0.1276');    # the same
print "Address: $address\n" if defined($address);

my @addresses = $list->reverse_geocode(latlng => '51.5034,-0.1276');
```

`latlng` is the latitude, a comma, and the longitude, in that order.  It
must be two plain decimal numbers written with the digits `0` to `9`.
Spaces, tabs and a `+` or `-` sign are allowed.  Anything else, such as
`'51.5;-0.1'`, `'1e5,2'` or `'51.5'`, makes `reverse_geocode` croak
before any geocoder is asked.

The geocoders are asked in turn, as for `geocode`.  `limit` is honoured;
`regex` is not.  If a geocoder complains that it does not know the
`latlng` parameter, it is asked again with only `lat` and `lon`.  If a
geocoder dies for any other reason, a warning is given and the next
geocoder is asked.

**Scalar context** returns one address string, or `undef`.

**List context** returns every address from the first geocoder that has
any, or an empty list.

An address is taken from the first of these that the answer has:

- `display_name` (OpenStreetMap, and others that copy it)
- the fields of geocoder.ca: `stnumber`, `staddress`, `city` and
`prov` for Canada, giving for example
`'1 Sussex Dr, Ottawa, ON'`; or the `usa` fields for the United States,
giving for example `'1600 Pennsylvania Ave, Washington, DC, USA'`
- `features[0].properties.formatted` (GeoApify); only the first
feature is used

If a geocoder returns a plain string, the string is the address.

Addresses are cached under the `latlng` string, so asking again for the
same position does not ask any geocoder.

#### Api Specification

##### Input

```perl
{
    latlng => { type => 'string', optional => 0, matches => qr/^[ \t]*[-+]?(?:[0-9]*\.?[0-9]+|[0-9]+\.?[0-9]*)[ \t]*,[ \t]*[-+]?(?:[0-9]*\.?[0-9]+|[0-9]+\.?[0-9]*)[ \t]*$/ },
}
```

##### Output

```perl
{
    type => 'string',
    optional => 1,
}

# Scalar context: an address string, or undef when not found
# List context: a list of address strings, or an empty list
```

### Log

Returns the record of what has happened since the object was made, or
since the last `flush()`.  There is one entry for each question asked of
a geocoder, and one for each answer that `geocode()` serves from the
cache.  `reverse_geocode()` adds no entry when it answers from the
cache.

```perl
for my $entry (@{ $list->log() }) {
    printf "%s: %.3fs via %s\n",
        $entry->{location},
        $entry->{timetaken},
        $entry->{geocoder};
}
```

Each entry is a hash reference with these keys:

- `location` - the place name or `latlng` that was asked about
- `geocoder` - the class name of the geocoder, or `'cache'`
- `timetaken` - how long the geocoder took, in seconds
- `line` - the line of your program that made the call
- `wantarray` - true if the call was made in list context
- `result` - the answer, when there was one; the string
`'not found'` when the geocoder had none
- `error` - the error, when the geocoder died or returned an
error; this can be an exception object, not only a string

The returned array reference is the object's own record, not a copy.

#### Api Specification

##### Input

```
[]
```

##### Output

```perl
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
```

### Flush

Empties the log and returns the object itself, so that it can be chained.

```perl
$list->geocode('Paris, France');
my $entries = $list->log();
$list->flush()->geocode('London, UK');
```

`flush` does **not** empty the cache.

#### Api Specification

##### Input

```
[]
```

##### Output

```perl
{
    type => 'object',
    isa  => 'Geo::Coder::List',
}
```

## Common Pitfalls

- **Scalar context and list context give different answers.**

    `geocode()` and `reverse_geocode()` return one answer in scalar
    context and all answers in list context.  Perl decides the context from
    the code around the call, and some places give list context when you may
    not expect it:

    ```perl
    my %row = (name => $name, place => $list->geocode($name));  # list context!
    print 'Found: ', $list->geocode($name);                     # list context!
    return $list->geocode($name);                               # your caller decides
    ```

    When nothing is found, list context returns an _empty list_, so in the
    first example the keys and values of `%row` move out of step.  Use
    `scalar()` to be sure:

    ```perl
    my %row = (name => $name, place => scalar($list->geocode($name)));
    ```

- **`undef` means "not found" and also "bad empty input".**

    `geocode()` returns `undef` both when no geocoder knows the place and
    when `location` is `undef` or empty (it also warns in that case).  Other
    bad input, such as a reference or a string of digits, does not return
    `undef`: it croaks.  Wrap the call in `eval` when the text comes from
    outside your program.

- **"Not found" is remembered for the life of the object.**

    When no geocoder finds a place, L1 remembers that, and later calls for
    the same place return `undef` at once without asking any geocoder, even
    if a geocoder was only down for a moment.  `flush()` does not forget it,
    and nor does a clone, which shares L1.  Make a new object with
    `Geo::Coder::List->new()` to ask again.  L2 never stores "not
    found".

- **An answer from L2 has only its position.**

    To keep L2 small, only `geometry` is stored there (unless `debug` is
    set).  An answer that comes from L2, for example in a new run of your
    program, has `geometry`, `lat`, `lng`, `lon` and `geocoder` (set to
    `'cache'`), but none of the provider's other fields, such as an address
    or a place type.  Answers from L1 keep every field.

- **The `geocoder` key is not always an object.**

    It is the geocoder object when a geocoder answered, and the string
    `'cache'` when the cache answered.  Do not call methods on it without
    checking.  To get a printable name in both cases:

    ```perl
    my $source = ref($result->{geocoder}) || $result->{geocoder};
    ```

- **Changing an answer changes the cache.**

    The first answer for a place is the same hash that L1 stores.  If you
    change it, later answers for that place, which are copies of the L1 entry,
    include your change.  Copy the answer before you change it.

- **The hash you give to `push()` is changed.**

    `limit` counts down inside the hash reference that you pushed.  If you
    push the same hash reference into two lists, they share one limit.  A
    clone made with `$list->new()` has its own copy.

- **The cache key is the exact text.**

    `'Paris, France'`, `'paris, france'` and `'Paris,France'` are three
    different keys, and each one asks the geocoders again.  Only runs of
    white space are made into one space before the text is used as a key.

- **HTML entities are always decoded.**

    `'AT&amp;T Park'` is looked up as `'AT&T Park'`.  There is no way to
    look up text that really contains `&amp;`.

- **Strings of digits depend on an optional module.**

    When [Geo::Location::Predicate](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APredicate) is installed, `geocode('12345')` croaks.
    When it is not installed, `'12345'` is sent to the geocoders.  If you
    handle postcodes or ZIP codes, add the country, such as
    `'12345, USA'`.

- **`reverse_geocode()` ignores `regex`.**

    A geocoder added with `regex` is still asked to reverse geocode every
    position.  Only `limit` is honoured.

- **The log grows until you empty it.**

    Every call adds to the log.  In a long-running program, such as a web
    server, call `flush()` from time to time.

- **Debug output goes to standard output.**

    With `debug` set, messages are printed to `STDOUT`, not `STDERR`, so
    they mix with your program's own output.  The same messages are always
    given to the configured `logger` at debug level, whether `debug` is set
    or not, so a logger is the way to collect them somewhere else.

## Encoding

- **Place names** (`location` in `geocode()`) may contain any
Unicode text, including accented letters, other alphabets and emoji.
Give them to `geocode()` as Perl _character_ strings: if your text is
UTF-8 bytes from a file or a web form, decode it first, for example with
`Encode::decode('UTF-8', $bytes)`.  HTML entities in the text are decoded
into characters, so text that mixes UTF-8 bytes that are not yet decoded
with entities becomes garbled.  The text is passed to each geocoder unchanged apart from
that; whether a geocoder understands emoji is up to the geocoder.
- **White space.**  Runs of ASCII spaces, tabs and new lines are
always made into one space.  Unicode spaces, such as the no-break space,
may or may not be, depending on how Perl stores the string; do not rely on
it.
- **Positions** (`latlng` in `reverse_geocode()`) must be ASCII.
Only the digits `0` to `9` are accepted.  Other Unicode digits, such as
Eastern Arabic or full-width digits, are refused.
- **Cache keys** are the cleaned text, so they can contain any
character.  L1 and a plain-hash L2 accept them all.  An L2 object must
accept character-string keys; [CHI](https://metacpan.org/pod/CHI) does.
- **Answers** are returned as the geocoder gave them.  Most
geocoders return character strings.
- **Debug output** prints place names to `STDOUT`.  If they contain
characters above 255, Perl warns `Wide character in print` unless
`STDOUT` has an encoding layer, such as
`binmode(STDOUT, ':encoding(UTF-8)')`.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Bugs

Please report any bugs or feature requests to
`bug-geo-coder-list at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List).

Known limitations:

- `reverse_geocode()` does not yet support [Geo::Location::Point](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APoint) objects.
- `reverse_geocode()` does not honour `regex`.

## See Also

- [Test Dashboard](https://nigelhorne.github.io/Geo-Coder-List/coverage/)
- [CHI](https://metacpan.org/pod/CHI)
- [Geo::Coder::All](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AAll)
- [Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces)
- [Geo::Coder::Many](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AMany)
- [Geo::Location::Predicate](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APredicate)
- [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3)
- [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Readonly](https://metacpan.org/pod/Readonly)

## Support

You can find documentation for this module with the perldoc command:

```
perldoc Geo::Coder::List
```

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-List](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-List)

- MetaCPAN

    [https://metacpan.org/release/Geo-Coder-List](https://metacpan.org/release/Geo-Coder-List)

## Formal Specification

The specifications below use the Z notation.  They describe what each
method does to the state of the object; they do not describe how.

### State

```
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
```

### New

```
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
```

### Push

```
┌─ Push ─────────────────────────────────────────────────────────
│ ΔGeoCoderList
│ g? : Entry
├────────────────────────────────────────────────────────────────
│ g? ≠ ⊥
│ geocoders′ = geocoders ⁀ ⟨g?⟩
│ L1′ = L1 ∧ L2′ = L2 ∧ log′ = log
└────────────────────────────────────────────────────────────────

PushUndef ≙ [ ΞGeoCoderList ; g? : Entry | g? = ⊥ ] ⇒ croak
```

### Geocode

```
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
```

### Ua

```
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
```

### Reverse\_Geocode

```
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
```

### Log

```
┌─ Log ──────────────────────────────────────────────────────────
│ ΞGeoCoderList
│ entries! : seq LogEntry
├────────────────────────────────────────────────────────────────
│ entries! = log
└────────────────────────────────────────────────────────────────
```

### Flush

```
┌─ Flush ────────────────────────────────────────────────────────
│ ΔGeoCoderList
│ self! : GeoCoderList
├────────────────────────────────────────────────────────────────
│ log′ = ⟨⟩
│ geocoders′ = geocoders ∧ L1′ = L1 ∧ L2′ = L2
│ self! = θGeoCoderList′
└────────────────────────────────────────────────────────────────
```

## State Diagram

An object has three parts that change over time: its chain of geocoders,
its cache (one state for each place name), and its log.  Each part is
shown on its own below.

### The Object and Its Chain

```
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
```

### The Cache, for One Place Name $T

```
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
```

### The Limit of One Geocoder Pushed With Limit => N

```
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
```

### The Log

```perl
+-----------+  geocode() or reverse_geocode()   +-------------+
|  EMPTY    |---------------------------------->|  HAS        |<--+
|  log = [] |  appends one entry per geocoder   |  ENTRIES    |---+ geocode() /
+-----------+  asked, or one for a cache hit    +-------------+   reverse_geocode():
     ^                                                 |          appends entries
     |               flush(): log = [], returns $self  |
     +-------------------------------------------------+
     ^
     | new() and clone: start EMPTY
```

## License and Copyright

Copyright 2016-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
