use Test::More tests => 17;

BEGIN {
	use lib "../lib";
	use_ok( "Geography::Countries::LatLong" => 1.0)
}

isa_ok( latlong("Niue"),'ARRAY', 'return');

@_ = latlong('Niue');
is($_[0], '-19.0333', 'lat');
is($_[1], '-169.8667', 'lon');

$_ = latlong('Niue');
isa_ok($_, 'ARRAY');
@_ = @$_;
is($_[0], '-19.0333', 'lat');
is($_[1], '-169.8667', 'lon');

$_ = latlong('Great Britain');
isa_ok($_, 'ARRAY');
@_ = @$_;
is($_[0], 54, 'lat');
is($_[1], -2, 'lon');

is(latlong('Hyperion'), undef, 'bad country name');

isnt(Geography::Countries::LatLong::supports('Hungary'),undef,'supports');
is(Geography::Countries::LatLong::supports('Judea'),"",'supports');

# diag scalar keys %$Geography::Countries::LatLong::countries_latlong;

ok( Geography::Countries::LatLong::USE_OLD_DATA(), 'use old data');
$_ = latlong('Great Britain');
isa_ok($_, 'ARRAY');
@_ = @$_;
is($_[0], '55.40342', 'lat');
is($_[1], '-3.21145', 'lon');


exit;

