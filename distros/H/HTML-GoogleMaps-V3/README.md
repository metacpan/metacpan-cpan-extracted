# NAME

HTML::GoogleMaps::V3 - a simple wrapper around the Google Maps API

<div>

    <a href='https://travis-ci.org/Humanstate/html-googlemaps-v3?branch=master'><img src='https://travis-ci.org/Humanstate/html-googlemaps-v3.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/Humanstate/html-googlemaps-v3?branch=master'><img src='https://coveralls.io/repos/Humanstate/html-googlemaps-v3/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

0.10

# SYNOPSIS

    use HTML::GoogleMaps::V3

    $map = HTML::GoogleMaps::V3->new;
    $map->center("1810 Melrose St, Madison, WI");
    $map->add_marker(point => "1210 W Dayton St, Madison, WI");
    $map->add_marker(point => [ 51, 0 ] );   # Greenwich

    my ($head, $map_div) = $map->onload_render;

# NOTE

This module is forked from [HTML::GoogleMaps](https://metacpan.org/pod/HTML::GoogleMaps) and updated to use V3 of
the API. Note that the module isn't quite a drop in replacement, although
it should be trivial to update your code to use it.

Note that V3 of the API does not require an API key, however you can pass
one and it will be used (useful for analytics).

Also note that this library only implements a subset of the functionality
available in the maps API, if you want more then raise an issue or create
a pull request.

# DESCRIPTION

HTML::GoogleMaps::V3 provides a simple wrapper around the Google Maps
API. It allows you to easily create maps with markers, polylines and
information windows. Thanks to Geo::Coder::Google you can now look
up locations around the world without having to install a local database.

# CONSTRUCTOR

- $map = HTML::GoogleMaps::V3->new;

    Creates a new HTML::GoogleMaps::V3 object. Takes a hash of options.
    Valid options are:

    - api\_key => key (your Google Maps API key)
    - height => height (in pixels or using your own unit)
    - width => width (in pixels or using your own unit)
    - z\_index => place on z-axis (e.g. -1 to ensure scrolling works)
    - geocoder => an object such as Geo::Coder::Google

# METHODS

- $map->center($point)

    Center the map at a given point. Returns 1 on success, 0 if
    the point could not be found.

- $map->zoom($level)

    Set the new zoom level (0 is corsest)

- $map->dragging($enable)

    Enable or disable dragging.

- $map->info\_window($enable)

    Enable or disable info windows.

- $map->map\_id($id)

    Set the id of the map div

- $map->map\_type($type)

    Set the map type. Either **normal**, **satellite**, **road**, or **hybrid**.

- $map->add\_marker(point => $point, html => $info\_window\_html)

    Add a marker to the map at the given point. A point can be a unique
    place name, like an address, or a pair of coordinates passed in as
    an arrayref: \[ longitude, latitude \]. Will return 0 if the point
    is not found and 1 on success.

    If **html** is specified, add a popup info window as well.

- $map->add\_polyline(points => \[ $point1, $point2 \])

    Add a polyline that connects the list of points. Other options
    include **color** (any valid HTML color), **weight** (line width in
    pixels) and **opacity** (between 0 and 1). Will return 0 if the points
    are not found and 1 on success.

- $map->onload\_render

    Renders the map and returns a two element list. The first element
    needs to be placed in the head section of your HTML document. The
    second in the body where you want the map to appear. You will also 
    need to add a call to html\_googlemaps\_initialize() in your page's 
    onload handler. The easiest way to do this is adding it to the body
    tag:

        <body onload="html_googlemaps_initialize()">

# SEE ALSO

[https://developers.google.com/maps/documentation/javascript/3.exp/reference](https://developers.google.com/maps/documentation/javascript/3.exp/reference)

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-fixflo

# AUTHORS

Nate Mueller &lt;nate@cs.wisc.edu> - Original Author

Lee Johnson &lt;leejo@cpan.org> - Maintainer of this fork

Nigel Horne - Contributor of several patches
