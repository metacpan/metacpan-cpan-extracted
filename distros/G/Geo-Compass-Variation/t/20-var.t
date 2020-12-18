use warnings;
use strict;

use Geo::Compass::Variation qw(mag_var);
use Test::More;

my $year = 2022.5;

my $data = [
    [51.0486, -114.0708, 1100, $year, 13.76802879517, "Calgary"],
    [43.6666667, -79.4166667, 76, $year, -10.25382023608, "Toronto"],
    [34.0522, -118.2437, 71, $year, 11.63273843009, "Los Angeles"],
    [35.6895, 139.6917, 44, $year, -7.79421838172, "Tokyo"],
    [-33.8688, 151.2093, 58, $year, 12.74002639311, "Sydney"],
];

for my $t (@$data){
    like mag_var(@$t), qr/$t->[4]/, "$t->[5] declination ok";
}

done_testing;

