use strict;
use warnings;

use Geo::IP;

use Test::More;

for my $method (qw( org_by_addr isp_by_addr name_by_addr )) {
    subtest $method => sub {
        my $gi = Geo::IP->open( 't/data/GeoIPOrg.dat', GEOIP_STANDARD );

        is(
            $gi->$method('12.87.118.0'), 'AT&T Worldnet Services',
            'expected org'
        );
    };

    # There isn't an isp_by_addr_v6 method
    next if $method eq 'isp_by_addr';

    # We don't support v6 lookups with the pure Perl API on older Perls
    next if Geo::IP->api eq 'PurePerl' and $] < 5.014;

    my $v6_method = $method . '_v6';
    subtest $v6_method => sub {
        my $gi = Geo::IP->open( 't/data/GeoIPASNumv6.dat', GEOIP_STANDARD );

        is(
            $gi->$v6_method('2001:4:112::'),
            'AS112 DNS-OARC',
            'expected ASN'
        );
    };
}

done_testing();
