use warnings;
use strict;

use Geo::Compass::Variation qw(mag_var);
use Test::More;

my $data = [
    [51.0486, -114.0708, 1100, 2017.5, 14.1672376136956, "Calgary"],
    [43.6666667, -79.4166667, 76, 2017.5, -10.450972677711, "Toronto"],
    [34.0522, -118.2437, 71, 2017.5, 12.0343578500291, "Los Angeles"],
    [35.6895, 139.6917, 44, 2017.5, -7.45873685054281, "Tokyo"],
    [-33.8688, 151.2093, 58, 2017.5, 12.5726315645576, "Sydney"],
];

for my $t (@$data){
    is mag_var(@$t), $t->[4], "$t->[5] declination ok";
}

done_testing;

