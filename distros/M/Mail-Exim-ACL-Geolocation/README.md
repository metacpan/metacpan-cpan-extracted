# Mail::Exim::ACL::Geolocation

A Perl module for the [Exim](https://www.exim.org/) mailer that maps IP
addresses to two-letter country codes such as "DE", "FR" and "US".
SpamAssassin can use these country codes to filter junk email.

    acl_check_rcpt:

      warn
        domains = +local_domains : +relay_to_domains
        set acl_m_country_code = ${perl{country_code}{$sender_host_address}}
        add_header = X-Sender-Host-Country: $acl_m_country_code

## DEPENDENCIES

Requires the Perl module IP::Geolocation::MMDB from CPAN and the modules
Exporter and List::Util, which are distributed with Perl.

Requires an IP to country database in the MaxMind DB file format from
[MaxMind](https://www.maxmind.com) or [DP-IP.com](https://db-ip.com/).  The
module searches the directories "/var/lib/GeoIP", "/usr/local/share/GeoIP",
"/usr/share/GeoIP" and "/opt/share/GeoIP" for one of the following database
files:

* GeoIP2-Country.mmdb
* GeoIP2-City.mmdb
* dbip-country.mmdb
* dbip-city.mmdb
* dbip-location.mmdb
* GeoLite2-Country.mmdb
* GeoLite2-City.mmdb
* dbip-country-lite.mmdb
* dbip-city-lite.mmdb

## INSTALLATION

Run the following commands to install the software:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc Mail::Exim::ACL::Geolocation

## LICENSE AND COPYRIGHT

Copyright (C) 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
