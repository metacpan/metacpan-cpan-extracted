use Device::Velleman::K8055 qw(:all);
use Test::More tests => 1;
use strict;
use warnings;
diag("Watch the leds for the analog output running\n");
is(analog_led_test(), 1, "Analog Led Test");

sub analog_led_test
{
    return -1 unless OpenDevice(0) == 0;
    
    for (my $i = 0; $i < 3; $i++)
    {
        for (my $j = 1; $j < 3; $j++)
        {
            SetAnalogChannel($j);
            ClearAnalogChannel($j == 1 ? 2 : ($j -1));
            sleep(1);
        }
    }
    ClearAllAnalog();
    CloseDevice();
    return 1;
}