#!perl -T

use Test::More;
use Device::USB;
use strict;
use warnings;
use constant TESTS_PER_INTERFACE => 8;

my $usb = Device::USB->new();
if(defined $usb)
{
    my $interface_count = 0;
    foreach my $dev ($usb->list_devices())
    {
        foreach my $config ($dev->configurations())
        {
            $interface_count += scalar( map {@{$_}} $config->interfaces() );
        }
    }
    if($interface_count)
    {
        plan tests => 2 + TESTS_PER_INTERFACE * $interface_count;
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

my @devices = $usb->list_devices();
isnt( scalar @devices, 0, "USB devices found" );

can_ok( "Device::USB::DevInterface",
        qw/bInterfaceNumber endpoints bNumEndpoints
        iInterface bInterfaceClass bInterfaceSubClass bInterfaceProtocol/
);

foreach my $dev (@devices)
{
    my $filename = $dev->filename();
    my $cfgno = 0;
    foreach my $cfg ($dev->configurations())
    {
        foreach my $if (map { @{$_} } $cfg->interfaces())
        {
            my $ifno = $if->bInterfaceNumber();
            isa_ok( $if, "Device::USB::DevInterface" );
            like( $if->bInterfaceNumber(), qr/^\d+$/, "$filename:$cfgno:$ifno: Interface Number" );
            like( $if->bAlternateSetting(), qr/^\d+$/, "$filename:$cfgno:$ifno: Alternate Setting" );
            is( $if->bNumEndpoints(), scalar @{$if->endpoints()}, "$filename:$cfgno:$ifno: endpoint count" );
            like( $if->bInterfaceClass(), qr/^\d+$/, "$filename:$cfgno:$ifno: Interface Class" );
            like( $if->bInterfaceSubClass(), qr/^\d+$/, "$filename:$cfgno:$ifno: Interface Sub Class" );
            like( $if->bInterfaceProtocol(), qr/^\d+$/, "$filename:$cfgno:$ifno: Interface Protocol" );
            like( $if->iInterface(), qr/^\d+$/, "$filename:$cfgno:$ifno: Interface string index" );
        }
        ++$cfgno;
    }
}

