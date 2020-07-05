# NAME

Geo::IP2Location::Lite - Lightweight version of Geo::IP2Location with IPv4
support only

<div>

    <a href='https://travis-ci.org/Humanstate/geo-ip2location-lite?branch=master'><img src='https://travis-ci.org/Humanstate/geo-ip2location-lite.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/Humanstate/geo-ip2location-lite?branch=master'><img src='https://coveralls.io/repos/Humanstate/geo-ip2location-lite/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

        use Geo::IP2Location::Lite;

        my $obj = Geo::IP2Location::Lite->open( "/path/to/IP-COUNTRY.BIN" );

        my $countryshort = $obj->get_country_short("20.11.187.239");
        my $countrylong  = $obj->get_country_long("20.11.187.239");
        my $region       = $obj->get_region("20.11.187.239");
        ...

        my ( $cos,$col,$reg ... ) = $obj->get_all("20.11.187.239");

# DESCRIPTION

This module is a lightweight version of Geo::IP2Location that is compatible
with **IPv4** BIN files only. It fixes all the current issues against the
current version of Geo::IP2Location and makes the perl more idiomatic (and
thus easier to maintain). The code is also compatible with older perls
([Geo::IP2Location](https://metacpan.org/pod/Geo::IP2Location) currently only works with 5.14 and above).

You should see the documentation for the original [Geo::IP2Location](https://metacpan.org/pod/Geo::IP2Location) module
for a complete list of available methods, the documentation below includes
**additional** methods addded by this module only.

# DIFFERENCES FROM [Geo::IP2Location](https://metacpan.org/pod/Geo::IP2Location)

The get\_country method has been added to get both short and long in one call:

        my ( $country_short,$country_long ) = $obj->get_country( $ip );

The ISO-3166 code for United Kingdom of Great Britain and Northern Ireland has
been corrected from **UK** to **GB**

# SEE ALSO

[Geo::IP2Location](https://metacpan.org/pod/Geo::IP2Location)

http://www.ip2location.com

# VERSION

0.13

# AUTHOR

Forked from Geo::IP2Location by Lee Johnson `leejo@cpan.org`. If you would
like to contribute documentation, features, bug fixes, or anything else then
please raise an issue / pull request:

    https://github.com/Humanstate/geo-ip2location-lite

# LICENSE

Copyright (c) 2016 IP2Location.com

All rights reserved. This package is free software; It is licensed under the
GPL.
