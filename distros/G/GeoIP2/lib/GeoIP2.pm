package GeoIP2;

use 5.008;
use strict;
use warnings;

our $VERSION = '2.006002';

1;

# ABSTRACT: Perl API for MaxMind's GeoIP2 web services and databases

__END__

=pod

=encoding UTF-8

=head1 NAME

GeoIP2 - Perl API for MaxMind's GeoIP2 web services and databases

=head1 VERSION

version 2.006002

=head1 DESCRIPTION

This distribution provides an API for the GeoIP2
L<web services|http://dev.maxmind.com/geoip/geoip2/web-services> and
L<databases|http://dev.maxmind.com/geoip/geoip2/downloadable>. The API also
works with the free
L<GeoLite2 databases|http://dev.maxmind.com/geoip/geoip2/geolite2/>.

See L<GeoIP2::WebService::Client> for details on the web service client API
and L<GeoIP2::Database::Reader> for the database API.

=head1 SPEEDING UP DATABASE READING

This module only depends on the pure Perl implementation of the MaxMind
database reader (L<MaxMind::DB::Reader>). If you install the libmaxminddb
library (L<http://maxmind.github.io/libmaxminddb/>) and
L<MaxMind::DB::Reader::XS>, then the XS implementation will be loaded
automatically. The XS implementation is approximately 100x faster than the
pure Perl implementation.

=head1 VALUES TO USE FOR DATABASE OR HASH KEYS

B<We strongly discourage you from using a value from any C<names> accessor as
a key in a database or hash.>

These names may change between releases. Instead we recommend using one of the
following:

=over 4

=item * L<GeoIP2::Record::City> - C<< $city->geoname_id >>

=item * L<GeoIP2::Record::Continent> - C<< $continent->code >> or C<< $continent->geoname_id >>

=item * L<GeoIP2::Record::Country> and L<GeoIP2::Record::RepresentedCountry> - C<< $country->iso_code >> or C<< $country->geoname_id >>

=item * L<GeoIP2::Record::Subdivision> - C<< $subdivision->iso_code >> or C<< $subdivision->geoname_id >>

=back

=head1 INTEGRATION WITH GEONAMES

GeoNames (L<http://www.geonames.org/>) offers web services and downloadable
databases with data on geographical features around the world, including
populated places. They offer both free and paid premium data. Each feature is
uniquely identified by a C<geoname_id>, which is an integer.

Many of the records returned by the GeoIP web services and databases include a
C<geoname_id> field. This is the ID of a geographical feature (city, region,
country, etc.) in the GeoNames database.

Some of the data that MaxMind provides is also sourced from GeoNames. We
source data such as place names, ISO codes, and other similar data from the
GeoNames premium data set.

=head1 REPORTING DATA PROBLEMS

If the problem you find is that an IP address is incorrectly mapped, please
submit your correction to MaxMind at L<http://www.maxmind.com/en/correction>.

If you find some other sort of mistake, like an incorrect spelling, please
check the GeoNames site (L<http://www.geonames.org/>) first. Once you've searched
for a place and found it on the GeoNames map view, there are a number of links
you can use to correct data ("move", "edit", "alternate names", etc.). Once
the correction is part of the GeoNames data set, it will be automatically
incorporated into future MaxMind releases.

If you are a paying MaxMind customer and you're not sure where to submit a
correction, please contact MaxMind support at for help. See
L<http://www.maxmind.com/en/support> for support details.

=head1 VERSIONING POLICY

This module uses semantic versioning as described by
L<http://semver.org/>. Version numbers can be read as X.YYYZZZ, where X is the
major number, YYY is the minor number, and ZZZ is the patch number.

=head1 PERL VERSION SUPPORT

This API supports Perl 5.10 and above.

The data returned from the GeoIP2 web services includes Unicode characters in
several locales. This may expose bugs in earlier versions of Perl. If Unicode
support is important to you, we recommend that you use the most recent version
of Perl available.

=head1 SUPPORT

This module is deprecated and will only receive fixes for major bugs and
security vulnerabilities. New features and functionality will not be added.

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/GeoIP2-perl/issues>.

If you are having an issue with a MaxMind service that is not specific to the
client API please see L<http://www.maxmind.com/en/support> for details.

Bugs may be submitted through L<https://github.com/maxmind/GeoIP2-perl/issues>.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Greg Oschwald <goschwald@maxmind.com>

=item *

Mark Fowler <mfowler@maxmind.com>

=item *

Olaf Alders <oalders@maxmind.com>

=back

=head1 CONTRIBUTORS

=for stopwords Adam Lapczynski Andy Jack E. Choroba Florian Ragwitz Graham Knop Mateu X Hunter Michael F. Canzoneri Narsimham Chelluri Patrick Cronin William Storey

=over 4

=item *

Adam Lapczynski <alapczynski@maxmind.com>

=item *

Andy Jack <github@veracity.ca>

=item *

E. Choroba <choroba@matfyz.cz>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Graham Knop <haarg@haarg.org>

=item *

Mateu X Hunter <mhunter@maxmind.com>

=item *

Michael F. Canzoneri <mikecanzoneri@gmail.com>

=item *

Narsimham Chelluri <nchelluri@maxmind.com>

=item *

Narsimham Chelluri <nchelluri@users.noreply.github.com>

=item *

Patrick Cronin <PatrickCronin@users.noreply.github.com>

=item *

William Storey <wstorey@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
