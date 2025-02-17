# NAME

HTML::OSM - A module to generate an interactive OpenStreetMap with customizable coordinates and zoom level.

# VERSION

Version 0.03

# SYNOPSIS

`HTML::OSM` is a Perl module for generating an interactive map using OpenStreetMap (OSM) and Leaflet.
The module accepts a list of coordinates with optional labels and zoom level to create a dynamic HTML file containing an interactive map.
The generated map allows users to view marked locations, zoom, and search for locations using the Nominatim API.

    use HTML::OSM;
    my $map = HTML::OSM->new();
    # ...

    $map = HTML::OSM->new(
        coordinates => [
          [34.0522, -118.2437, 'Los Angeles'],
          [undef, undef, 'Paris'],
        ],
        zoom => 14,
    );
    my ($head, $map_div) = $map->onload_render();

- Caching

    Identical geocode requests are cached (using [CHI](https://metacpan.org/pod/CHI) or a user-supplied caching object),
    reducing the number of HTTP requests to the API and speeding up repeated queries.

    This module leverages [CHI](https://metacpan.org/pod/CHI) for caching geocoding responses.
    When a geocode request is made,
    a cache key is constructed from the request.
    If a cached response exists,
    it is returned immediately,
    avoiding unnecessary API calls.

- Rate-Limiting

    A minimum interval between successive API calls can be enforced to ensure that the API is not overwhelmed and to comply with any request throttling requirements.

    Rate-limiting is implemented using [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes).
    A minimum interval between API
    calls can be specified via the `min_interval` parameter in the constructor.
    Before making an API call,
    the module checks how much time has elapsed since the
    last request and,
    if necessary,
    sleeps for the remaining time.

# SUBROUTINES/METHODS

## new

    $map = HTML::OSM->new(
        coordinates => [
          [37.7749, -122.4194, 'San Francisco'],
          [40.7128, -74.0060, 'New York'],
          [51.5074, -0.1278, 'London'],
        ],
        zoom => 10,
    );

Creates a new `HTML::OSM` object with the provided coordinates and optional zoom level.

- `cache`

    A caching object.
    If not provided,
    an in-memory cache is created with a default expiration of one hour.

- coordinates

    An array reference containing a list of coordinates.
    Each entry should be an array with latitude, longitude, and an optional label, in the format:

        [latitude, longitude, label, icon_url]

    If latitude and/or longitude is undefined,
    the label is taken to be a location to be added.
    If no coordinates are provided, an error will be thrown.

- geocoder

    An optional geocoder object such as [Geo::Coder::List](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AList) or [Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree).

- `height`

    Height (in pixels or using your own unit), the default is 400px.

- `min_interval`

    Minimum number of seconds to wait between API requests.
    Defaults to `0` (no delay).
    Use this option to enforce rate-limiting.

- `ua`

    An object to use for HTTP requests.
    If not provided, a default user agent is created.

- `host`

    The API host endpoint.
    Defaults to [https://nominatim.openstreetmap.org/search](https://nominatim.openstreetmap.org/search).

- `width`

    Width (in pixels or using your own unit), the default is 600px.

- zoom

    An optional zoom level for the map, with a default value of 12.

## add\_marker

Add a marker to the map at the given point.
A point can be a unique place name, like an address,
an object that understands `latitude()` and `longitude()`,
or a pair of coordinates passed in as an arrayref: `[ longitude, latitude ]`.
Will return 0 if the point is not found and 1 on success.

It takes two optional arguments:

- html

    Add a popup info window as well.

- icon

    A url to the icon to be added.

## center

Center the map at a given point. Returns 1 on success, 0 if the point could not be found.

## zoom

Get/set the new zoom level (0 is corsest)

    $map->zoom(10);

## onload\_render

Renders the map and returns a two element list.
The first element needs to be placed in the head section of your HTML document.
The second in the body where you want the map to appear.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

# SEE ALSO

- [https://wiki.openstreetmap.org/wiki/API](https://wiki.openstreetmap.org/wiki/API)
- [File::Slurp](https://metacpan.org/pod/File%3A%3ASlurp)
- `HTML::GoogleMaps::V3`

    Much of the interface to `HTML::OSM` mimicks this for compatability.

- [Leaflet](https://metacpan.org/pod/Leaflet)

You can find documentation for this module with the perldoc command.

    perldoc HTML::OSM

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/HTML-OSM](https://metacpan.org/dist/HTML-OSM)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-OSM](https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-OSM)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=HTML-OSM](http://matrix.cpantesters.org/?dist=HTML-OSM)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=HTML::OSM](http://deps.cpantesters.org/?module=HTML::OSM)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-html-osm at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-OSM](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-OSM).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

## TODO

Allow dynamic addition/removal of markers via user input.

# LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2
