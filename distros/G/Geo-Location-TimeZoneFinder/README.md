# Geo::Location::TimeZoneFinder

A Perl module that maps geographic coordinates to time zone names such as
"Asia/Shanghai".  The module uses database files that are published by the
Timezone Boundary Builder project.

    use Geo::Location::TimeZoneFinder;
    my $finder = Geo::Location::TimeZoneFinder->new(file_base => 'shapefile');
    my @time_zones = $finder->time_zones_at(lat => $lat, lon => $lon);

## DEPENDENCIES

Requires the file "timezones.shapefile.zip" from the [Timezone Boundary
Builder](https://github.com/evansiroky/timezone-boundary-builder) project.
The zip archive must be extracted to a directory.

## INSTALLATION

Run the following commands to install the software:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc Geo::Location::TimeZoneFinder

## LICENSE AND COPYRIGHT

Copyright (C) 2023 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
