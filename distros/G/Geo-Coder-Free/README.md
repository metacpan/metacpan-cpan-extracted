# Geo::Coder::Free

Provides a geocoding functionality using free databases of towns

# VERSION

Version 0.03

# SYNOPSIS

      use Geo::Coder::Free;

      my $geocoder = Geo::Coder::Free->new();
      my $location = $geocoder->geocode(location => 'Ramsgate, Kent, UK');

# DESCRIPTION

Geo::Coder::Free provides an interface to free databases.

Refer to the source URL for licencing information for these files
cities.csv is from https://www.maxmind.com/en/free-world-cities-database
admin1.db is from http://download.geonames.org/export/dump/admin1CodesASCII.txt
admin2.db is from http://download.geonames.org/export/dump/admin2Codes.txt

See also http://download.geonames.org/export/dump/allCountries.zip

To significantly speed this up, gunzip cities.csv and run it through the db2sql script to create an SQLite file.

# METHODS

## new

    $geocoder = Geo::Coder::Free->new();

## geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

    # TODO:
    # @locations = $geocoder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);
        

## reverse\_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

To be done.

## ua

Does nothing, here for compatibility with other geocoders

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# BUGS

Lots of lookups fail at the moment.

# SEE ALSO

VWF, Maxmind and geonames.

# LICENSE AND COPYRIGHT

Copyright 2017 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at \`&lt;njh at nigelhorne.com>\`.
