# samples.t

use Test::Most;

use Path::Class qw/ dir /;
use Geo::JSON;

my @tests = dir('t/samples')->children;

foreach my $test (@tests) {

    my $geojson = $test->slurp;

    ok my $obj = Geo::JSON->from_json( $geojson ), "created object from $test";

}

done_testing();

