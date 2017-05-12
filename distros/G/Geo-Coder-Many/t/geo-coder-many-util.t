
use strict;
use warnings;

# test precision - more tests needed
my %tests = (
    'good' => {
       'lon1' => -0.09535789489746094,
       'lat1' => 51.53258851784387,
       'lon2' => -0.10239601135253906,
       'lat2' => 51.5227098067524,
       'expected_precision' => 0.7,
    },

    'same long/lat' => {
       'lon1' => -0.09535789489746094,
       'lat1' => 51.53258851784387,
       'lon2' => -0.09535789489746094,
       'lat2' => 51.53258851784387,
       'expected_precision' => 1.0,
    },
);

use Test::More;
use_ok('Geo::Coder::Many::Util');

ok(Geo::Coder::Many::Util::determine_precision_from_bbox() == 0,
   'no input leads to precision of 0');

foreach my $testname (sort keys %tests){
    my $rh_data = $tests{$testname};
    my $precision = Geo::Coder::Many::Util::determine_precision_from_bbox($rh_data);
    ok($precision == $rh_data->{expected_precision},
       "correct precision for $testname"
    );
}

my $num_tests = 2 + scalar(keys %tests);
done_testing($num_tests);