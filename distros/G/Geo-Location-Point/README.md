## Name

Geo::Location::Point - Location information

## Version

Version 0.19

## Synopsis

Geo::Location::Point encapsulates geographical point data with latitude and longitude.
It supports distance calculations,
comparison between points,
and provides various convenience methods for attributes like latitude, longitude, and related string representations.

```perl
use Geo::Location::Point;

my $location = Geo::Location::Point->new(latitude => 0.01, longitude => -71);
```

## Subroutines/Methods

### New

Initialise a new object, accepting latitude and longitude via a hash or hash reference.
Takes one optional argument 'key' which is an API key for [https://timezonedb.com](https://timezonedb.com) for looking up timezone data.

```perl
$location = Geo::Location::Point->new({ latitude => 0.01, longitude => -71 });
```

### Lat

```
print 'Latitude: ', $location->lat(), "\n";
print 'Longitude: ', $location->long(), "\n";
```

### Latitude

Synonym for lat().

### Long

```
print 'Latitude: ', $location->lat(), "\n";
print 'Longitude: ', $location->long(), "\n";
```

### Lng

Synonym for long().

### Longitude

Synonym for long().

### Distance

Determine the distance between two geographical points,
returns a [Class::Measure::Length](https://metacpan.org/pod/Class%3A%3AMeasure%3A%3ALength) object.

### Equal

Check if two points are identical within a small tolerance.

```perl
my $loc1 = Geo::Location::Point->new(lat => 2, long => 2);
my $loc2 = Geo::Location::Point->new(lat => 2, long => 2);
print ($loc1 == $loc2), "\n";       # Prints 1
```

### Not\_Equal

Are two points different?

```perl
my $loc1 = Geo::Location::Point->new(lat => 2, long => 2);
my $loc2 = Geo::Location::Point->new(lat => 2, long => 2);
print ($loc1 != $loc2), "\n";       # Prints 0
```

### Tz

Returns the timezone of the location.
Needs [TimeZone::TimeZoneDB](https://metacpan.org/pod/TimeZone%3A%3ATimeZoneDB).

### Timezone

Synonym for tz().

### As\_String

Generate a human-readable string describing the point,
incorporating additional attributes like city or country if available.

### As\_Uri

Convert the point to a Geo URI scheme string (geo:latitude,longitude).
See [https://en.wikipedia.org/wiki/Geo\_URI\_scheme](https://en.wikipedia.org/wiki/Geo_URI_scheme).
Arguably it should return a [URI](https://metacpan.org/pod/URI) object instead.

### Attr

Get or set arbitrary attributes, such as city or country.
A call with an argument sets the attribute and returns the value that was set;
a call without one reads it back and returns `undef` if it was never set.

```
$location->city('London');
$location->country('UK');
print $location->as_string(), "\n";
print "$location\n";        # Calls as_string
```

It is the argument list, not the value, that decides whether a call is a read or a write,
so false values are attributes like any other and are stored and returned unchanged:

```
$location->confidence(0);
print 'matched: ', defined($location->confidence()) && $location->confidence(), "\n";
```

The upper case variant of the key is consulted
(but not overwritten) when the key as given has never been set,
which is how the MaxMind field names are read. An attribute that has been set,
however false, takes precedence over it.

### Geocoder

The distribution that produced the point, such as `Geo::Coder::Free`.

```
$location->geocoder('Geo::Coder::Free');
```

### Database

The database the distribution answered from, such as `OpenAddresses`, `Local`
or `MaxMind`.

```
$location->database('OpenAddresses');
```

### Confidence

How good the match is, from `0` to `1` inclusive, where `1` is an exact
match. A confidence that is not a number, or that falls outside that range, is
rejected rather than stored.

```
$location->confidence(0);           # Tried and rejected
$location->confidence(0.8);         # A good match
```

### Accuracy\_Levels

The accuracy levels a point may claim, most precise first: `address` (a house
number), `street`, `postcode`, `locality`, `city`, `region` and
`country`.

This is the vocabulary, written down once here and read from here by
[Geo::Coder::Free::Provenance](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AProvenance) rather than copied, so the levels a point
accepts and the levels a backend reports cannot drift apart.  `accuracy()`
accepts these and refuses anything else.

The rule that turns the fields a backend matched into one of these levels is
["accuracy\_for"](#accuracy_for), beside the list it returns a level from.

The list is read-only, and a caller that tries to add to it is refused, because
it is the list `accuracy()` checks against: were it writable, a level pushed
into it would be published to every reader of this list while the module went on
refusing it.

```perl
my $levels = Geo::Location::Point::ACCURACY_LEVELS();
```

### Accuracy\_for

The accuracy a match can claim, from the fields that made it.  The most precise
field present decides: a house number makes it an `address`, a road a
`street`, a postcode a `postcode`, a name or a city a `locality`, a state or
region a `region`, and a country a `country`.  So a dataset row carrying only
a city, state and country is a `locality`: a named place, not an address.

```perl
my $level = Geo::Location::Point::accuracy_for(qw(house_number road city));
```

Always returns one of the ["ACCURACY\_LEVELS"](#accuracy_levels): a match on a row with none of the
fields above is still a named place, so it is reported as a `locality` rather
than left unsaid, because every result promises an accuracy.

It is a function, not a method - the fields are what a backend matched, not
something a point carries - and it lives beside the vocabulary it returns a
level from, so the levels a point accepts and the rules that choose one of them
have a single home.

### Accuracy

How precise the coordinates behind a match can claim to be.  The levels are
those in ["ACCURACY\_LEVELS"](#accuracy_levels); anything else is rejected, because a reader
deciding what a point may claim about itself has to be able to trust the
value.

```
$location->accuracy('city');
```

### Country

The country of the point, as the data spells it: `GB`, `US`, `Canada`. It
is stored as given rather than normalised, so it is whatever the backend
matched.

```
$location->country('GB');
```

### City

The city, town or similar locality of the point.

```
$location->city('London');
```

### State

The state, province or region of the point.

```
$location->state('KY');
```

## Support

This module is provided as-is without any warranty.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Bugs

There is no validation on the attribute in the AUTOLOAD method,
so typos such as "citty" will not be caught.
`geocoder`, `database`, `confidence`, `accuracy`, `country`, `city` and
`state` have documented accessors of their own that do check what they are
given,
but they are the only attributes that do,
and `new()` stores whatever it is handed without checking it,
so a provenance field set through the constructor can still be any value.

## See Also

- [Test Dashboard](https://nigelhorne.github.io/Geo-Location-Point/coverage/)

[GIS::Distance](https://metacpan.org/pod/GIS%3A%3ADistance),
[Geo::Point](https://metacpan.org/pod/Geo%3A%3APoint),
[TimeZone::TimeZoneDB](https://metacpan.org/pod/TimeZone%3A%3ATimeZoneDB).

## License and Copyright

Copyright 2019-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
