#!perl -T

use Test::More;
use Device::USB;
use strict;
use warnings;
use constant TESTS_PER_CONFIGURATION => 7;

my $usb = Device::USB->new();
if(defined $usb)
{
    my $config_count = 0;
    foreach my $dev ($usb->list_devices())
    {
        $config_count += $dev->bNumConfigurations();
    }
    if($config_count)
    {
        plan tests => 2 + TESTS_PER_CONFIGURATION * $config_count;
    }
    else
    {
        plan skip_all => 'No devices found.';
    }
}
else
{
    fail( "Unable to create USB object." );
}

can_ok( "Device::USB::DevConfig",
        qw/wTotalLength bNumInterfaces interfaces bConfigurationValue
           iConfiguration bmAttributes MaxPower/
);

my @devices = $usb->list_devices();

isnt( scalar @devices, 0, "USB devices found" );

foreach my $dev (@devices)
{
    my $filename = $dev->filename();
    my $cfgno = 0;
    foreach my $cfg ($dev->configurations())
    {
        isa_ok( $cfg, "Device::USB::DevConfig" );
        like( $cfg->wTotalLength(), qr/^\d+$/, "$filename:$cfgno: USB Version" );
        is( $cfg->bNumInterfaces(), scalar @{$cfg->interfaces()}, "$filename:$cfgno: interface count" );
        like( $cfg->bConfigurationValue(), qr/^\d+$/, "$filename:$cfgno: configuration value" );
        like( $cfg->iConfiguration(), qr/^\d+$/, "$filename:$cfgno: configuration" );
        like( $cfg->bmAttributes(), qr/^\d+$/, "$filename:$cfgno: Attributes" );
        like( $cfg->MaxPower(), qr/^\d+$/, "$filename:$cfgno: max power" );
        ++$cfgno;
    }
}

