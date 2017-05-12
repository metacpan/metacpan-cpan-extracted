use FindBin qw($Bin);
use lib "$Bin/../lib";
use v5.10;

use Device::Altimeter::LPS331AP;

my $a = Device::Altimeter::LPS331AP->new(I2CBusDevicePath => '/dev/i2c-1');
$a->enable();
use Data::Dumper;
while(){
    say 'millibars: ' . Dumper $a->getPressureMillibars();
    say 'InchesHg: ' . $a->getPressureInchesHg();
    say 'Celsius: ' . $a->getTemperatureCelsius();
    say 'Fahrenheit: ' . $a->getTemperatureFahrenheit();
    say 'ALTITUDE: ' . $a->getPressureToAltitudeMeters($a->getPressureMillibars,1011);
}
