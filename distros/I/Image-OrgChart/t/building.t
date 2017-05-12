
######################### We start with some black magic to print on failure.

use Test;
BEGIN { plan tests => 4 };
use Image::OrgChart;
ok(1); # Loaded

######################### End of black magic.

#### Test 2 -- New Object
my $t = new Image::OrgChart();
ok($t);

#### Test 3 -- add method
$t->add('/foo/bar');
ok( (scalar keys %{$t->{_data}{foo}} == 1) );

#### Test 4 -- set_hashref method
$hash{bar} = {
	      'foo1' => {},
	      'foo2' => {},
             };
$t->set_hashref(\%hash);
ok( (scalar keys %{$t->{_data}{bar}} == 2) );

