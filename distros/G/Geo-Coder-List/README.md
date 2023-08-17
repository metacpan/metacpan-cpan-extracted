[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-List.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-List)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/naayd09612e10llw/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-list/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/Geo-Coder-List/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Geo-Coder-List?branch=master)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-List.svg)](https://metacpan.org/release/Geo-Coder-List)

# NAME

Geo::Coder::List - Call many Geo-Coders

# VERSION

Version 0.31

# SYNOPSIS

[Geo::Coder::All](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AAll)
and
[Geo::Coder::Many](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AMany)
are great routines but neither quite does what I want.
This module's primary use is to allow many backends to be used by
[HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3)

# SUBROUTINES/METHODS

## new

Creates a Geo::Coder::List object.

Takes an optional argument 'cache' which takes an cache object that supports
get() and set() methods.
Takes an optional argument 'debug',
the higher the number,
the more debugging.
The licences of some geo coders,
such as Google,
specifically prohibit caching API calls,
so be careful to only use with those services that allow it.

    use Geo::Coder::List;
    use CHI;

    my $geocoder->new(cache => CHI->new(driver => 'Memory', global => 1));

## push

Add an encoder to list of encoders.

    use Geo::Coder::List;
    use Geo::Coder::GooglePlaces;
    # ...
    my $list = Geo::Coder::List->new()->push(Geo::Coder::GooglePlaces->new());

Different encoders can be preferred for different locations.
For example this code uses geocode.ca for Canada and US addresses,
and OpenStreetMap for other places:

    my $geo_coderlist = Geo::Coder::List->new()
        ->push({ regex => qr/(Canada|USA|United States)$/, geocoder => Geo::Coder::CA->new() })
        ->push(Geo::Coder::OSM->new());

    # Uses Geo::Coder::CA, and if that fails uses Geo::Coder::OSM
    my $location = $geo_coderlist->geocode(location => '1600 Pennsylvania Ave NW, Washington DC, USA');
    # Only uses Geo::Coder::OSM
    if($location = $geo_coderlist->geocode('10 Downing St, London, UK')) {
        print 'The prime minister lives at co-ordinates ',
            $location->{geometry}{location}{lat}, ',',
            $location->{geometry}{location}{lng}, "\n";
    }

    # It is also possible to limit the number of enquires used by a particular encoder
    $geo_coderlist->push({ geocoder => Geo::Coder::GooglePlaces->new(key => '1234'), limit => 100) });

## geocode

Runs geocode on all of the loaded drivers.
See [Geo::Coder::GooglePlaces::V3](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces%3A%3AV3) for an explanation.

The name of the Geo-Coder that gave the result is put into the geocode element of the
return value,
if the value was retrieved from the cache the value will be undefined.

    if(defined($location->{'geocoder'})) {
        print 'Location information retrieved using ', $location->{'geocoder'}, "\n";
    }

## ua

Accessor method to set the UserAgent object used internally by each of the Geo-Coders.
You can call _env\_proxy_,
for example,
to set the proxy information from environment variables:

    my $geocoder_list = Geo::Coder::List->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoder_list->ua($ua);

Note that unlike Geo::Coders there is no read method since that would be pointless.

## reverse\_geocode

Similar to geocode except it expects a latitude/longitude parameter.

    print $geocoder_list->reverse_geocode(latlng => '37.778907,-122.39732');

## log

Returns the log of events to help you debug failures,
optimize lookup order and fix quota breakage.

    my @log = @{$geocoderlist->log()};

## flush

Clear the log.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-geo-coder-list at rt.cpan.org`,
or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

reverse\_geocode() doesn't update the logger.
reverse\_geocode() should support [Geo::Location::Point](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APoint) objects.

# SEE ALSO

[Geo::Coder::All](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AAll)
[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces)
[Geo::Coder::Many](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AMany)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::List

You can also look for information at:

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-List](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-List)

- MetaCPAN

    [https://metacpan.org/release/Geo-Coder-List](https://metacpan.org/release/Geo-Coder-List)

# LICENSE AND COPYRIGHT

Copyright 2016-2023 Nigel Horne.

This program is released under the following licence: GPL2
