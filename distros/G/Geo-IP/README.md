# NAME

Geo::IP - Look up location and network information by IP Address

# VERSION

version 1.50

# SYNOPSIS

    use Geo::IP;
    my $gi = Geo::IP->new(GEOIP_MEMORY_CACHE);
    # look up IP address '24.24.24.24'
    # returns undef if country is unallocated, or not defined in our database
    my $country = $gi->country_code_by_addr('24.24.24.24');
    $country = $gi->country_code_by_name('yahoo.com');
    # $country is equal to "US"


    use Geo::IP;
    my $gi = Geo::IP->open("/usr/local/share/GeoIP/GeoIPCity.dat", GEOIP_STANDARD);
    my $record = $gi->record_by_addr('24.24.24.24');
    print $record->country_code,
          $record->country_code3,
          $record->country_name,
          $record->region,
          $record->region_name,
          $record->city,
          $record->postal_code,
          $record->latitude,
          $record->longitude,
          $record->time_zone,
          $record->area_code,
          $record->continent_code,
          $record->metro_code;


    # the IPv6 support is currently only avail if you use the CAPI which is much
    # faster anyway. ie: print Geo::IP->api equals to 'CAPI'
    use Socket;
    use Socket6;
    use Geo::IP;
    my $g = Geo::IP->open('/usr/local/share/GeoIP/GeoIPv6.dat') or die;
    print $g->country_code_by_ipnum_v6(inet_pton AF_INET6, '::24.24.24.24');
    print $g->country_code_by_addr_v6('2a02:e88::');

# DESCRIPTION

This module uses the GeoIP Legacy file based database.  This database simply
contains IP blocks as keys, and countries as values. This database should be
more complete and accurate than reverse DNS lookups.

This module can be used to automatically select the geographically closest
mirror, to analyze your web server logs to determine the countries of your
visitors, for credit card fraud detection, and for software export controls.

# IP GEOLOCATION USAGE

IP geolocation is inherently imprecise. Locations are often near the center of
the population. Any location provided by a GeoIP database or web service
should not be used to identify a particular address or household.

# IP ADDRESS TO COUNTRY DATABASES

Free monthly updates to the database are available from

    http://dev.maxmind.com/geoip/geolite

This free database is similar to the database contained in IP::Country, as
well as many paid databases. It uses ARIN, RIPE, APNIC, and LACNIC whois to
obtain the IP->Country mappings.

If you require greater accuracy, MaxMind offers a database on a paid
subscription basis.  Also included with this is a service that updates your
database automatically each month, by running a program called geoipupdate
included with the C API from a cronjob.  For more details on the differences
between the free and paid databases, see:

http://www.maxmind.com/en/geolocation\_landing

Do not miss the city database, described in Geo::IP::Record

Make sure to use the `geolite-mirror-simple.pl` script from the example directory to
stay current with the databases.

# BENCHMARK the lookups are fast. This is my laptop ( examples/benchmark.pl ):

    Benchmark: running city_mem, city_std, country_mem, country_std, country_v6_mem, country_v6_std, isp_mem, isp_std for at least 10 CPU seconds...
      city_mem: 10.3121 wallclock secs (10.30 usr +  0.01 sys = 10.31 CPU) @ 387271.48/s (n=3992769)
      city_std: 10.0658 wallclock secs ( 2.86 usr +  7.17 sys = 10.03 CPU) @ 54392.62/s (n=545558)
    country_mem: 10.1772 wallclock secs (10.16 usr +  0.00 sys = 10.16 CPU) @ 1077507.97/s (n=10947481)
    country_std: 10.1432 wallclock secs ( 2.30 usr +  7.85 sys = 10.15 CPU) @ 83629.56/s (n=848840)
    country_v6_mem: 10.2579 wallclock secs (10.25 usr + -0.00 sys = 10.25 CPU) @ 365997.37/s (n=3751473)
    country_v6_std: 10.8541 wallclock secs ( 1.77 usr +  9.07 sys = 10.84 CPU) @ 10110.42/s (n=109597)
       isp_mem: 10.147 wallclock secs (10.13 usr +  0.01 sys = 10.14 CPU) @ 590109.66/s (n=5983712)
       isp_std: 10.0484 wallclock secs ( 2.71 usr +  7.33 sys = 10.04 CPU) @ 73186.35/s (n=734791)

# CLASS METHODS

- $gi = Geo::IP->new( $flags );

    Constructs a new Geo::IP object with the default database located inside your system's
    _datadir_, typically _/usr/local/share/GeoIP/GeoIP.dat_.

    Flags can be set to either GEOIP\_STANDARD, or for faster performance (at a
    cost of using more memory), GEOIP\_MEMORY\_CACHE. When using memory cache you
    can force a reload if the file is updated by setting GEOIP\_CHECK\_CACHE.
    GEOIP\_INDEX\_CACHE caches the most frequently accessed index portion of the
    database, resulting in faster lookups than GEOIP\_STANDARD, but less memory
    usage than GEOIP\_MEMORY\_CACHE - useful for larger databases such as GeoIP
    Legacy Organization and GeoIP City. Note, for GeoIP Country, Region and
    Netspeed databases, GEOIP\_INDEX\_CACHE is equivalent to GEOIP\_MEMORY\_CACHE.

    Prior to geoip-api version 1.6.3, the C API would leak diagnostic messages
    onto stderr unconditionally. From Geo::IP v1.44 onwards, the flag
    squelching this behavior (GEOIP\_SILENCE) is implicitly added to the flags
    passed in new(), open(), and open\_type().

    To combine flags, use the bitwise OR operator, |.  For example, to cache the
    database in memory, but check for an updated GeoIP.dat file, use:
    Geo::IP->new( GEOIP\_MEMORY\_CACHE | GEOIP\_CHECK\_CACHE );

- $gi = Geo::IP->open( $database\_filename, $flags );

    Constructs a new Geo::IP object with the database located at `$database_filename`.

- $gi = Geo::IP->open\_type( $database\_type, $flags );

    Constructs a new Geo::IP object with the $database\_type database located in
    the standard location.  For example

        $gi = Geo::IP->open_type( GEOIP_CITY_EDITION_REV1 , GEOIP_STANDARD );

    opens the database file in the standard location for GeoIP Legacy City,
    typically _/usr/local/share/GeoIP/GeoIPCity.dat_.

# OBJECT METHODS

- $code = $gi->country\_code\_by\_addr( $ipaddr );

    Returns the ISO 3166 country code for an IP address.

- $code = $gi->country\_code\_by\_name( $hostname );

    Returns the ISO 3166 country code for a hostname.

- $code = $gi->country\_code3\_by\_addr( $ipaddr );

    Returns the 3 letter country code for an IP address.

- $code = $gi->country\_code3\_by\_name( $hostname );

    Returns the 3 letter country code for a hostname.

- $name = $gi->country\_name\_by\_addr( $ipaddr );

    Returns the full country name for an IP address.

- $name = $gi->country\_name\_by\_name( $hostname );

    Returns the full country name for a hostname.

- $r = $gi->record\_by\_addr( $ipaddr );

    Returns a Geo::IP::Record object containing city location for an IP address.

- $r = $gi->record\_by\_name( $hostname );

    Returns a Geo::IP::Record object containing city location for a hostname.

- $org = $gi->org\_by\_addr( $ipaddr ); **deprecated** use `name_by_addr` instead.

    Returns the Organization, ISP name or Domain Name for an IP address.

- $org = $gi->org\_by\_name( $hostname );  **deprecated** use `name_by_name` instead.

    Returns the Organization, ISP name or Domain Name for a hostname.

- $info = $gi->database\_info;

    Returns database string, includes version, date, build number and copyright notice.

- $old\_charset = $gi->set\_charset( $charset );

    Set the charset for the city name - defaults to GEOIP\_CHARSET\_ISO\_8859\_1.  To
    set UTF8, pass GEOIP\_CHARSET\_UTF8 to set\_charset.
    For perl >= 5.008 the utf8 flag is honored.

- $charset = $gi->charset;

    Gets the currently used charset.

- ( $country, $region ) = $gi->region\_by\_addr('24.24.24.24');

    Returns a list containing country and region. If region and/or country is
    unknown, undef is returned. Sure this works only for region databases.

- ( $country, $region ) = $gi->region\_by\_name('www.xyz.com');

    Returns a list containing country and region. If region and/or country is
    unknown, undef is returned. Sure this works only for region databases.

- $netmask = $gi->last\_netmask;

    Gets netmask of network block from last lookup.

- $gi->netmask(12);

    Sets netmask for the last lookup

- my ( $from, $to ) = $gi->range\_by\_ip('24.24.24.24');

    Returns the start and end of the current network block. The method tries to join several continuous netblocks.

- $api = $gi->api or $api = Geo::IP->api

    Returns the currently used API.

        # prints either CAPI or PurePerl
        print Geo::IP->api;

- $continent = $gi->continent\_code\_by\_country\_code('US');

    Returns the continent code by country code.

- $dbe = $gi->database\_edition

    Returns the database\_edition of the currently opened database.

        if ( $gi->database_edition == GEOIP_COUNTRY_EDITION ){
          ...
        }

- $isp = $gi->isp\_by\_addr('24.24.24.24');

    Returns the isp for 24.24.24.24

- $isp = $gi->isp\_by\_name('www.maxmind.com');

    Returns the isp for www.something.de

- my $time\_zone = $gi->time\_zone('US', 'AZ');

    Returns the time zone for country/region.

        # undef
        print  $gi->time_zone('US', '');

        # America/Phoenix
        print  $gi->time_zone('US', 'AZ');

        # Europe/Berlin
        print  $gi->time_zone('DE', '00');

        # Europe/Berlin
        print  $gi->time_zone('DE', '');

- $id = $gi->id\_by\_addr('24.24.24.24');

    Returns the country\_id for 24.24.24.24. The country\_id might be useful as array
    index. 0 is unknown.

- $id = $gi->id\_by\_name('www.maxmind.com');

    Returns the country\_id for www.maxmind.com. The country\_id might be useful as array
    index. 0 is unknown.

- $cc = $gi->country\_code3\_by\_addr\_v6('::24.24.24.24');
- $cc = $gi->country\_code3\_by\_name\_v6('ipv6.google.com');
- $cc = $gi->country\_code\_by\_addr\_v6('2a02:ea0::');
- $cc = $gi->country\_code\_by\_ipnum\_v6($ipnum);

        use Socket;
        use Socket6;
        use Geo::IP;
        my $g = Geo::IP->open('/usr/local/share/GeoIP/GeoIPv6.dat') or die;
        print $g->country_code_by_ipnum_v6(inet_pton AF_INET6, '::24.24.24.24');

- $cc = $gi->country\_code\_by\_name\_v6('ipv6.google.com');
- name\_by\_addr

    Returns the Organization, ISP name or Domain Name for a IP address.

- name\_by\_addr\_v6

    Returns the Organization, ISP name or Domain Name for an IPv6 address.

- name\_by\_ipnum\_v6

    Returns the Organization, ISP name or Domain Name for an ipnum.

- name\_by\_name

    Returns the Organization, ISP name or Domain Name for a hostname.

- name\_by\_name\_v6

    Returns the Organization, ISP name or Domain Name for a hostname.

- org\_by\_addr\_v6 **deprecated** use `name_by_addr_v6`

    Returns the Organization, ISP name or Domain Name for an IPv6 address.

- org\_by\_name\_v6  **deprecated** use `name_by_name_v6`

    Returns the Organization, ISP name or Domain Name for a hostname.

- teredo

    Returns the current setting for teredo.

- enable\_teredo

    Enable / disable teredo

        $gi->enable_teredo(1); # enable
        $gi->enable_teredo(0); # disable

- lib\_version

        if ( $gi->api eq 'CAPI' ){
            print $gi->lib_version;
        }

# ISSUE TRACKER AND GIT repo

Is available from GitHub, see

https://github.com/maxmind/geoip-api-perl

# SEE ALSO

[GeoIP2](https://metacpan.org/pod/GeoIP2) - database reader for the GeoIP2 format.

# AUTHORS

- Dave Rolsky <drolsky@maxmind.com>
- Greg Oschwald <goschwald@maxmind.com>

# CONTRIBUTORS

- asb-cpan <asb-cpan@users.noreply.github.com>
- Boris Zentner <bzentner@maxmind.com>
- Boris Zentner <bzm@2bz.de>
- John SJ Anderson <genehack@genehack.org>
- Olaf Alders <oalders@maxmind.com>
- Philip A. Prindeville <philipp@redfish-solutions.com>
- shawniverson <shawniverson@gmail.com>
- Thomas J Mather <tjmather@maxmind.com>
- Tina Mueller <TINITA@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
