use Device::Velleman::K8055 qw(:all);
use Test::More tests => 1;
use strict;
use warnings;
diag( "Watch the leds for the digital output running\n");

is(digital_led_test(), 1, 'Digital Led Test');

sub digital_led_test
{
    # this should show a led running light
    return -1 unless OpenDevice(0) == 0;
    
    for (my $i = 0; $i < 3; $i++)
    {
        for (my $j = 1; $j <= 8; $j++)
        {
            SetDigitalChannel($j);
            ClearDigitalChannel($j == 1 ? 8 : ($j -1));
            sleep(1);
        }
    }
    ClearAllDigital();
    CloseDevice();
    return 1;
}