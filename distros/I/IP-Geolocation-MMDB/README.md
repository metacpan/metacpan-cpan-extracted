# IP::Geolocation::MMDB

A Perl module that reads MaxMind DB files and maps IP addresses to two-letter
country codes such as "DE", "FR" and "US".

    use IP::Geolocation::MMDB;
    my $db = IP::Geolocation::MMDB->new(file => 'GeoIP2-Country.mmdb');
    my $lookup_result = $db->record_for_address('1.2.3.4');
    my $country_code = $db->getcc('2620:fe::9');

## DEPENDENCIES

Requires Alien::libmaxminddb from CPAN.  On Windows, Alien::MSYS needs to be
installed.

Requires an IP to country database in the MaxMind DB file format from
[DP-IP.com](https://db-ip.com/) or [MaxMind](https://www.maxmind.com/).

## INSTALLATION

The [Open Build Service](https://build.opensuse.org/package/show/home:voegelas/perl-IP-Geolocation-MMDB)
provides binary and source packages.

Run the following commands to install the software manually:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc IP::Geolocation::MMDB

## LICENSE AND COPYRIGHT

Copyright 2021 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
