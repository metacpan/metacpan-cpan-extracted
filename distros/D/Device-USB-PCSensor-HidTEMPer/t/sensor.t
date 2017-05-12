use Test::Simple tests => 6;

use Device::USB::PCSensor::HidTEMPer::Sensor;

ok( Device::USB::PCSensor::HidTEMPer::Sensor::MAX_TEMPERATURE eq 0, "MAX_TEMPERATURE");
ok( Device::USB::PCSensor::HidTEMPer::Sensor::MIN_TEMPERATURE eq 0, "MIN_TEMPERATURE");

$sensor = Device::USB::PCSensor::HidTEMPer::Sensor->new( undef ); 

ok( defined($sensor), 'new()');
ok( $sensor->fahrenheit() == 32, 'fahrenheit()' );
ok ( $sensor->min() == 0, 'min()');
ok ( $sensor->max() == 0, 'max()');