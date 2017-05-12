use strict;
use Test;

plan tests => 13;

use Geography::NationalGrid;
ok(1);

# Yahoo! Taiwan
comp(25.0268337002586745, 121.522412806088342, 302721.36, 2768851.3995);

# National Taiwan University
comp(25.0169811348563738, 121.533698709267335, 303864.6425, 2767764.5186);

# transform TWD67 -> TWD97
my $point1 = new Geography::NationalGrid('TW', 'Projection' => 'TWD67',
  'Easting' => 301822.41, 'Northing' => 2769934.13);
my $point2 = $point1->transform('TWD97');
ok($point2->easting, 302652);
ok($point2->northing, 2769730);
ok($point2->latitude, 25.0347717108971217);
ok($point2->longitude, 121.521768497433618);

sub comp
{
  my ($lat, $long, $e, $n) = @_;
  my $point1 = new Geography::NationalGrid('TW',
    Latitude  => $lat,
    Longitude => $long
  );
  ok($point1->easting, int($e));
  ok($point1->northing, int($n));
  my $point2 = new Geography::NationalGrid::TW(
    Easting  => $e,
    Northing => $n
  );
  ok($point2->latitude, $lat);
  ok($point2->longitude, $long);
}
