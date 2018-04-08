[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-Free.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-Free)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/8nk00o0rietskf29/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-free-4onbr/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/Geo-Coder-Free/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Geo-Coder-Free?branch=master)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/4097424524111879/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/4097424524111879/heads/master/)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-Free.svg)](http://search.cpan.org/~nhorne/Geo-Coder-Free/)

# Geo::Coder::Free

Provides a geocoding functionality using free databases

# VERSION

Version 0.07

# SYNOPSIS

    use Geo::Coder::Free;

    my $geocoder = Geo::Coder::Free->new();
    my $location = $geocoder->geocode(location => 'Ramsgate, Kent, UK');

    # Use a local download of http://results.openaddresses.io/
    my $openaddr_geocoder = Geo::Coder::Freee->new(openaddr => $ENV{'OPENADDR_HOME'});
    $location = $openaddr_geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');

# DESCRIPTION

Geo::Coder::Free provides an interface to free databases by acting as a front-end to
Geo::Coder::Free::MaxMind and Geo::Coder::Free::OpenAddresses.

The cgi-bin directory contains a simple DIY geocoding website:

    curl 'http://localhost/~user/cgi-bin/page.fcgi?page=query&q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA'

# METHODS

## new

    $geocoder = Geo::Coder::Free->new();

Takes one optional parameter, openaddr, which is the base directory of
the OpenAddresses data downloaded from [http://results.openaddresses.io](http://results.openaddresses.io).

Takes one optional parameter, directory,
which tells the library where to find the MaxMind and GeoNames files admin1db, admin2.db and cities.\[sql|csv.gz\].
If that parameter isn't given, the module will attempt to find the databases, but that can't be guaranteed.

## geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'longitude'}, "\n";

    # TODO:
    # @locations = $geocoder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

## reverse\_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

To be done.

## ua

Does nothing, here for compatibility with other geocoders

## run

You can also run this module from the command line:

    perl lib/Geo/Coder/Free.pm 1600 Pennsylvania Avenue NW, Washington DC

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# BUGS

Lots of lookups fail at the moment.

The openaddresses.io code has yet to be completed.
There are die()s where the code path has yet to be written.

The MaxMind data only contains cities.
The openaddresses data doesn't cover the globe.

Can't parse and handle "London, England".

See [Geo::Coder::Free::OpenAddresses](https://metacpan.org/pod/Geo::Coder::Free::OpenAddresses) for instructions creating its SQLite database from
[http://results.openaddresses.io/](http://results.openaddresses.io/).

# SEE ALSO

VWF, openaddresses, MaxMind and geonames.

# LICENSE AND COPYRIGHT

Copyright 2017-2018 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at \`&lt;njh at nigelhorne.com>\`.

This product includes GeoLite2 data created by MaxMind, available from
[http://www.maxmind.com](http://www.maxmind.com).
