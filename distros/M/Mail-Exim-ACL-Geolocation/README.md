# Mail::Exim::ACL::Geolocation

A Perl module for the [Exim](https://www.exim.org/) mailer that maps IP
addresses to geolocation information such as country codes and Autonomous
Systems.  Spam filters can use this information to filter junk email.

    acl_check_rcpt:

      warn
        domains = +local_domains : +relay_to_domains

        set acl_m_country_code = ${perl{country_code}{$sender_host_address}}
        add_header = X-Sender-Host-Country: $acl_m_country_code

        set acl_m_asn = ${perl{asn_lookup}{$sender_host_address}}
        add_header = X-Sender-Host-ASN: $acl_m_asn

## DEPENDENCIES

Requires the Perl module IP::Geolocation::MMDB from CPAN.

Requires geolocation databases in the MaxMind DB file format from
[MaxMind](https://www.maxmind.com) or [DP-IP.com](https://db-ip.com/).  The
module searches the directories "/var/lib/GeoIP", "/usr/local/share/GeoIP",
"/usr/share/GeoIP", "/opt/share/GeoIP" and "/var/db/GeoIP" for the
following database files:

* GeoIP2-Country.mmdb
* GeoIP2-City.mmdb
* dbip-country.mmdb
* dbip-city.mmdb
* GeoLite2-Country.mmdb
* GeoLite2-City.mmdb
* dbip-country-lite.mmdb
* dbip-city-lite.mmdb

* GeoIP2-ASN.mmdb
* dbip-asn.mmdb
* GeoLite2-ASN.mmdb
* dbip-asn-lite.mmdb

## INSTALLATION

Run the following commands to install the software:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc Mail::Exim::ACL::Geolocation

## LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
