use strict;
use warnings;

use Test::More tests => 17;

use Device::WallyHome;
use Device::WallyHome::Test::Data;


# Load main wally object
my $wally = Device::WallyHome->new(
    _testModeIdentifier => '1',
    token               => 'test-token',
);

ok(defined $wally, 'instantiate wally object');


# Check REST API user agent name
ok($wally->userAgentName() =~ /^Device::WallyHome v\d+\.\d+\.\d+/, 'useragent name formatted');
ok($wally->userAgentName() eq 'Device::WallyHome v' . Device::WallyHome->VERSION, 'useragent name correct version');


# Get places
my $places = $wally->places();

ok(
       defined $places
    && ref($places)
    && ref($places) eq 'ARRAY'
    && scalar @$places == 1,
    'get places'
);

my $place = $places->[0];

isa_ok($place, 'Device::WallyHome::Place');


# Get sensors
my $sensors = $place->sensors();

ok(
       defined $sensors
    && ref($sensors)
    && ref($sensors) eq 'ARRAY'
    && scalar @$sensors == 1,
    'get sensors'
);

# Sensor from list
my $sensor = $sensors->[0];

isa_ok($sensor, 'Device::WallyHome::Sensor', 'sensor');


# Sensor by SNID
my $sensorBySnid = $place->getSensorBySnid('90-7a-f1-ff-ff-ff');

ok(defined $sensorBySnid, 'sensorBySnid defined');
isa_ok($sensorBySnid, 'Device::WallyHome::Sensor', 'sensorBySnid');


# Location from sensor
my $location = $sensor->location();

ok(defined $location, 'location defined');
isa_ok($location, 'Device::WallyHome::Sensor::Location', 'location');


# Thesholds from sensor
my $thresholds = $sensor->thresholds();

ok(
       defined $thresholds
    && ref($thresholds)
    && ref($thresholds) eq 'ARRAY'
    && scalar @$thresholds == 2,
    'get thresholds'
);


# Threshold by name
my $thresholdByName = $sensor->threshold('TEMP');

ok(defined $thresholdByName, 'thresholdByName defined');
isa_ok($thresholdByName, 'Device::WallyHome::Sensor::Threshold', 'thresholdByName');


# States from sensor
my $states = $sensor->states();

ok(
       defined $states
    && ref($states)
    && ref($states) eq 'ARRAY'
    && scalar @$states == 5,
    'get states'
);


# State by name
my $stateByName = $sensor->state('TEMP');

ok(defined $stateByName, 'stateByName defined');
isa_ok($stateByName, 'Device::WallyHome::Sensor::State', 'stateByName');
