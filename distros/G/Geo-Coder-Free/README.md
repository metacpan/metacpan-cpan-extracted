Geo-Coder-Free
==============

[![Actions States](https://img.shields.io/github/actions/workflow/status/nigelhorne/geo-coder-free/test.yml?branch=master)](https://github.com/nigelhorne/Geo-Coder-Free/actions)
[![Appveyor status](https://ci.appveyor.com/api/projects/status/8nk00o0rietskf29/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-free-4onbr/branch/master)
[![Coveralls Status](https://coveralls.io/repos/github/nigelhorne/Geo-Coder-Free/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Geo-Coder-Free?branch=master)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-Free.svg)](http://search.cpan.org/~nhorne/Geo-Coder-Free/)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/4097424524111879/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/4097424524111879/heads/master/)
[![Kwalitee](https://cpants.cpanauthors.org/dist/Geo-Coder-Free.png)](http://cpants.cpanauthors.org/dist/Geo-Coder-Free)
[![Travis Status](https://travis-ci.org/nigelhorne/Geo-Coder-Free.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-Free)

# NAME

Geo::Coder::Free - Provides a Geo-Coding functionality using free databases

# VERSION

Version 0.41

# DESCRIPTION

`Geo::Coder::Free` translates addresses into latitude and longitude coordinates using a local `SQLite` database built from free databases such as
[https://spelunker.whosonfirst.org/](https://spelunker.whosonfirst.org/),
[https://maxmind.com](https://maxmind.com),
[https://github.com/dr5hn/countries-states-cities-database](https://github.com/dr5hn/countries-states-cities-database),
[https://openaddresses.io/](https://openaddresses.io/), and
[https://openstreetmap.org](https://openstreetmap.org).
The module is designed to be flexible,
importing the data into the database,
and supporting both command-line and programmatic usage.
The module includes methods for geocoding (translating addresses to coordinates) and reverse geocoding (translating coordinates to addresses),
though the latter is not fully implemented.
It also provides utilities for handling common address formats and abbreviations,
and it includes a sample CGI script for a web-based geocoding service.
The module is intended for use in applications requiring geocoding without relying on paid or rate-limited online services,
and it supports customization through environment variables and optional database downloads.

The cgi-bin directory contains a simple DIY Geo-Coding website.

    cgi-bin/page.fcgi page=query q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA

The sample website is currently down while I look for a new host.
When it's back up you will be able to use this to test it.

    curl 'https://geocode.nigelhorne.com/cgi-bin/page.fcgi?page=query&q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA'

# SYNOPSIS

    use Geo::Coder::Free;

    my $geo_coder = Geo::Coder::Free->new();
    my $location = $geo_coder->geocode(location => 'Ramsgate, Kent, UK');

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

    # Use a local download of http://results.openaddresses.io/ and https://www.whosonfirst.org/
    my $openaddr_geo_coder = Geo::Coder::Free->new(openaddr => $ENV{'OPENADDR_HOME'});
    $location = $openaddr_geo_coder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

# METHODS

## new

    $geo_coder = Geo::Coder::Free->new();

Takes one optional parameter, openaddr, which is the base directory of
the OpenAddresses data from [http://results.openaddresses.io](http://results.openaddresses.io),
and Who's On First data from [https://whosonfirst.org](https://whosonfirst.org).

Takes one optional parameter, directory,
which tells the object where to find the MaxMind and GeoNames files admin1db,
admin2.db and cities.\[sql|csv.gz\].
If that parameter isn't given,
the module will attempt to find the databases,
but that can't be guaranteed to work.

## geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'longitude'}, "\n";

    # TODO:
    # @locations = $geo_coder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

    # Note that this yields many false positives and isn't useable yet
    my @matches = $geo_coder->geocode(scantext => 'arbitrary text', region => 'US');

    @matches = $geo_coder->geocode(scantext => 'arbitrary text', region => 'GB', ignore_words => [ 'foo', 'bar' ]);

## reverse\_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

To be done.

## ua

Does nothing, here for compatibility with other Geo-Coders

## run

You can also run this module from the command line:

    perl lib/Geo/Coder/Free.pm 1600 Pennsylvania Avenue NW, Washington DC

# GETTING STARTED

To download, import and setup the local database,
before running "make", but after running "perl Makefile.PL", run these instructions.

Optionally set the environment variable OPENADDR\_HOME to point to an empty directory and download the data from [http://results.openaddresses.io](http://results.openaddresses.io) into that directory; and
optionally set the environment variable WHOSONFIRST\_HOME to point to an empty directory and download the data using [https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-clone](https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-clone).
The script bin/download\_databases (see below) will do those for you.
You do not need to download the MaxMind data, that will be downloaded automatically.

You will need to create the database used by Geo::Coder::Free.

Install [App::csv2sqlite](https://metacpan.org/pod/App%3A%3Acsv2sqlite) and [https://github.com/nigelhorne/NJH-Snippets](https://github.com/nigelhorne/NJH-Snippets).
Run bin/create\_sqlite - converts the Maxmind "cities" database from CSV to SQLite.

To use with MariaDB,
set MARIADB\_SERVER="$hostname;$port" and
MARIADB\_USER="$user;$password" (TODO: username/password should be asked for)
The code will use a database called geo\_code\_free which will be deleted
if it exists.
$user should only need to privileges to DROP, CREATE, SELECT, INSERT, CREATE and INDEX
on that database. If you've set DEBUG mode in createdatabase.PL, or are playing
with REPLACE instead of INSERT, you'll also need DELETE privileges - but non-developers
don't need to have that.

Optional steps to download and install large databases.
This will take a long time and use a lot of disc space, be clear that this is what you want.
In the bin directory there are some helper scripts to do this.
You will need to tailor them to your set up, but that's not that hard as the
scripts are trivial.

1. `mkdir $WHOSONFIRST_HOME; cd $WHOSONFIRST_HOME` run wof-clone from NJH-Snippets.

    This can take a long time because it contains lots of directories which filesystem drivers
    seem to take a long time to navigate (at least my EXT4 and ZFS systems do).

2. Install [https://github.com/dr5hn/countries-states-cities-database.git](https://github.com/dr5hn/countries-states-cities-database.git) into $DR5HN\_HOME.
This data contains cities only,
so it's not used if OSM\_HOME is set,
since the latter is much more comprehensive.
Also, only Australia, Canada and the US is imported, as the UK data is difficult to parse.
3. Run bin/download\_databases - this will download the WhosOnFirst, Openaddr,
Open Street Map and dr5hn databases.
Check the values of OSM\_HOME, OPENADDR\_HOME,
DR5HN\_HOME and WHOSONFIRST\_HOME within that script,
you may wish to change them.
The Makefile.PL file will download the MaxMind database for you, as that is not optional.
4. Run bin/create\_db - this creates the database used by G:C:F using the data you've just downloaded
The database is called openaddr.sql,
even though it does include all of the above data.
That's historical before I added the WhosOnFirst database.
The names are a bit of a mess because of that.
I should rename it to geo-coder-free.sql, even though it doesn't contain the Maxmind data.

Now you're ready to run "make"
(note that the download\_databases script may have done that for you,
but you'll want to check).

See the comment at the start of createdatabase.PL for further reading.

# MORE INFORMATION

I've written a few Perl related Genealogy programs including gedcom ([https://github.com/nigelhorne/gedcom](https://github.com/nigelhorne/gedcom))
and ged2site ([https://github.com/nigelhorne/ged2site](https://github.com/nigelhorne/ged2site)).
One of the things that these do is to check the validity of your family tree, and one of those tasks is to verify place-names.
Of course places do change names and spelling becomes more consistent over the years, but the vast majority remain the same.
Enough of a majority to computerise the verification.
Unfortunately all of the on-line services have one problem or another - most either charge for large number of access, or throttle the number of look-ups.
Even my modest tree, just over 2000 people, reaches those limits.

There are, however, a number of free databases that can be used, including MaxMind, GeoNames, OpenAddresses and WhosOnFirst.
The objective of [Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree) ([https://github.com/nigelhorne/Geo-Coder-Free](https://github.com/nigelhorne/Geo-Coder-Free))
is to create a database of those databases and to create a search engine either through a local copy of the database or through an on-line website.
Both are in their early days, but I have examples which do surprisingly well.

The local copy of the database is built using the createdatabase.PL script which is bundled with G:C:F.
That script creates a single SQLite file from downloaded copies of the databases listed above, to create the database you will need
to first install [App::csv2sqlite](https://metacpan.org/pod/App%3A%3Acsv2sqlite).
If REDIS\_SERVER is set, the data are also stored on a Redis Server.
Running 'make' will download GeoNames and MaxMind, but OpenAddresses and WhosOnFirst need to be downloaded manually if you decide to use them - they are treated as optional by G:C:F.

The sample website at [https://geocode.nigelhorne.com/](https://geocode.nigelhorne.com/) is down at the moment while I look for a new host.
The source code for that site is included in the G:C:F distribution.

# BUGS

Some lookups fail at the moments, if you find one please file a bug report.

The MaxMind data only contains cities.
The OpenAddresses data doesn't cover the globe.

Can't parse and handle "London, England".

It would be great to have a set-up wizard to create the database.

The various scripts in NJH-Snippets ought to be in this module.

# SEE ALSO

[https://openaddresses.io/](https://openaddresses.io/),
[https://www.maxmind.com/en/home](https://www.maxmind.com/en/home),
[https://www.geonames.org/](https://www.geonames.org/),
[https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/countries%2Bstates%2Bcities.json](https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/countries%2Bstates%2Bcities.json),
[https://www.whosonfirst.org/](https://www.whosonfirst.org/) and
[https://github.com/nigelhorne/vwf](https://github.com/nigelhorne/vwf).

[Geo::Coder::Free::Local](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3ALocal),
[Geo::Coder::Free::Maxmind](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AMaxmind),
[Geo::Coder::Free::OpenAddresses](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AOpenAddresses).

See [Geo::Coder::Free::OpenAddresses](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AOpenAddresses) for instructions creating the SQLite database from
[http://results.openaddresses.io/](http://results.openaddresses.io/).

# AUTHOR

Nigel Horne, `<njh@bandsman.co.uk>`

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Free

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Geo-Coder-Free](https://metacpan.org/release/Geo-Coder-Free)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Free](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Free)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Geo-Coder-Free](http://cpants.cpanauthors.org/dist/Geo-Coder-Free)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Geo-Coder-Free](http://matrix.cpantesters.org/?dist=Geo-Coder-Free)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Geo::Coder::Free](http://deps.cpantesters.org/?module=Geo::Coder::Free)

- Search CPAN

    [http://search.cpan.org/dist/Geo-Coder-Free/](http://search.cpan.org/dist/Geo-Coder-Free/)

# LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at \`&lt;njh at nigelhorne.com>\`.

This product uses GeoLite2 data created by MaxMind, available from
[https://www.maxmind.com/en/home](https://www.maxmind.com/en/home). See their website for licensing information.

This product uses data from Who's on First.
See [https://github.com/whosonfirst-data/whosonfirst-data/blob/master/LICENSE.md](https://github.com/whosonfirst-data/whosonfirst-data/blob/master/LICENSE.md) for licensing information.
