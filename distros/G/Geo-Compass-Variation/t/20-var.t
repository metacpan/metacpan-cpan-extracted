use warnings;
use strict;

use Geo::Compass::Variation qw(mag_var);
use Test::More;

my $data = [
    [51.0486, -114.0708, 1100, 2017.5, 14.167237613695, "Calgary"],
    [43.6666667, -79.4166667, 76, 2017.5, -10.45097267771, "Toronto"],
    [34.0522, -118.2437, 71, 2017.5, 12.034357850029, "Los Angeles"],
    [35.6895, 139.6917, 44, 2017.5, -7.4587368505428, "Tokyo"],
    [-33.8688, 151.2093, 58, 2017.5, 12.572631564557, "Sydney"],
];

for my $t (@$data){
    like mag_var(@$t), qr/$t->[4]/, "$t->[5] declination ok";
}

done_testing;

