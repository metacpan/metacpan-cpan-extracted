
######################### We start with some black magic to print on failure.

use Test;
BEGIN { plan tests => 8 };
use Image::OrgChart;
ok(1); # Loaded

######################### End of black magic.

#### Test 2 -- New Object
my $t = new Image::OrgChart();
ok($t);

######################### End of black magic.

#### Test 2 -- set_hashref method
$hash{bar} = {
	      'foo1' => {},
	      'foo2' => {},
             };
$t = Image::OrgChart->new();
ok($t);

$t->set_hashref(\%hash);
ok( (scalar keys %{$t->{_data}{bar}} == 2) );

#### Test 3 -- get data type
$type = $t->data_type();
if ($type ne 'gif' && $type ne 'png') {
    warn "Data Type '$type' is not png or gif.\n";
    ok(0);
} else {
    ok(1);
}

#### Test 4 -- test data (approximate)
$data = $t->draw();
ok($data);

$length = length($data);

$expected_lengths{gif} = 332;
$expected_lengths{png} = 332;

ok($length < $expected_lengths{$type} || $expected_lengths{$type} > 360);

### Test 5 -- test data (exact length)
ok( $length != $expected_lengths{$type} );
 
