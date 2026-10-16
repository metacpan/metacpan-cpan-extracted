## Name

Geo::Location::Point - Location information

## Version

Version 0.16

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

## Support

This module is provided as-is without any warranty.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Bugs

There is no validation on the attribute in the AUTOLOAD method,
so typos such as "citty" will not be caught.

## See Also

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Geo-Location-Point/coverage/)

[GIS::Distance](https://metacpan.org/pod/GIS%3A%3ADistance),
[Geo::Point](https://metacpan.org/pod/Geo%3A%3APoint),
[TimeZone::TimeZoneDB](https://metacpan.org/pod/TimeZone%3A%3ATimeZoneDB).

## License and Copyright

Copyright 2019-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
