use warnings;
use strict;

use Geo::Compass::Variation qw(mag_dec);
use Test::More;

my $year = 2022.5;

my $data = [
    [51.0486, -114.0708, 1100, $year, 13.7680287951, "Calgary"],
    [43.6666667, -79.4166667, 76, $year, -10.25382023608, "Toronto"],
    [34.0522, -118.2437, 71, $year, 11.632738430093, "Los Angeles"],
    [35.6895, 139.6917, 44, $year, -7.794218381724, "Tokyo"],
    [-33.8688, 151.2093, 58, $year, 12.740026393110, "Sydney"],
];

for my $t (@$data){
    like mag_dec(@$t), qr/$t->[4]/, "$t->[5] declination ok";
}

done_testing;

