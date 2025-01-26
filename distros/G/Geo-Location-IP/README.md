# Geo::Location::IP

Perl modules that map IP addresses to location information such as country and
city names.

    use Geo::Location::IP::Database::Reader;
    my $reader = Geo::Location::IP::Database::Reader->new(
      file    => '/path/to/City.mmdb',
      locales => ['de', 'en'],
    );
    eval {
      my $city_model = $reader->city(ip => '1.2.3.4');
      my $city       = $city_model->city;
      my $country    = $city_model->country;
      printf "%s in %s\n", $city->name, $country->name;
    };

## DEPENDENCIES

Requires Perl 5.026 and the modules IP::Geolocation::MMDB and Object::Pad from
CPAN.

Requires databases in the MaxMind DB file format from
[MaxMind](https://www.maxmind.com) or [DP-IP.com](https://db-ip.com/).

## INSTALLATION

Run the following commands to install the software:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc Geo::Location::IP

## LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
