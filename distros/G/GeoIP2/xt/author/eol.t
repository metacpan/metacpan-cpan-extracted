use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/web-service-request',
    'lib/GeoIP2.pm',
    'lib/GeoIP2/Database/Reader.pm',
    'lib/GeoIP2/Error/Generic.pm',
    'lib/GeoIP2/Error/HTTP.pm',
    'lib/GeoIP2/Error/IPAddressNotFound.pm',
    'lib/GeoIP2/Error/Type.pm',
    'lib/GeoIP2/Error/WebService.pm',
    'lib/GeoIP2/Model/ASN.pm',
    'lib/GeoIP2/Model/AnonymousIP.pm',
    'lib/GeoIP2/Model/City.pm',
    'lib/GeoIP2/Model/ConnectionType.pm',
    'lib/GeoIP2/Model/Country.pm',
    'lib/GeoIP2/Model/Domain.pm',
    'lib/GeoIP2/Model/Enterprise.pm',
    'lib/GeoIP2/Model/ISP.pm',
    'lib/GeoIP2/Model/Insights.pm',
    'lib/GeoIP2/Record/City.pm',
    'lib/GeoIP2/Record/Continent.pm',
    'lib/GeoIP2/Record/Country.pm',
    'lib/GeoIP2/Record/Location.pm',
    'lib/GeoIP2/Record/MaxMind.pm',
    'lib/GeoIP2/Record/Postal.pm',
    'lib/GeoIP2/Record/RepresentedCountry.pm',
    'lib/GeoIP2/Record/Subdivision.pm',
    'lib/GeoIP2/Record/Traits.pm',
    'lib/GeoIP2/Role/Error/HTTP.pm',
    'lib/GeoIP2/Role/HasIPAddress.pm',
    'lib/GeoIP2/Role/HasLocales.pm',
    'lib/GeoIP2/Role/Model.pm',
    'lib/GeoIP2/Role/Model/Flat.pm',
    'lib/GeoIP2/Role/Model/HasSubdivisions.pm',
    'lib/GeoIP2/Role/Model/Location.pm',
    'lib/GeoIP2/Role/Record/Country.pm',
    'lib/GeoIP2/Role/Record/HasNames.pm',
    'lib/GeoIP2/Types.pm',
    'lib/GeoIP2/WebService/Client.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/GeoIP2/Database/Reader-ASN.t',
    't/GeoIP2/Database/Reader-Anonymous-IP.t',
    't/GeoIP2/Database/Reader-Connection-Type.t',
    't/GeoIP2/Database/Reader-Domain.t',
    't/GeoIP2/Database/Reader-Enterprise.t',
    't/GeoIP2/Database/Reader-ISP.t',
    't/GeoIP2/Database/Reader.t',
    't/GeoIP2/Error/Type.t',
    't/GeoIP2/Model/City.t',
    't/GeoIP2/Model/Country.t',
    't/GeoIP2/Model/Insights.t',
    't/GeoIP2/Model/names.t',
    't/GeoIP2/Types.t',
    't/GeoIP2/WebService/Client.t',
    't/lib/Test/GeoIP2.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
