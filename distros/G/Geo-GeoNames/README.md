# NAME

Geo::GeoNames - Perform geographical queries using GeoNames Web Services

# VERSION

Version 1.15

# SYNOPSIS

        use Geo::GeoNames;
        my $geo = Geo::GeoNames->new(username => $ENV{'GEONAME_USER'});

        # make a query based on placename
        my $result = $geo->search(q => 'Fredrikstad', maxRows => 2);

        # print the first result
        print ' Name: ', $result->[0]->{name}, "\n";
        print ' Longitude: ', $result->[0]->{lng}, "\n";
        print ' Latitude: ', $result->[0]->{lat}, "\n";

        # Make a query based on postcode
        $result = $geo->postalcode_search(
                postalcode => '1630', maxRows => 3, style => 'FULL'
        );

# DESCRIPTION

Before you start, get a free GeoNames account and enable it for
access to the free web service:

- Get an account

    Go to [http://www.geonames.org/login](http://www.geonames.org/login)

- Respond to the email
- Login and enable your account for free access

    [http://www.geonames.org/enablefreewebservice](http://www.geonames.org/enablefreewebservice)

Provides a perl interface to the webservices found at
[http://api.geonames.org](http://api.geonames.org). That is, given a given placename or
postalcode, the module will look it up and return more information
(longitude, latitude, etc) for the given placename or postalcode.
Wikipedia lookups are also supported. If more than one match is found,
a list of locations will be returned.

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
    $geo_coder->ua(LWP::UserAgent::Throttled->new());

# SUBROUTINES/METHODS

- new

            $geo = Geo::GeoNames->new( username => '...' );
            $geo = Geo::GeoNames->new( username => '...', url => $url );

    Constructor for Geo::GeoNames. It returns a reference to an
    Geo::GeoNames object. You may also pass the url of the webservices to
    use. The default value is [http://api.geonames.org](http://api.geonames.org) and is the only url,
    to my knowledge, that provides the services needed by this module. The
    username parameter is required.

- username( $username )

    With a single argument, set the GeoNames username and return that
    username. With no arguments, return the username.

- default\_ua

    Returns the default UserAgent used a Mojo::UserAgent object that
    carps on errors.

- default\_url

    Returns `http://api.geonames.org`.

- url( $url )

    With a single argument, set the GeoNames url and return that
    url. With no arguments, return the url.

- geocode( $placename )

    This method is just an easy access to search. It is the same as
    saying:

            $geo->search( q => $placename );

- search( arg => $arg )

    Searches for information about a placename. Valid names for **arg** are
    as follows:

            q               => $placename
            name            => $placename
            name_equals     => $placename
            maxRows         => $maxrows
            startRow        => $startrow
            country         => $countrycode
            continentCode   => $continentcode
            adminCode1      => $admin1
            adminCode2      => $admin2
            adminCode3      => $admin3
            fclass          => $fclass
            featureClass    => $fclass,
            featureCode     => $code
            lang            => $lang
            type            => $type
            style           => $style
            isNameRequired  => $isnamerequired
            tag             => $tag
            name_startsWith => $name_startsWith
            countryBias     => $countryBias
            cities          => $cities
            operator        => $operator
            searchlang      => $searchlang
            charset         => $charset
            fuzzy           => $fuzzy
            north           => $north
            west            => $west
            east            => $east
            south           => $south
            orderby         => $orderby

    One, and only one, of **q**, **name**, **name\_equals**, or **name\_startsWith** must be
    supplied to this method.

    fclass is deprecated.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export/geonames-search.html](http://www.geonames.org/export/geonames-search.html)

- find\_nearby\_placename( arg => $arg )

    Reverse lookup for closest placename to a given coordinate. Valid
    names for **arg** are as follows:

            lat     => $lat
            lng     => $lng
            radius  => $radius
            style   => $style
            maxRows => $maxrows

    Both **lat** and **lng** must be supplied to this method.

    For a thorough descriptions of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- find\_nearest\_address(arg => $arg)

    Reverse lookup for closest address to a given coordinate. Valid names
    for **arg** are as follows:

            lat => $lat
            lng => $lng

    Both **lat** and **lng** must be supplied to this method.

    For a thorough descriptions of the arguments, see
    [http://www.geonames.org/maps/reverse-geocoder.html](http://www.geonames.org/maps/reverse-geocoder.html)

    US only.

- find\_nearest\_intersection(arg => $arg)

    Reverse lookup for closest intersection to a given coordinate. Valid
    names for **arg** are as follows:

            lat => $lat
            lng => $lng

    Both **lat** and **lng** must be supplied to this method.

    For a thorough descriptions of the arguments, see
    [http://www.geonames.org/maps/reverse-geocoder.html](http://www.geonames.org/maps/reverse-geocoder.html)

    US only.

- find\_nearby\_streets(arg => $arg)

    Reverse lookup for closest streets to a given coordinate. Valid names
    for **arg** are as follows:

            lat => $lat
            lng => $lng

    Both **lat** and **lng** must be supplied to this method.

    For a thorough descriptions of the arguments, see
    [http://www.geonames.org/maps/reverse-geocoder.html](http://www.geonames.org/maps/reverse-geocoder.html)

    US only.

- postalcode\_search(arg => $arg)

    Searches for information about a postalcode. Valid names for **arg**
    are as follows:

            postalcode => $postalcode
            placename  => $placename
            country    => $country
            maxRows    => $maxrows
            style      => $style

    One, and only one, of **postalcode** or **placename** must be supplied
    to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- find\_nearby\_postalcodes(arg => $arg)

    Reverse lookup for postalcodes. Valid names for **arg** are as follows:

            lat     => $lat
            lng     => $lng
            radius  => $radius
            maxRows => $maxrows
            style   => $style
            country => $country

    Both **lat** and **lng** must be supplied to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- postalcode\_country\_info

    Returns a list of all postalcodes found on GeoNames. This method
    takes no arguments.

- country\_info(arg => $arg)

    Returns country information. Valid names for **arg** are as follows:

            country => $country
            lang    => $lang

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- find\_nearby\_wikipedia(arg => $arg)

    Reverse lookup for Wikipedia articles. Valid names for **arg** are as
    follows:

            lat     => $lat
            lng     => $lng
            radius  => $radius
            maxRows => $maxrows
            lang    => $lang
            country => $country

    Both **lat** and **lng** must be supplied to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- find\_nearby\_wikipedia\_by\_postalcode(arg => $arg)

    Reverse lookup for Wikipedia articles. Valid names for **arg** are as
    follows:

            postalcode => $postalcode
            country    => $country
            radius     => $radius
            maxRows    => $maxrows

    Both **postalcode** and **country** must be supplied to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- wikipedia\_search(arg => $arg)

    Searches for Wikipedia articles. Valid names for **arg** are as
    follows:

            q       => $placename
            maxRows => $maxrows
            lang    => $lang
            title   => $title

    **q** must be supplied to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- wikipedia\_bounding\_box(arg => $arg)

    Searches for Wikipedia articles. Valid names for **arg** are as
    follows:

            south   => $south
            north   => $north
            east    => $east
            west    => $west
            lang    => $lang
            maxRows => $maxrows

    **south**, **north**, **east**, and **west** and must be supplied to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- cities(arg => $arg)

    Returns a list of cities and placenames within the bounding box.
    Valid names for **arg** are as follows:

            south   => $south
            north   => $north
            east    => $east
            west    => $west
            lang    => $lang
            maxRows => $maxrows

    **south**, **north**, **east**, and **west** and must be supplied to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- country\_code(arg => $arg)

    Return the country code for a given point. Valid names for **arg** are
    as follows:

            lat    => $lat
            lng    => $lng
            radius => $radius
            lang   => $lang

    Both **lat** and **lng** must be supplied to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- earthquakes(arg => $arg)

    Returns a list of cities and placenames within the bounding box.
    Valid names for **arg** are as follows:

            south        => $south
            north        => $north
            east         => $east
            west         => $west
            date         => $date
            minMagnitude => $minmagnitude
            maxRows      => $maxrows

    **south**, **north**, **east**, and **west** and must be supplied to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- find\_nearby\_weather(arg => $arg)

    Return the country code for a given point. Valid names for **arg** are
    as follows:

            lat => $lat
            lng => $lng

    Both **lat** and **lng** must be supplied to this method.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- get(arg => $arg)

    Returns information about a given place based on a geonameId.

            geonameId  => $geonameId
            lang       => $lang
            style      => $style (Seems to be ignored, although documented)

    **geonamesId** must be supplied to this method. **lang** and **style** are optional.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export](http://www.geonames.org/export)

- hierarchy(arg => $arg)

    Returns all GeoNames higher up in the hierarchy of a place based on a geonameId.

        geonameId => $geonameId
        style     => $style (Not documented, but seems to be respected)

    **geonamesId** must be supplied to this method. **style** is optional.

    For a thorough description of the arguments, see
    [http://www.geonames.org/export/place-hierarchy.html#hierarchy](http://www.geonames.org/export/place-hierarchy.html#hierarchy)

- children(arg => $arg)

    Returns the children (admin divisions and populated places) for a given geonameId.

        geonameId => $geonameId
        style     => $style (Not documented, but seems to be respected)

    **geonamesId** must be supplied to this method. **style** is optional.

    For a thorough description of the arguments, see
    [https://www.geonames.org/export/place-hierarchy.html](https://www.geonames.org/export/place-hierarchy.html)

# RETURNED DATASTRUCTURE

The datastructure returned from methods in this module is an array of
hashes. Each array element contains a hash which in turn contains the
information about the placename/postalcode.

For example, running the statement

        my $result = $geo->search(
                q => "Fredrikstad", maxRows => 3, style => "FULL"
                );

yields the result:

        $VAR1 = {
                'population' => {},
                'lat' => '59.2166667',
                'elevation' => {},
                'countryCode' => 'NO',
                'adminName1' => "\x{d8}stfold",
                'fclName' => 'city, village,...',
                'adminCode2' => {},
                'lng' => '10.95',
                'geonameId' => '3156529',
                'timezone' => {
                        'dstOffset' => '2.0',
                        'content' => 'Europe/Oslo',
                        'gmtOffset' => '1.0'
                        },
                'fcode' => 'PPL',
                'countryName' => 'Norway',
                'name' => 'Fredrikstad',
                'fcodeName' => 'populated place',
                'alternateNames' => 'Frederikstad,Fredrikstad,Fredrikstad kommun',
                'adminCode1' => '13',
                'adminName2' => {},
                'fcl' => 'P'
                };

The elements in the hashes depends on which **style** is passed to the
method, but will always contain **name**, **lng**, and **lat** except for
postalcode\_country\_info(), find\_nearest\_address(),
find\_nearest\_intersection(), and find\_nearby\_streets().

# BUGS

This module is provided as-is without any warranty.

Not a bug, but the GeoNames services expects placenames to be UTF-8
encoded, and all data received from the webservices are also UTF-8 encoded.
So make sure that strings are encoded/decoded based on the correct encoding.

Please report any bugs found or feature requests through GitHub issues
[https://github.com/nigelhorne/Geo-GeoNames/issues](https://github.com/nigelhorne/Geo-GeoNames/issues).
or
`bug-geo-geonamnes at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-GeoNames](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-GeoNames).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

- Test coverage report: [https://nigelhorne.github.io/Geo-GeoNames/coverage/](https://nigelhorne.github.io/Geo-GeoNames/coverage/)
- [http://www.geonames.org/export](http://www.geonames.org/export)
- [http://www.geonames.org/export/ws-overview.html](http://www.geonames.org/export/ws-overview.html)

# SOURCE AVAILABILITY

The source code for this module is available from Github
at [https://github.com/nigelhorne/Geo-GeoNames](https://github.com/nigelhorne/Geo-GeoNames).

# AUTHOR

Per Henrik Johansen, `<per.henrik.johansen@gmail.com>`.

Previously maintained by brian d foy, `<brian.d.foy@gmail.com>`
and Nicolas Mendoza, `<mendoza@pvv.ntnu.no>`

Maintained by Nigel Horne, `<njh at nigelhorne.com>`

# COPYRIGHT AND LICENSE

Copyright (C) 2007-2021 by Per Henrik Johansen
Copyright (C) 2022-2023 by Nigel Horne

This library is available under the Artistic License 2.0.
