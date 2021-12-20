# Mail::Exim::Blacklist::GeoIP

A Perl module for the [Exim](https://www.exim.org/) mailer that maps IP
addresses to two-letter country codes such as "DE", "FR" and "US".
SpamAssassin can use these country codes to filter junk e-mail.

    acl_check_rcpt:

      warn
        domains = +local_domains : +relay_to_domains
        set acl_m_country_code = ${perl{geoip_country_code}{$sender_host_address}}
        add_header = X-Sender-Host-Country: $acl_m_country_code

      accept

## DEPENDENCIES

Requires the Perl module MaxMind::DB::Reader from CPAN and the modules
Exporter and List::Util, which are distributed with Perl.

Requires an IP to country database in the MMDB format from
[DP-IP.com](https://db-ip.com/) or [MaxMind](https://www.maxmind.com).  The
module searches the directories "/var/lib/GeoIP" and "/usr/share/GeoIP" for
one of the following database files:

* dbip-country.mmdb
* GeoIP2-Country.mmdb
* dbip-country-lite.mmdb
* GeoLite2-Country.mmdb

## INSTALLATION

The [Open Build Service](https://build.opensuse.org/package/show/home:voegelas/perl-Mail-Exim-Blacklist-GeoIP)
provides binary and source packages.

Run the following commands to install the software manually:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc Mail::Exim::Blacklist::GeoIP

## LICENSE AND COPYRIGHT

Copyright 2021 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
