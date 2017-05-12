# crs.t

use Test::Most;

use Geo::JSON::CRS;

my $pkg = 'Geo::JSON::CRS';

ok my $n = $pkg->new(
    {   type       => 'name',
        properties => { name => 'urn:ogc:def:crs:OGC:1.3:CRS84' }
    }
    ),
    "new - named CRS";

ok my $l = $pkg->new(
    {   type       => 'link',
        properties => {
            href => 'http://example.com/crs/42',
            type => 'proj4'
        }
    }
    ),
    "new - linked CRS";

ok my $r = $pkg->new(
    {   type       => 'link',
        properties => {
            href => 'data.crs',
            type => 'ogcwkt'
        }
    }
    ),
    "new - relative link";

done_testing();

