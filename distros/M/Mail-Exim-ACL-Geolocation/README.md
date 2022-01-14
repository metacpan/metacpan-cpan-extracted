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
[DP-IP.com](https://db-ip.com/) or [MaxMind](https://www.maxmind.com).  The
module searches the directories "/var/lib/GeoIP" and "/usr/share/GeoIP" for one
of the following database files:

* dbip-country.mmdb
* GeoIP2-Country.mmdb
* dbip-location.mmdb
* GeoIP2-City.mmdb
* dbip-country-lite.mmdb
* GeoLite2-Country.mmdb
* dbip-city-lite.mmdb
* GeoLite2-City.mmdb

## INSTALLATION

The [Open Build Service](https://build.opensuse.org/package/show/home:voegelas/perl-Mail-Exim-ACL-Geolocation)
provides binary and source packages.

Run the following commands to install the software manually:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc Mail::Exim::ACL::Geolocation

## LICENSE AND COPYRIGHT

Copyright 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
