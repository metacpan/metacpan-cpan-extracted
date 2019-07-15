[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-Free.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-Free)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/8nk00o0rietskf29/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-free-4onbr/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/Geo-Coder-Free/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Geo-Coder-Free?branch=master)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/4097424524111879/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/4097424524111879/heads/master/)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-Free.svg)](http://search.cpan.org/~nhorne/Geo-Coder-Free/)

# NAME

Geo::Coder::Free - Provides a Geo-Coding functionality using free databases

# VERSION

Version 0.20

# SYNOPSIS

    use Geo::Coder::Free;

    my $geo_coder = Geo::Coder::Free->new();
    my $location = $geo_coder->geocode(location => 'Ramsgate, Kent, UK');

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

    # Use a local download of http://results.openaddresses.io/
    my $openaddr_geo_coder = Geo::Coder::Free->new(openaddr => $ENV{'OPENADDR_HOME'});
    $location = $openaddr_geo_coder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

# DESCRIPTION

Geo::Coder::Free provides an interface to free databases by acting as a front-end to
Geo::Coder::Free::MaxMind and Geo::Coder::Free::OpenAddresses.

The cgi-bin directory contains a simple DIY Geo-Coding website.

    cgi-bin/page.fcgi page=query q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA

You can see a sample website at [https://geocode.nigelhorne.com/](https://geocode.nigelhorne.com/).

    curl 'https://geocode.nigelhorne.com/cgi-bin/page.fcgi?page=query&q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA'

# METHODS

## new

    $geo_coder = Geo::Coder::Free->new();

Takes one optional parameter, openaddr, which is the base directory of
the OpenAddresses data downloaded from [http://results.openaddresses.io](http://results.openaddresses.io).

The database also will include data from Who's On First [https://whosonfirst.org](https://whosonfirst.org).

Takes one optional parameter, directory,
which tells the library where to find the MaxMind and GeoNames files admin1db, admin2.db and cities.\[sql|csv.gz\].
If that parameter isn't given, the module will attempt to find the databases, but that can't be guaranteed.

## geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'longitude'}, "\n";

    # TODO:
    # @locations = $geo_coder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

    # Note that this yields many false positives and isn't useable yet
    my @matches = $geo_coder->geocode(scantext => 'arbitrary text', region => 'US');

## reverse\_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

To be done.

## ua

Does nothing, here for compatibility with other Geo-Coders

## run

You can also run this module from the command line:

    perl lib/Geo/Coder/Free.pm 1600 Pennsylvania Avenue NW, Washington DC

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# GETTING STARTED

Before you start,
install [App::csv2sqlite](https://metacpan.org/pod/App::csv2sqlite);
optionally set the environment variable OPENADDR\_HOME to point to an empty directory and download the data from [http://results.openaddresses.io](http://results.openaddresses.io) into that directory;
optionally set the environment variable WHOSONFIRST\_HOME to point to an empty directory and download the data using [https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-sqlite-download](https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-sqlite-download).
You do not need to download the MaxMind data, that will be downloaded automatically.

# MORE INFORMATION

I've written a few Perl related Genealogy programs including gedcom ([https://github.com/nigelhorne/gedcom](https://github.com/nigelhorne/gedcom))
and ged2site ([https://github.com/nigelhorne/ged2site](https://github.com/nigelhorne/ged2site)).
One of the things that these do is to check the validity of your family tree, and one of those tasks is to verify place-names.
Of course places do change names and spelling becomes more consistent over the years, but the vast majority remain the same.
Enough of a majority to computerise the verification.
Unfortunately all of the on-line services have one problem or another - most either charge for large number of access, or throttle the number of look-ups.
Even my modest tree, just over 2000 people, reaches those limits.

There are, however, a number of free databases that can be used, including MaxMind, GeoNames, OpenAddresses and WhosOnFirst.
The objective of Geo::Coder::Free ([https://github.com/nigelhorne/Geo-Coder-Free](https://github.com/nigelhorne/Geo-Coder-Free))
is to create a database of those databases and to create a search engine either through a local copy of the database or through an on-line website.
Both are in their early days, but I have examples which do surprisingly well.

The local copy of the database is built using the createdatabase.PL script which is bundled with G:C:F.
That script creates a single SQLite file from downloaded copies of the databases listed above, to create the database you will need
to first install [App::csv2sqlite](https://metacpan.org/pod/App::csv2sqlite).
Running 'make' will download GeoNames and MaxMind, but OpenAddresses and WhosOnFirst need to be downloaded manually if you decide to use them - they are treated as optional by G:C:F.

There is a sample website at [https://geocode.nigelhorne.com/](https://geocode.nigelhorne.com/).  The source code for that site is included in the G:C:F distribution.

# BUGS

Some lookups fail at the moments, if you find one please file a bug report.

Doesn't include results from
[Geo::Coder::Free::Local](https://metacpan.org/pod/Geo::Coder::Free::Local).

The MaxMind data only contains cities.
The OpenAddresses data doesn't cover the globe.

Can't parse and handle "London, England".

# SEE ALSO

VWF, OpenAddresses, MaxMind and geonames.

See [Geo::Coder::Free::OpenAddresses](https://metacpan.org/pod/Geo::Coder::Free::OpenAddresses) for instructions creating the SQLite database from
[http://results.openaddresses.io/](http://results.openaddresses.io/).

# LICENSE AND COPYRIGHT

Copyright 2017-2019 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at \`&lt;njh at nigelhorne.com>\`.

This product uses GeoLite2 data created by MaxMind, available from
[https://www.maxmind.com/en/home](https://www.maxmind.com/en/home). See their website for licensing information.

This product uses data from Who's on First.
See [https://github.com/whosonfirst-data/whosonfirst-data/blob/master/LICENSE.md](https://github.com/whosonfirst-data/whosonfirst-data/blob/master/LICENSE.md) for licensing information.
