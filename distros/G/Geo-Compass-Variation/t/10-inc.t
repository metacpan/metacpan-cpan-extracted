use warnings;
use strict;

use Geo::Compass::Variation qw(mag_inc);
use Test::More;

my $data = [
    [51.0486, -114.0708, 1100, 2017.5, 73.3152904902216, "Calgary"],
    [43.6666667, -79.4166667, 76, 2017.5, 69.713916808503, "Toronto"],
    [34.0522, -118.2437, 71, 2017.5, 58.8578478983067, "Los Angeles"],
    [35.6895, 139.6917, 44, 2017.5, 49.5614004810652, "Tokyo"],
    [-33.8688, 151.2093, 58, 2017.5, -64.2952308980996, "Sydney"],
];

for my $t (@$data){
    is mag_inc(@$t), $t->[4], "$t->[5] inclination ok";
}

done_testing;

