#!perl -wT

use strict;

# use lib 'lib';
use Test::Most tests => 18;
use Scalar::Util;

BEGIN { use_ok('Geo::Location::Point') }

isa_ok(Geo::Location::Point->new({ lat => 0, long => 0 }), 'Geo::Location::Point', 'Creating Geo::Location::Point object');
ok(!defined(Geo::Location::Point::new()));

# Begin testing
my $class = 'Geo::Location::Point';

diag('Ignore various usage messages');

# Instantiate with valid latitude and longitude
my $obj = $class->new(lat => 45, long => 90);
ok(Scalar::Util::blessed($obj) eq $class, 'Object creation successful with valid lat/long');
is($obj->{'lat'}, 45, 'Latitude is correct');
is($obj->{'long'}, 90, 'Longitude is correct');
is($obj->{'lng'}, 90, 'Longitude alias (lng) is set correctly');

# Instantiate with missing latitude
$obj = $class->new(long => 90);
ok(!defined($obj), 'Object creation fails with missing latitude');

# Instantiate with invalid latitude
$obj = $class->new(lat => 200, long => 90);
ok(!defined($obj), 'Object creation fails with invalid latitude');

# Instantiate with missing longitude
$obj = $class->new(lat => 45);
ok(!defined($obj), 'Object creation fails with missing longitude');

# Instantiate with invalid longitude
$obj = $class->new(lat => 45, long => 200);
ok(!defined($obj), 'Object creation fails with invalid longitude');

# Clone an object with additional arguments
my $original = $class->new(lat => 30, long => 60);
my $clone = $original->new(lat => 35);
ok(Scalar::Util::blessed($clone) eq $class, 'Object cloned successfully');
is($clone->{'lat'}, 35, 'Cloned object has updated latitude');
is($clone->{'long'}, 60, 'Cloned object retains original longitude');

# Incorrect usage of the new method
$obj = eval { $class->new([1, 2, 3]) };
ok(!defined($obj), 'Object creation fails with invalid input format');

# Correct usage with latitude/longitude keys
$obj = $class->new({ latitude => 10, longitude => 20 });
ok(Scalar::Util::blessed($obj) eq $class, 'Object creation successful with latitude/longitude keys');
is($obj->{'lat'}, 10, 'Latitude is correctly derived from latitude key');
is($obj->{'long'}, 20, 'Longitude is correctly derived from longitude key');
