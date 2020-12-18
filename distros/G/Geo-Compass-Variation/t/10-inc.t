use warnings;
use strict;

use Geo::Compass::Variation qw(mag_inc);
use Test::More;

my $year = 2022.5;

my $data = [
    [51.0486, -114.0708, 1100, $year, 73.06672951727, "Calgary"],
    [43.6666667, -79.4166667, 76, $year, 69.21591170362, "Toronto"],
    [34.0522, -118.2437, 71, $year, 58.84445605814, "Los Angeles"],
    [35.6895, 139.6917, 44, $year, 49.50639969036, "Tkyo"],
    [-33.8688, 151.2093, 58, $year, -64.38154944542, "Sydney"],
];

for my $t (@$data){
    like mag_inc(@$t), qr/$t->[4]/, "$t->[5] inclination ok";
}

done_testing;

