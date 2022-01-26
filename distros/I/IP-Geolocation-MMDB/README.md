# IP::Geolocation::MMDB

A Perl module that reads MaxMind DB files and maps IP addresses to location
information such as country and city names.

    use IP::Geolocation::MMDB;
    my $db = IP::Geolocation::MMDB->new(file => 'Country.mmdb');
    my $metadata = $db->metadata;
    my $data = $db->record_for_address('1.2.3.4');
    my $country_code = $db->getcc('2620:fe::9');

## DEPENDENCIES

Requires Alien::libmaxminddb from CPAN.  Requires Math::BigInt version
1.999806, which is distributed with Perl 5.26 and newer.

Requires libmaxminddb 1.2.0 or newer.

Requires an IP to country, city or ASN database in the MaxMind DB file format
from [MaxMind](https://www.maxmind.com/) or [DP-IP.com](https://db-ip.com/).

Windows is not supported.  Please do not ask for Windows support.

## INSTALLATION

Run the following commands to install the software:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc IP::Geolocation::MMDB

## LICENSE AND COPYRIGHT

Copyright 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
